variable "aws_region" {
  description = "Região AWS para implantar os recursos"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Nome base para os recursos do projeto (ex: real-state-services)"
  type        = string
  default     = "real-state-java-services"
}

variable "environment" {
  description = "Ambiente de deploy (ex: dev, stg, prod)"
  type        = string
  default     = "dev"
}

variable "vpc_cidr_block" {
  description = "Bloco CIDR para a VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "Lista de blocos CIDR para as subnets públicas"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "Lista de blocos CIDR para as subnets privadas"
  type        = list(string)
  default     = ["10.0.3.0/24", "10.0.4.0/24"]
}

variable "availability_zones" {
  description = "Lista de Zonas de Disponibilidade a serem usadas"
  type        = list(string)
  # Certifique-se de que estas AZs estão disponíveis na sua var.aws_region
  # Exemplo para us-east-1
  default = ["us-east-1a", "us-east-1b"]
}

variable "srv_cad_users_image_tag" {
  description = "Tag da imagem Docker para o serviço srv-cad-users (ex: latest, v1.0.0, ou hash do commit)"
  type        = string
  default     = "latest" # Ou um valor padrão apropriado
}

variable "srv_cad_advertisements_image_tag" {
  description = "Tag da imagem Docker para o serviço srv-cad-advertisements (ex: latest, v1.0.0, ou hash do commit)"
  type        = string
  default     = "latest"
}

variable "srv_cad_company_image_tag" {
  description = "Tag da imagem Docker para o serviço srv-cad-company (ex: latest, v1.0.0, ou hash do commit)"
  type        = string
  default     = "latest"
}

variable "auth_server_image_tag" {
  description = "Tag da imagem Docker para o serviço auth-server"
  type        = string
  default     = "latest"
}

variable "log_retention_days" {
  description = "Número de dias para reter os logs no CloudWatch para os serviços ECS."
  type        = number
  default     = 7
}

variable "db_cad_company_table_name" {
  description = "Nome da tabela DynamoDB 'db-cad-company' a ser usada pelos serviços Java."
  type        = string
  # Este valor será fornecido externamente, por exemplo, via -var ou um arquivo .tfvars
}

variable "mongodb_atlas_connection_string" {
  description = "String de conexão para o MongoDB Atlas usado pelo srv-cad-imoveis."
  type        = string
  sensitive   = true # Importante para dados sensíveis
  # Este valor deve ser fornecido via TF_VAR_mongodb_atlas_connection_string ou um arquivo .tfvars seguro (não commitado)
}

variable "mongodb_database_name_advertisement" {
  description = "Nome do banco de dados no MongoDB Atlas para o serviço de anúncios."
  type        = string
}

variable "mongodb_database_name_users" {
  description = "Nome do banco de dados no MongoDB Atlas para o serviço de usuários."
  type        = string
}

variable "root_log_level" {
  description = "Nível de log raiz para as aplicações Spring Boot (ex: INFO, DEBUG)."
  type        = string
  default     = "INFO"
}

variable "spring_log_level" {
  description = "Nível de log específico para pacotes Spring (ex: INFO, DEBUG)."
  type        = string
  default     = "INFO"
}

variable "client_web_secret" {
  description = "Client secret para o cliente web (ex: frontend)."
  type        = string
  sensitive   = true
}

variable "auth_server_client_secret" {
  description = "Client secret para o próprio auth-server (client credentials flow)."
  type        = string
  sensitive   = true
}

variable "jks_uri" {
  description = "URI para o arquivo JKS, se utilizado pelos serviços."
  type        = string
  default     = null # Torna opcional, fornecer via secret se necessário
  sensitive   = true # JKS pode conter chaves privadas
}

variable "public_auth_server_url" {
  description = "A URL pública do auth-server, usada para o issuer-uri do OIDC."
  type        = string
  # Ex: "https://auth.dev.meudominio.com"
}