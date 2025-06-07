resource "aws_lb" "main" {
  name               = "${var.project_name}-alb-${var.environment}"
  internal           = false # Mude para true se for um ALB interno
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = aws_subnet.public[*].id # ALB em subnets públicas

  enable_deletion_protection = false # Mude para true em produção

  access_logs {
    bucket  = aws_s3_bucket.alb_logs.bucket
    prefix  = "alb-access-logs" # Opcional: um prefixo para organizar os logs dentro do bucket
    enabled = true
  }

  tags = local.common_tags
}

# Listener HTTP padrão (porta 80)
# Você pode adicionar um listener HTTPS (porta 443) com um certificado ACM
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "Recurso não encontrado."
      status_code  = "404"
    }
  }
  tags = local.common_tags
}

# Target Group padrão (pode não ser usado se todos os paths forem cobertos)
# Ou pode ser usado para um health check genérico do ALB.
# Por simplicidade, vamos criar os target groups por serviço.