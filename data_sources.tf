data "terraform_remote_state" "dynamodb" {
  backend = "s3"

  config = {
    bucket = "real-state-terraform-state-bucket"
    key    = "real-state-dynamodb/terraform.tfstate"
    region = "us-east-1"
  }
}

data "aws_caller_identity" "current" {}
data "aws_elb_service_account" "current" {}