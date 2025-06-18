variable "github_repository" {
  description = "GitHub repository in format: organization/repository"
  type        = string
  default     = "amineodjn/rsschool-devops-course-tasks"
}

variable "aws_region" {
  description = "AWS Region for resources"
  type        = string
  default     = "eu-central-1"
}

variable "aws_account_id" {
  description = "AWS Account ID"
  type        = string
  default     = "679128292768"
}

variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  default = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  default = ["10.0.101.0/24", "10.0.102.0/24"]
}

variable "azs" {
  description = "List of AZs"
  type        = list(string)
  default     = ["eu-central-1a", "eu-central-1b"]
} 