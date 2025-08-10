output "cluster_name" { value = module.eks.cluster_name }
output "cluster_region" { value = var.region }
output "cluster_endpoint" { value = module.eks.cluster_endpoint }
output "my_ip" { value = local.my_ip }