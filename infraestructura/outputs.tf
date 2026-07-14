output "api_url" {
  description = "URL publica de la API"
  value       = "http://${module.compute.public_ip}:8080"
}

output "ec2_public_ip" {
  description = "IP publica de la EC2"
  value       = module.compute.public_ip
}

output "ssh_command" {
  description = "Comando para conectarse por SSH"
  value       = "ssh -i clave.pem ec2-user@${module.compute.public_ip}"
}
