# ============================================================
# 1. GitHub OIDC Provider (one per AWS account)
# ============================================================

resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]

  tags = {
    Project = "Intelligent Document Pipeline"
  }
}

# ============================================================
# 2. Trust policy: Allow GitHub Actions from your repo to assume this role
#    CHANGE the repo name below to match yours!
# ============================================================

data "aws_iam_policy_document" "github_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      #CHANGE THIS to your GitHub username/repo
      values = ["repo:sindhujaVispute/AWS-document-pipeline:*"]
    }
  }
}

# ============================================================
# 3. Create the GitHub Actions IAM Role
# ============================================================

resource "aws_iam_role" "github_actions" {
  name               = "doc-pipeline-github-actions-role"
  assume_role_policy = data.aws_iam_policy_document.github_assume_role.json

  tags = {
    Project     = "Intelligent Document Pipeline"
    Environment = "Dev"
  }
}

# ============================================================
# 4. Grant GitHub Actions role permissions to deploy our infra
#    For simplicity, we grant broad permissions. In real production,
#    you would scope this to specific resources.
# ============================================================

resource "aws_iam_role_policy_attachment" "github_actions_admin" {
  role       = aws_iam_role.github_actions.name
  policy_arn = "arn:aws:iam::aws:policy/PowerUserAccess"
}

resource "aws_iam_role_policy" "github_actions_iam" {
  name = "github-actions-iam-management"
  role = aws_iam_role.github_actions.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "iam:GetRole",
        "iam:GetPolicy",
        "iam:GetPolicyVersion",
        "iam:ListRolePolicies",
        "iam:ListAttachedRolePolicies",
        "iam:PassRole",
        "iam:CreateRole",
        "iam:DeleteRole",
        "iam:PutRolePolicy",
        "iam:DeleteRolePolicy",
        "iam:AttachRolePolicy",
        "iam:DetachRolePolicy",
        "iam:CreateOpenIDConnectProvider",
        "iam:DeleteOpenIDConnectProvider",
        "iam:TagOpenIDConnectProvider",
        "iam:UpdateAssumeRolePolicy"
      ]
      Resource = "*"
    }]
  })
}