terraform {
  # Este bloco informa ao Terraform para usar o backend S3 que você criou
  # com o projeto real-state-tf-backend.
  backend "s3" {
    bucket = "real-state-terraform-state-bucket" # O nome do bucket que você criou
    key    = "services-infra/terraform.tfstate"  # Um caminho específico para este projeto dentro do bucket
    region = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-lock-table" # Nome da tabela de lock, se você criou uma.
  }
}

provider "aws" {
  region = var.aws_region
}

# Bloco de locals para valores computados e dinâmicos
locals {
  ecs_cluster_name = "${var.project_name}-cluster-${var.environment}"

  # Estratégia de URLs Dinâmicas
  # Constrói as URLs baseadas no DNS do Application Load Balancer.
  # Usamos https como padrão, pois o ALB é o ponto de entrada para tráfego interno e externo.
  # O ALB fará a terminação TLS e encaminhará o tráfego para os serviços.
  auth_server_url   = "https://${aws_lb.main.dns_name}/auth-server"
  user_api_base_url = "https://${aws_lb.main.dns_name}/srv-cad-users"
}