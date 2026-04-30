resource "aws_ecr_repository" "api" {
  name                 = "mindmeld-api"
  image_tag_mutability = "MUTABLE"
  force_delete         = true # Allows us to cleanly destroy the environment later

  image_scanning_configuration {
    scan_on_push = true
  }
}
