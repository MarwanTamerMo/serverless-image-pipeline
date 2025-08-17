output "ecr_repo_url" {
  value = aws_ecr_repository.consumer.repository_url
}

output "cluster_name" {
  value = aws_eks_cluster.this.name
}

output "consumer_irsa_role_arn" {
  value       = aws_iam_role.consumer_irsa.arn
  description = "IAM Role ARN to annotate on the ServiceAccount (eks.amazonaws.com/role-arn)"
}
