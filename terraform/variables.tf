variable "region" {
  type    = string
  default = "eu-central-1"
}

variable "cluster_name" {
  type    = string
  default = "eks-test-cluster"
}

variable "node_type" {
  type    = string
  default = "t3.large"
}

variable "k8s_version" {
  type    = string
  default = "1.33"
}