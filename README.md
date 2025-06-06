# Infraestrutura para Serviços Java do Projeto Real State

Este repositório contém o código Terraform para provisionar e gerenciar a infraestrutura AWS necessária para os serviços Java do projeto "Real State".

## Visão Geral

O projeto provisiona os seguintes componentes principais:

*   **Rede:**
    *   Uma Virtual Private Cloud (VPC) customizada.
    *   Subnets públicas e privadas distribuídas em múltiplas Zonas de Disponibilidade.
    *   Internet Gateway para acesso à internet nas subnets públicas.
    *   NAT Gateway para permitir que recursos em subnets privadas acessem a internet (ex: para puxar dependências ou conectar-se a APIs externas como MongoDB Atlas).
    *   Tabelas de Rota para controlar o fluxo de tráfego.
*   **Balanceamento de Carga:**
    *   Um Application Load Balancer (ALB) para distribuir o tráfego HTTP para os serviços.
*   **Computação (ECS Fargate):**
    *   Um cluster Amazon Elastic Container Service (ECS).
    *   Serviços ECS Fargate para cada microsserviço Java:
        *   `srv-cad-usuarios`
        *   `srv-cad-imoveis`
        *   `srv-cad-company`
    *   Definições de Tarefa ECS configuradas com logging, variáveis de ambiente e health checks.
*   **Registros de Container:**
    *   Repositórios Amazon Elastic Container Registry (ECR) para cada serviço, onde as imagens Docker serão armazenadas.
*   **IAM e Segurança:**
    *   IAM Roles para execução de tarefas ECS e para permissões específicas das aplicações (ex: acesso ao DynamoDB para `srv-cad-company`).
    *   Security Groups para controlar o tráfego de entrada e saída para o ALB e os serviços ECS.
*   **Logging:**
    *   Grupos de Log no CloudWatch para cada serviço ECS.

## Pré-requisitos

*   Terraform CLI (versão especificada em `providers.tf`, atualmente `~> 5.0` para o provider AWS).
*   Credenciais AWS configuradas e com as permissões necessárias para criar os recursos definidos.
*   Um bucket S3 central para armazenar o estado do Terraform. Este projeto está configurado para usar o bucket `real-state-terraform-state-bucket`.

## Configuração

### 1. Backend

O estado do Terraform para este projeto é armazenado remotamente em um bucket S3. A configuração do backend está definida em `backend.tf`:

```hcl
terraform {
  backend "s3" {
    bucket         = "real-state-terraform-state-bucket"
    key            = "real-state-java-services/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    use_lockfile   = true
  }
}
```

Certifique-se de que o bucket S3 (`real-state-terraform-state-bucket`) exista na região `us-east-1` antes de inicializar o Terraform.

### 2. Variáveis

As variáveis de configuração estão definidas em `variables.tf`. Algumas variáveis importantes que podem precisar ser fornecidas ou ajustadas:

*   `aws_region`: Região AWS (padrão: `us-east-1`).
*   `project_name`: Nome base para os recursos (padrão: `real-state-java-services`).
*   `environment`: Ambiente de deploy (padrão: `dev`).
*   `srv_cad_usuarios_image_tag`, `srv_cad_imoveis_image_uri`, `srv_cad_company_image_uri`: URIs ou tags das imagens Docker para os respectivos serviços. Estas devem ser fornecidas, geralmente via pipeline de CI/CD ou variáveis de ambiente.
*   `dynamodb_db_cad_company_table_name`: Nome da tabela DynamoDB para o serviço `srv-cad-company`.
*   `mongodb_atlas_connection_string`, `mongodb_database_name_cad_advertisement`: Para o serviço `srv-cad-imoveis`.
*   `mongodb_atlas_connection_string_usuarios`, `mongodb_database_name_usuarios`: Para o serviço `srv-cad-usuarios`.

**Importante:** Variáveis sensíveis como as strings de conexão do MongoDB (`mongodb_atlas_connection_string*`) **não devem** ser commitadas em arquivos `.tfvars`. Forneça-as através de variáveis de ambiente (prefixadas com `TF_VAR_`) ou através de um sistema de gerenciamento de segredos no seu pipeline de CI/CD.

Você pode criar um arquivo `terraform.tfvars` (que está no `.gitignore` por padrão para evitar o commit de segredos) para definir valores não sensíveis ou para desenvolvimento local:

```hcl
# Exemplo de terraform.tfvars (NÃO COMMITE SE CONTIVER SEGREDOS)
# project_name = "meu-projeto-java"
# environment  = "staging"
# srv_cad_usuarios_image_tag = "v1.2.3"
# dynamodb_db_cad_company_table_name = "minha-tabela-company-dev"
```

## Uso

1.  **Inicializar o Terraform:**
    Navegue até o diretório raiz do projeto e execute:
    ```bash
    terraform init
    ```
    Isso baixará os provedores necessários e configurará o backend.

2.  **Planejar as Mudanças:**
    Para ver quais recursos o Terraform criará, modificará ou destruirá:
    ```bash
    terraform plan
    ```
    Para ambientes não interativos ou para salvar o plano:
    ```bash
    terraform plan -out=tfplan
    ```

3.  **Aplicar as Mudanças:**
    Para criar ou atualizar a infraestrutura:
    ```bash
    terraform apply
    ```
    Ou, se você salvou um plano:
    ```bash
    terraform apply tfplan
    ```

4.  **Destruir a Infraestrutura:**
    Para remover todos os recursos criados por este projeto (use com cuidado!):
    ```bash
    terraform destroy
    ```

## Outputs

O projeto define alguns outputs em `outputs.tf` que podem ser úteis, como:
*   `vpc_id`: O ID da VPC criada.
*   `alb_dns_name`: O nome DNS do Application Load Balancer, usado para acessar os serviços.
*   `ecs_cluster_name`: O nome do cluster ECS.

## CI/CD

Este projeto pode ser integrado a um pipeline de CI/CD (como GitHub Actions) para automatizar os processos de `plan` e `apply`.