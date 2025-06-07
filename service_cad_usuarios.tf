locals {
  srv_cad_usuarios_service_name = "srv-cad-usuarios"
  srv_cad_usuarios_port         = 8080 # Porta que o container srv-cad-usuarios escuta
}

# Log Group para o serviço
resource "aws_cloudwatch_log_group" "srv_cad_usuarios" {
  name              = "/ecs/${local.ecs_cluster_name}/${local.srv_cad_usuarios_service_name}"
  retention_in_days = var.log_retention_days
  tags              = local.common_tags
}

# Definição da Tarefa ECS
resource "aws_ecs_task_definition" "srv_cad_usuarios" {
  family                   = "${local.srv_cad_usuarios_service_name}-${var.environment}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256" # 0.25 vCPU
  memory                   = "512" # 0.5 GB RAM
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_generic_task_role.arn # Use uma role mais específica se necessário

  container_definitions = jsonencode([
    {
      name      = local.srv_cad_usuarios_service_name
      # A URI da imagem agora pode ser construída ou ainda vir de uma variável.
      # Se o pipeline da aplicação souber a tag, você pode construir assim:
      image     = "${aws_ecr_repository.srv_cad_usuarios.repository_url}:${var.srv_cad_usuarios_image_tag}" # Nova variável para a tag
      essential = true
      portMappings = [
        {
          containerPort = local.srv_cad_usuarios_port
          hostPort      = local.srv_cad_usuarios_port # Em awsvpc, hostPort é igual a containerPort
          protocol      = "tcp"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.srv_cad_usuarios.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
      # Adiciona a variável de ambiente para o nome da tabela DynamoDB
      # Alterado para usar MongoDB
      environment = [
        { name = "SPRING_PROFILES_ACTIVE", value = var.environment }, # Exemplo de outra variável
        { name = "MONGODB_ATLAS_CONNECTION_STRING", value = var.mongodb_atlas_connection_string }, # Usando a string de conexão comum
        { name = "DB_USER_NAME", value = var.mongodb_database_name_usuarios }, # Alinhado com o nome da app
        { name = "ROOT_LOG_LEVEL", value = var.root_log_level },
        { name = "SPRING_LOG_LEVEL", value = var.spring_log_level }
        # Se JKS_URI for específico para este serviço e não global, adicione aqui. Se for global e opcional, pode ser omitido se var.jks_uri for null.
      ],
      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:${local.srv_cad_usuarios_port}/srv-cad-usuarios/health || exit 1"]
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
resource "aws_lb_target_group" "srv_cad_usuarios" {
  name        = "${local.srv_cad_usuarios_service_name}-${var.environment}"
  port        = local.srv_cad_usuarios_port
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip" # Para Fargate
  health_check {
    path                = "/srv-cad-usuarios/health"
    protocol            = "HTTP"
    interval            = 30
    timeout             = 10
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
  tags = local.common_tags
}

# Regra do Listener do ALB (ex: roteamento baseado em path)
resource "aws_lb_listener_rule" "srv_cad_usuarios" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 100 # Prioridade única para cada regra

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.srv_cad_usuarios.arn
  }

  condition {
    path_pattern {
      values = ["/usuarios*"] # Roteia requisições para /usuarios/* para este serviço
    }
  }
}

# Serviço ECS
resource "aws_ecs_service" "srv_cad_usuarios" {
  name            = "${local.srv_cad_usuarios_service_name}-${var.environment}"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.srv_cad_usuarios.arn
  desired_count   = 1 # Número desejado de tarefas
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = aws_subnet.private[*].id # Executa tarefas nas subnets privadas
    security_groups = [aws_security_group.ecs_tasks_sg.id]
    assign_public_ip = false # Fargate em subnets privadas não precisa de IP público
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.srv_cad_usuarios.arn
    container_name   = local.srv_cad_usuarios_service_name
    container_port   = local.srv_cad_usuarios_port
  }

  # Para evitar problemas de "InvalidParameterException: The new task definition does not support the launch type specified"
  # durante atualizações, pode ser necessário um lifecycle block.
  # Ou garantir que a task definition sempre seja compatível.
  # depends_on = [aws_lb_listener_rule.srv_cad_usuarios] # Garante que a regra do listener exista

  # Habilita ECS Exec (opcional)
  enable_execute_command = true

  tags = local.common_tags
}