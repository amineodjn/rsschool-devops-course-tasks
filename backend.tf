terraform {
  backend "s3" {
    bucket         = "terraform-devops-course-11579"
    key            = "global/s3/terraform.tfstate"
    region         = "eu-central-1"
    encrypt        = true
    dynamodb_table = "terraform-lock"
  }
} 