variable "aws_region" {
  description = "Region de AWS donde se despliega la infra"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Prefijo usado para nombrar todos los recursos"
  type        = string
  default     = "todo-api"
}

variable "app_repo_url" {
  description = "URL publica del repo que la EC2 clonara (https://github.com/USUARIO/REPO.git)"
  type        = string
}

variable "instance_type" {
  description = "Tipo de instancia EC2 (free tier: t3.micro)"
  type        = string
  default     = "t3.micro"
}
