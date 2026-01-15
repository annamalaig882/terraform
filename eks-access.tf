
resource "aws_eks_access_entry" "admin_access" {
  cluster_name  = aws_eks_cluster.eks.name
  principal_arn = aws_iam_role.eks_admin_role.arn
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "admin_policy" {
  cluster_name  = aws_eks_cluster.eks.name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  principal_arn = aws_iam_role.eks_admin_role.arn

  access_scope {
    type = "cluster"
  }
}
