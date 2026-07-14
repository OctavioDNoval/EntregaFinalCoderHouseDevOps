variable "name_prefix" {
  type = string
}

variable "ami_id" {
  type = string
}

variable "instance_type" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "ec2_sg_id" {
  type = string
}

variable "app_repo_url" {
  type = string
}

variable "key_filename" {
  description = "Nombre del archivo .pem que se genera en la raiz del proyecto"
  type        = string
  default     = "clave.pem"
}
