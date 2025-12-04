locals {
  auth_server_service_name = "auth-server"
  auth_server_port         = 8083 # Porta que o container auth-server escuta
}

# Log Group para o serviço
resource "aws_cloudwatch_log_group" "auth_server" {
  name              = "/ecs/${local.ecs_cluster_name}/${local.auth_server_service_name}"
  retention_in_days = var.log_retention_days
  tags              = local.common_tags
}

# Definição da Tarefa ECS
resource "aws_ecs_task_definition" "auth_server" {
  family                   = "${local.auth_server_service_name}-${var.environment}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_generic_task_role.arn # Usa a role genérica

  container_definitions = jsonencode([
    {
      name      = local.auth_server_service_name
      image     = "${aws_ecr_repository.auth_server.repository_url}:${var.auth_server_image_tag}"
      essential = true
      portMappings = [
        {
          containerPort = local.auth_server_port
          hostPort      = local.auth_server_port
          protocol      = "tcp"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.auth_server.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
      environment = [
        { name = "SPRING_PROFILES_ACTIVE", value = var.environment },
        { name = "ROOT_LOG_LEVEL", value = var.root_log_level },
        { name = "SPRING_LOG_LEVEL", value = var.spring_log_level },
        { name = "AUTH_SERVER_URL", value = var.public_auth_server_url }, # Usa a URL pública para o issuer-uri
        # AUTH_SERVER_EXTERNAL_URL não parece ser usado no application.properties, mas pode ser útil manter para outros contextos.
        # Se não for usado, pode ser removido.
        { name = "USER_API_BASE_URL", value = local.user_api_base_url },
        { name = "CLIENT_WEB_SECRET", value = var.client_web_secret },
        { name = "AUTH_SERVER_CLIENT_SECRET", value = var.auth_server_client_secret }
      ]
      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:${local.auth_server_port}/auth-server/health || exit 1"]
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
resource "aws_lb_target_group" "auth_server" {
  name        = "${local.auth_server_service_name}-${var.environment}"
  port        = local.auth_server_port
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"
  health_check {
    path                = "/auth-server/health"
    protocol            = "HTTP"
    interval            = 30
    timeout             = 10
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }
  tags = local.common_tags
}

# Regra do Listener do ALB
resource "aws_lb_listener_rule" "auth_server" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 130 # Prioridade única

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.auth_server.arn
  }

  condition {
    path_pattern {
      values = ["/auth-server*"]
    }
  }
}

# Serviço ECS
resource "aws_ecs_service" "auth_server" {
  name            = "${local.auth_server_service_name}-${var.environment}"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.auth_server.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  health_check_grace_period_seconds = 120
  network_configuration {
    subnets          = aws_subnet.private[*].id
    security_groups  = [aws_security_group.ecs_tasks_sg.id]
    assign_public_ip = false
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.auth_server.arn
    container_name   = local.auth_server_service_name
    container_port   = local.auth_server_port
  }
  deployment_circuit_breaker {
    enable   = true
    rollback = false
  }
  enable_execute_command = true
  tags                   = local.common_tags
}