# Generate random string
resource "random_pet" "random" {
  length    = 2
  separator = "_"
}

# Create ECR repo to store the app container images
resource "aws_ecr_repository" "registry" {
  name                 = "${local.name_prefix}-registry"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }
}

# Create everything fargate (task, IAM roles, etc.)
