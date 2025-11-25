locals {
  srv_cad_advertisements_service_name = "srv-cad-advertisements"
  srv_cad_advertisements_port         = 8080 # Porta que o container srv-cad-advertisements escuta
}

# Log Group para o serviço
resource "aws_cloudwatch_log_group" "srv_cad_advertisements" {
  name              = "/ecs/${local.ecs_cluster_name}/${local.srv_cad_advertisements_service_name}"
  retention_in_days = var.log_retention_days
  tags              = local.common_tags
}

# Definição da Tarefa ECS
resource "aws_ecs_task_definition" "srv_cad_advertisements" {
  family                   = "${local.srv_cad_advertisements_service_name}-${var.environment}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_generic_task_role.arn

  container_definitions = jsonencode([
    {
      name      = local.srv_cad_advertisements_service_name
      image     = "${aws_ecr_repository.srv_cad_advertisements.repository_url}:${var.srv_cad_advertisements_image_tag}"
      essential = true
      portMappings = [
        {
          containerPort = local.srv_cad_advertisements_port
          hostPort      = local.srv_cad_advertisements_port
          protocol      = "tcp"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.srv_cad_advertisements.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
      environment = [
        { name = "SPRING_PROFILES_ACTIVE", value = var.environment },
        { name = "MONGODB_ATLAS_CONNECTION_STRING", value = var.mongodb_atlas_connection_string },
        { name = "DB_ADVERTISEMENT_NAME", value = var.mongodb_database_name_advertisement },
        { name = "ROOT_LOG_LEVEL", value = var.root_log_level },
        { name = "SPRING_LOG_LEVEL", value = var.spring_log_level },
        { name = "AUTH_SERVER_URL", value = local.auth_server_url }
      ]
      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:${local.srv_cad_advertisements_port}/srv-cad-advertisements/health || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }
    }
  ])
  tags = local.common_tags
}

# Target Group do ALB
resource "aws_lb_target_group" "srv_cad_advertisements" {
  name        = "${local.srv_cad_advertisements_service_name}-${var.environment}"
  port        = local.srv_cad_advertisements_port
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"
  health_check {
    path                = "/srv-cad-advertisements/health"
    protocol            = "HTTP"
    interval            = 30
    timeout             = 10
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }
  tags = local.common_tags
}

# Regra do Listener do ALB
resource "aws_lb_listener_rule" "srv_cad_advertisements" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 110 # Prioridade diferente da outra regra

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.srv_cad_advertisements.arn
  }

  condition {
    path_pattern {
      values = ["/srv-cad-advertisements*"] # Roteia requisições para /advertisements/*
    }
  }
}

# Serviço ECS
resource "aws_ecs_service" "srv_cad_advertisements" {
  name            = "${local.srv_cad_advertisements_service_name}-${var.environment}"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.srv_cad_advertisements.arn
  desired_count   = 1
  health_check_grace_period_seconds = 120
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = aws_subnet.private[*].id
    security_groups = [aws_security_group.ecs_tasks_sg.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.srv_cad_advertisements.arn
    container_name   = local.srv_cad_advertisements_service_name
    container_port   = local.srv_cad_advertisements_port
  }

  deployment_circuit_breaker {
    enable   = true
    rollback = false # Se a implantação falhar, não reverte (para as tentativas com a versão atual)
  }

  enable_execute_command = true
  tags                   = local.common_tags
}