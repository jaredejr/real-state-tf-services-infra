# Repositório ECR para srv-cad-usuarios
resource "aws_ecr_repository" "srv_cad_usuarios" {
  name                 = local.srv_cad_usuarios_service_name # Usa o mesmo nome do serviço para consistência
  image_tag_mutability = "MUTABLE"                           # Ou "IMMUTABLE" se preferir que as tags não possam ser sobrescritas

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = local.common_tags
}

# Repositório ECR para srv-cad-imoveis
resource "aws_ecr_repository" "srv_cad_imoveis" {
  name                 = local.srv_cad_imoveis_service_name
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = local.common_tags
}

# Repositório ECR para srv-cad-company
resource "aws_ecr_repository" "srv_cad_company" {
  name                 = local.srv_cad_company_service_name
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = local.common_tags
}

# Você pode adicionar outputs para as URLs dos repositórios se necessário