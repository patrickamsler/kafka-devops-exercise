module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${var.cluster_name}-vpc"
  cidr = "10.0.0.0/16"

  azs = ["${var.region}a", "${var.region}b", "${var.region}c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true
}

module "ebs_csi_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.39"

  role_name_prefix = "${var.cluster_name}-ebs-csi-"
  attach_ebs_csi_policy = true

  oidc_providers = {
    this = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
    }
  }
}

data "http" "whoami" {
  url = "https://checkip.amazonaws.com"
}

locals {
  my_ip = chomp(data.http.whoami.response_body)
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = var.cluster_name
  cluster_version = var.k8s_version

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  cluster_endpoint_public_access        = true
  # cluster_endpoint_public_access_cidrs  = ["0.0.0.0/0"] # Allow access from anywhere
  cluster_endpoint_public_access_cidrs  = [ "${local.my_ip}/32" ]  # access from my IP only
  enable_cluster_creator_admin_permissions = true

  eks_managed_node_groups = {
    ng = {
      instance_types = [var.node_type]
      desired_size   = 3
      min_size       = 3
      max_size       = 3
      subnets        = module.vpc.private_subnets
    }
  }

  cluster_addons = {
    aws-ebs-csi-driver = {
      most_recent               = true
      service_account_role_arn  = module.ebs_csi_irsa.iam_role_arn
    }
  }
}