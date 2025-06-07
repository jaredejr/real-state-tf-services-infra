# Role de Execução da Tarefa ECS
# Permite que o Fargate puxe imagens do ECR e envie logs para o CloudWatch.
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${var.project_name}-ecs-task-execution-role-${var.environment}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Role da Tarefa ECS (Opcional, para permissões específicas da aplicação)
# Se seus serviços Java precisarem acessar outros serviços AWS (S3, DynamoDB, etc.),
# adicione as permissões aqui.
resource "aws_iam_role" "ecs_generic_task_role" {
  name = "${var.project_name}-ecs-generic-task-role-${var.environment}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
  tags = local.common_tags
}

# Role da Tarefa ECS específica para srv-cad-company (com acesso ao DynamoDB)
resource "aws_iam_role" "ecs_srv_cad_company_task_role" {
  name = "${var.project_name}-ecs-srv-cad-company-task-role-${var.environment}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
  tags = local.common_tags
}

# Política para permitir acesso à tabela DynamoDB db-cad-company
data "aws_iam_policy_document" "ecs_dynamodb_cad_company_access" {
  statement {
    actions = [
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:UpdateItem",
      "dynamodb:DeleteItem",
      "dynamodb:Query",
      "dynamodb:Scan",
      "dynamodb:DescribeTable"
    ]
    resources = [
      "arn:aws:dynamodb:${var.aws_region}:${data.aws_caller_identity.current.account_id}:table/${var.dynamodb_db_cad_company_table_name}"
      # Se você precisar de acesso a índices, adicione-os aqui:
      # "arn:aws:dynamodb:${var.aws_region}:${data.aws_caller_identity.current.account_id}:table/${var.dynamodb_db_cad_company_table_name}/index/*"
    ]
  }
}

resource "aws_iam_policy" "ecs_dynamodb_cad_company_access" {
  name        = "${var.project_name}-ecs-dynamodb-cad-company-policy-${var.environment}"
  description = "Permite que as tarefas ECS acessem a tabela DynamoDB db-cad-company"
  policy      = data.aws_iam_policy_document.ecs_dynamodb_cad_company_access.json
}

# Anexa a política de acesso ao DynamoDB APENAS à role específica do srv-cad-company
resource "aws_iam_role_policy_attachment" "ecs_srv_cad_company_dynamodb_access" {
  role       = aws_iam_role.ecs_srv_cad_company_task_role.name
  policy_arn = aws_iam_policy.ecs_dynamodb_cad_company_access.arn
}

# Política para permitir ECS Exec (SSM Session Manager)
data "aws_iam_policy_document" "ecs_exec_policy_document" {
  statement {
    effect = "Allow"
    actions = [
      "ssmmessages:CreateControlChannel",
      "ssmmessages:CreateDataChannel",
      "ssmmessages:OpenControlChannel",
      "ssmmessages:OpenDataChannel"
    ]
    resources = ["*"] # Necessário para ECS Exec
  }
}

resource "aws_iam_policy" "ecs_exec_policy" {
  name        = "${var.project_name}-ecs-exec-policy-${var.environment}"
  description = "Permite que as tarefas ECS usem o ECS Exec via SSM Session Manager"
  policy      = data.aws_iam_policy_document.ecs_exec_policy_document.json
}

resource "aws_iam_role_policy_attachment" "generic_task_role_ecs_exec" {
  role       = aws_iam_role.ecs_generic_task_role.name
  policy_arn = aws_iam_policy.ecs_exec_policy.arn
}

resource "aws_iam_role_policy_attachment" "company_task_role_ecs_exec" {
  role       = aws_iam_role.ecs_srv_cad_company_task_role.name
  policy_arn = aws_iam_policy.ecs_exec_policy.arn
}