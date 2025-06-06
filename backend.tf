terraform {
  backend "s3" {
    bucket         = "real-state-terraform-state-bucket"     # O mesmo bucket S3 central usado pelo projeto DynamoDB
    key            = "real-state-java-services/terraform.tfstate"  # Caminho único para o estado deste projeto de serviços Java
    region         = "us-east-1"                             # A mesma região do bucket S3
    encrypt        = true                                    # Criptografa o estado em repouso
    use_lockfile   = true                                    # Habilita o bloqueio de estado baseado em arquivo no S3
  }
}