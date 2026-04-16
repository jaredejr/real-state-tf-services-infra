# Repositório ECR para srv-cad-usuarios
resource "aws_ecr_repository" "srv_cad_users" {
  name                 = local.srv_cad_users_service_name
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = local.common_tags
}

resource "aws_ecr_lifecycle_policy" "srv_cad_users_policy" {
  repository = aws_ecr_repository.srv_cad_users.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep last 3 images"
      selection = {
        tagStatus     = "any"
        countType     = "imageCountMoreThan"
        countNumber   = 3
      }
      action = {
        type = "expire"
      }
    }]
  })
}

# Repositório ECR para srv-cad-imoveis
resource "aws_ecr_repository" "srv_cad_advertisements" {
  name                 = local.srv_cad_advertisements_service_name
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = local.common_tags
}

resource "aws_ecr_lifecycle_policy" "srv_cad_advertisements_policy" {
  repository = aws_ecr_repository.srv_cad_advertisements.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep last 3 images"
      selection = {
        tagStatus     = "any"
        countType     = "imageCountMoreThan"
        countNumber   = 3
      }
      action = {
        type = "expire"
      }
    }]
  })
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

resource "aws_ecr_lifecycle_policy" "srv_cad_company_policy" {
  repository = aws_ecr_repository.srv_cad_company.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep last 3 images"
      selection = {
        tagStatus     = "any"
        countType     = "imageCountMoreThan"
        countNumber   = 3
      }
      action = {
        type = "expire"
      }
    }]
  })
}

# Repositório ECR para auth-server
resource "aws_ecr_repository" "auth_server" {
  name                 = local.auth_server_service_name
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = local.common_tags
}

resource "aws_ecr_lifecycle_policy" "auth_server_policy" {
  repository = aws_ecr_repository.auth_server.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep last 3 images"
      selection = {
        tagStatus     = "any"
        countType     = "imageCountMoreThan"
        countNumber   = 3
      }
      action = {
        type = "expire"
      }
    }]
  })
}
