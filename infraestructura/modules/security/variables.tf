variable "name_prefix" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "app_port" {
  type = number
}

variable "monitoring_enabled" {
  description = "Abrir puertos de Prometheus (9090) y Grafana (3000). Para produccion considera restringir cidr_blocks o usar SSH tunneling"
  type        = bool
  default     = true
}
