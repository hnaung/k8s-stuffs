provider "aws" {
  region = "ap-southeast-2"
}

data "aws_security_group" "default" {
  name   = "default"
  vpc_id = module.vpc.vpc_id
}

module "vpc" {
  source = "./modules/"

  name = "staging-vpc"

  cidr = "192.168.0.0/16"

  azs             = ["ap-southeast-2a", "ap-southeast-2b", "ap-southeast-2c"]
  private_subnets = ["192.168.96.0/19", "192.168.128.0/19", "192.168.160.0/19"]
  public_subnets  = ["192.168.0.0/19", "192.168.32.0/19", "192.168.64.0/19"]

  assign_generated_ipv6_cidr_block = false

  enable_nat_gateway = true
  single_nat_gateway = true
  enable_dns_hostnames = true
  enable_dns_support = true
  public_subnet_tags = {
    Name = "staging-vpc-publicsubnet"
  }

  private_subnet_tags = {
    Name = "staging-vpc-privatesubnet"
  }
  tags = {
    Owner       = "gplus"
    Environment = "staging"
  }

  vpc_tags = {
    Name = "staging-vpc"
  }
}

