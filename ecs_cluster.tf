resource "aws_ecs_cluster" "main" {
  name = local.ecs_cluster_name
  tags = local.common_tags

  setting {
    name  = "containerInsights"
    value = "enabled" # Habilita o Container Insights para monitoramento
  }

  configuration {
    execute_command_configuration {
      logging = "DEFAULT" # Ou OVERRIDE para configurar logs do ECS Exec
      # kms_key_id = "your-kms-key-arn" # Opcional: para criptografar logs do ECS Exec
      # log_configuration { # Opcional: se logging = OVERRIDE
      #   cloud_watch_log_group_name = aws_cloudwatch_log_group.ecs_exec_logs.name
      # }
    }
  }
}