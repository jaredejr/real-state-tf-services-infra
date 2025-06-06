locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }

  ecs_cluster_name = "${var.project_name}-cluster-${var.environment}"
}