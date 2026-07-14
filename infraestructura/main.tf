data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

module "security" {
  source      = "./modules/security"
  name_prefix = var.project_name
  vpc_id      = data.aws_vpc.default.id
  app_port    = 8080
}

module "compute" {
  source        = "./modules/compute"
  name_prefix   = var.project_name
  ami_id        = data.aws_ami.al2023.id
  instance_type = var.instance_type
  subnet_id     = data.aws_subnets.default.ids[0]
  ec2_sg_id     = module.security.ec2_sg_id
  app_repo_url  = var.app_repo_url
}
