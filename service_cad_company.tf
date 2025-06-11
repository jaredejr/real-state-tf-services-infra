locals {
  srv_cad_company_service_name = "srv-cad-company"
  srv_cad_company_port         = 8082 # Escolha uma porta para este serviço, ex: 8082
}

# Log Group para o serviço
resource "aws_cloudwatch_log_group" "srv_cad_company" {
  name              = "/ecs/${local.ecs_cluster_name}/${local.srv_cad_company_service_name}"
  retention_in_days = var.log_retention_days
  tags              = local.common_tags
}

# Definição da Tarefa ECS
resource "aws_ecs_task_definition" "srv_cad_company" {
  family                   = "${local.srv_cad_company_service_name}-${var.environment}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256" # 0.25 vCPU
  memory                   = "512" # 0.5 GB RAM
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_srv_cad_company_task_role.arn # Usa a role específica com acesso ao DynamoDB

  container_definitions = jsonencode([
    {
      name      = local.srv_cad_company_service_name
      image     = "${aws_ecr_repository.srv_cad_company.repository_url}:${var.srv_cad_company_image_tag}"
      essential = true
      portMappings = [
        {
          containerPort = local.srv_cad_company_port
          hostPort      = local.srv_cad_company_port
          protocol      = "tcp"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.srv_cad_company.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
      environment = [
        { name = "SPRING_PROFILES_ACTIVE", value = var.environment },
        { name = "DYNAMODB_CAD_COMPANY_TABLE", value = var.dynamodb_db_cad_company_table_name }, # Alinhado com o nome da app
        { name = "AWS_REGION", value = var.aws_region }, # Para o SDK AWS
        # AWS_ACCESS_KEY_ID e AWS_SECRET_ACCESS_KEY NÃO DEVEM SER USADOS AQUI. A role da tarefa fornecerá as credenciais.
        { name = "JKS_URI", value = var.jks_uri }, # Adicionado JKS_URI
        { name = "ROOT_LOG_LEVEL", value = var.root_log_level },
        { name = "SPRING_LOG_LEVEL", value = var.spring_log_level }
      ]
      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:${local.srv_cad_company_port}/srv-cad-company/health || exit 1"]
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
resource "aws_lb_target_group" "srv_cad_company" {
  name        = "${local.srv_cad_company_service_name}-${var.environment}"
  port        = local.srv_cad_company_port
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"
  health_check {
    path                = "/srv-cad-company/health"
    protocol            = "HTTP"
    interval            = 75
    timeout             = 60
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }
  tags = local.common_tags
}

# Regra do Listener do ALB
resource "aws_lb_listener_rule" "srv_cad_company" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 120 # Prioridade diferente das outras regras (ex: 100, 110, 120)

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.srv_cad_company.arn
  }

  condition {
    path_pattern {
      values = ["/srv-cad-company*"] # Roteia requisições para /company/*
    }
  }
}

# Serviço ECS
resource "aws_ecs_service" "srv_cad_company" {
  name            = "${local.srv_cad_company_service_name}-${var.environment}"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.srv_cad_company.arn
  desired_count   = 1
  health_check_grace_period_seconds = 120
  launch_type     = "FARGATE"
  network_configuration {
    subnets         = aws_subnet.private[*].id
    security_groups = [aws_security_group.ecs_tasks_sg.id]
    assign_public_ip = false
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.srv_cad_company.arn
    container_name   = local.srv_cad_company_service_name
    container_port   = local.srv_cad_company_port
  }
  enable_execute_command = true
  tags                   = local.common_tags
}