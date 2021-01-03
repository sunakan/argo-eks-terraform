locals {
  cluster_name    = "eks-example"
  cluster_version = "1.18"
}
################################################################################
# EKS
################################################################################
module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  version         = "13.2.1"
  cluster_name    = local.cluster_name
  cluster_version = local.cluster_version
  subnets         = module.vpc.public_subnets

  vpc_id = module.vpc.vpc_id

  ################################################
  # EKSのマネージドノードグループを作成
  # EKSはマネージドノードグループではない、ノードグループもサポート
  ################################################
  node_groups = {
    ng-1 = {
      desired_capacity = 2
      max_capacity     = 2
      min_capacity     = 2
      instance_type    = "t3.small"
    }
  }
  write_kubeconfig = false
}

################################################################################
# Terraformでk8sにアクセスするために必要
################################################################################
data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}
data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}
provider "kubernetes" {
  load_config_file = "false"
  host  = data.aws_eks_cluster.cluster.endpoint
  token = data.aws_eks_cluster_auth.cluster.token
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
}
