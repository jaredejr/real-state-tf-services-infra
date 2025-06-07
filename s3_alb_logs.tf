resource "aws_s3_bucket" "alb_logs" {
  bucket = "${var.project_name}-alb-access-logs-${data.aws_caller_identity.current.account_id}-${var.aws_region}" # Nome único para o bucket

  tags = local.common_tags
}

# Política para permitir que o ALB escreva no bucket
data "aws_iam_policy_document" "alb_log_s3_policy_doc" {
  statement {
    effect = "Allow"
    actions = ["s3:PutObject"]
    principals {
      type        = "AWS"
      # ARN do serviço de Elastic Load Balancing para a sua região
      # Consulte: https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-access-logs.html#access-logging-bucket-permissions
      # Exemplo para us-east-1: arn:aws:iam::127311923021:root (este é o ID da conta da AWS para ELB em us-east-1)
      # Você pode encontrar o ID da conta correto para sua região na documentação.
      # Para us-east-1, o ID da conta do serviço ELB é 127311923021
      identifiers = ["arn:aws:iam::${data.aws_elb_service_account.current.id}:root"]
    }
    resources = ["arn:aws:s3:::${aws_s3_bucket.alb_logs.bucket}/*"]
  }
}

resource "aws_s3_bucket_policy" "alb_logs_policy" {
  bucket = aws_s3_bucket.alb_logs.id
  policy = data.aws_iam_policy_document.alb_log_s3_policy_doc.json
}

data "aws_elb_service_account" "current" {}