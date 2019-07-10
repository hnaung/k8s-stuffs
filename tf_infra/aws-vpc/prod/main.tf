provider "aws" {
  region = "ap-southeast-2"
}

data "aws_security_group" "default" {
  name   = "default"
  vpc_id = module.vpc.vpc_id
}

module "vpc" {
  source = "./modules/"

  name = "production-vpc"

  cidr = "172.31.0.0/16"

  azs             = ["ap-southeast-2a", "ap-southeast-2b", "ap-southeast-2c"]
  private_subnets = ["172.31.96.0/19", "172.31.128.0/19", "172.31.160.0/19"]
  public_subnets  = ["172.31.0.0/19", "172.31.32.0/19", "172.31.64.0/19"]

  assign_generated_ipv6_cidr_block = false

  enable_nat_gateway = true
  single_nat_gateway = true
  enable_dns_hostnames = true
  enable_dns_support   = true

  public_subnet_tags = {
    Name = "production-vpc-publicsubnet"
  }

  private_subnet_tags = {
    Name = "production-vpc-privatesubnet"
  }
  tags = {
    Owner       = "gplus"
    Environment = "production"
  }

  vpc_tags = {
    Name = "production-vpc"
  }
}

