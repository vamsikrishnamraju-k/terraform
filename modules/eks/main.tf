module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name               = var.cluster_name
  kubernetes_version = "1.36"

  vpc_id     = var.vpc_id
  subnet_ids = var.subnet_ids

  # EKS API endpoint
  endpoint_public_access  = true
  endpoint_private_access = false

  # Give cluster creator admin permissions
  enable_cluster_creator_admin_permissions = true


  # Enable EKS Auto Mode
  compute_config = {
    enabled    = true
    node_pools = ["general-purpose", "system"]
  }


   /* # EKS Secrets encryption
  encryption_config = {
    provider_key_arn = aws_kms_key.eks.arn
    resources        = ["secrets"]
  } */


  # EKS Add-ons
  addons = {
    vpc-cni = {
      most_recent    = true   # This ensures that the add-on is always updated to the latest version.
      before_compute = true    # This ensures that the add-on is created before the compute resources (node groups) are created.
    }

    eks-pod-identity-agent = {
      most_recent    = true
      before_compute = true
    }

    kube-proxy = {
      most_recent = true
    }

    coredns = {
      most_recent = true
    }

    metrics-server = {
      most_recent = true
    }
  }

  # Managed Node Group
 /* eks_managed_node_groups = {
    system = {
      name = "vamsi-system"

      instance_types = ["t3.small"]

      min_size     = 2
      max_size     = 4
      desired_size = 3

      labels = {
        workload = "system"
      }
    }

    /*application = {
      name = "vamsi-application"

      instance_types = ["t3.small"]

      min_size     = 2
      max_size     = 5
      desired_size = 3

      labels = {
        workload = "application"
      }
    }
  }*/

  tags = {
    Environment = "production"
    Project     = "vamsi-eks"
  }
}