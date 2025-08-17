# 1) OIDC provider for this cluster (derived from the EKS cluster created in this module)
data "tls_certificate" "oidc" {
  url = aws_eks_cluster.this.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks" {
  url             = aws_eks_cluster.this.identity[0].oidc[0].issuer
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.oidc.certificates[0].sha1_fingerprint]
}

# 2) Custom policy: allow SQS receive/delete & S3 get/put/list
resource "aws_iam_policy" "consumer_policy" {
  name        = var.consumer_policy_name
  description = "Allow consumer to read from SQS and read/write S3 objects"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = ["sqs:ReceiveMessage", "sqs:DeleteMessage", "sqs:GetQueueAttributes"],
        Resource = var.sqs_queue_arn
      },
      # --- THIS IS THE FIX ---
      # Added a new statement to allow listing the raw bucket contents
      {
        Effect   = "Allow",
        Action   = "s3:ListBucket",
        Resource = "arn:aws:s3:::${var.raw_bucket_name}" # Note: No "/*"
      },
      # This statement allows getting/putting objects in both buckets
      {
        Effect = "Allow",
        Action = ["s3:GetObject", "s3:PutObject"],
        Resource = [
          "arn:aws:s3:::${var.raw_bucket_name}/*",
          "arn:aws:s3:::${var.thumb_bucket_name}/*"
        ]
      }
    ]
  })
}

# 3) IAM role for the ServiceAccount (IRSA)
data "aws_iam_policy_document" "consumer_assume_role" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.eks.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:${var.consumer_namespace}:${var.consumer_service_account}"]
    }
  }
}

resource "aws_iam_role" "consumer_irsa" {
  name               = var.consumer_role_name
  assume_role_policy = data.aws_iam_policy_document.consumer_assume_role.json
}

# Attach the custom policy
resource "aws_iam_role_policy_attachment" "consumer_attach_custom" {
  role       = aws_iam_role.consumer_irsa.name
  policy_arn = aws_iam_policy.consumer_policy.arn
}
