resource "aws_iam_user" "jenkins" {
  name = "jenkins-eks-lab"
}

resource "aws_iam_user_policy" "jenkins_ecr" {
  name = "orders-service-ecr-access"
  user = aws_iam_user.jenkins.name

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Sid      = "ECRLogin"
        Effect   = "Allow"
        Action   = "ecr:GetAuthorizationToken"
        Resource = "*"
      },
      {
        Sid    = "OrdersRepositoryAccess"
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:PutImage",
          "ecr:BatchGetImage",
          "ecr:GetDownloadUrlForLayer",
          "ecr:DescribeImages"
        ]
        Resource = aws_ecr_repository.orders.arn
      }
    ]
  })
}

output "jenkins_user_arn" {
  value = aws_iam_user.jenkins.arn
}
