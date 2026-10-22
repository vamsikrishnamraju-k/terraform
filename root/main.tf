provider "aws" {
  region = "us-east-1"
}

module "network" {
  source = "../modules/vpc"

  # VPC Name
  vpc_name = "vamsi-vpc"

  # VPC CIDR Block
  vpc_cidr = "10.0.0.0/16"

  # Availability Zones where subnets will be created
  azs = [
    "us-east-1a",
    "us-east-1b"
  ]

  # Public Subnets
  public_subnets = {
    "public-subnet-1" = {
      cidr = "10.0.0.0/20"
      az   = "us-east-1a"
    }

    "public-subnet-2" = {
      cidr = "10.0.16.0/20"
      az   = "us-east-1b"
    }
  }

  # Private Subnets
  private_subnets = {
    "private-subnet-1" = "10.0.48.0/20"
    "private-subnet-2" = "10.0.64.0/20"
  }

  # Create NAT Gateway for private subnets
  create_nat_gateway = true

  # Common tags for all resources
  common_tags = {
    Project     = "learning-terraform"
    Environment = "Development"
    ManagedBy   = "vamasi"
  }

}

module "eks" {
  source = "../modules/eks"

  cluster_name = "vamsi"

  vpc_id = module.network.vpc_id

  subnet_ids = module.network.public_subnet_ids
}