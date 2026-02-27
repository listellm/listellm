data "aws_caller_identity" "current" {}

# -----------------------------------------------------------------------------
# OIDC provider — GitHub Actions federation
# -----------------------------------------------------------------------------

resource "aws_iam_openid_connect_provider" "github_actions" {
  #checkov:skip=CKV_AWS_358:Single-owner personal repo; StringLike wildcard is intentional

  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1", # pragma: allowlist secret
    "1c58a3a8518e8759bf075b76b750d4f2df264fcd", # pragma: allowlist secret
  ]
}

# -----------------------------------------------------------------------------
# Trust policy — allow GitHub Actions to assume the role via OIDC
# -----------------------------------------------------------------------------

data "aws_iam_policy_document" "github_actions_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github_actions.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:listellm/listellm:*"]
    }
  }
}

# -----------------------------------------------------------------------------
# IAM role — GitHub Actions
# -----------------------------------------------------------------------------

resource "aws_iam_role" "github_actions" {
  name               = "listell-github-actions"
  description        = "GitHub Actions OIDC role for listellm/listellm"
  assume_role_policy = data.aws_iam_policy_document.github_actions_assume.json
}

# -----------------------------------------------------------------------------
# Inline policy — least-privilege permissions for holding-page infra
# -----------------------------------------------------------------------------

data "aws_iam_policy_document" "github_actions" {
  statement {
    sid    = "TerraformStateBucket"
    effect = "Allow"

    actions = [
      "s3:ListBucket",
      "s3:GetBucketVersioning",
    ]

    resources = ["arn:aws:s3:::listell-co-uk-terraform-state"]
  }

  statement {
    sid    = "TerraformStateObjects"
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
    ]

    resources = ["arn:aws:s3:::listell-co-uk-terraform-state/holding-page/*"]
  }

  statement {
    sid    = "S3OriginBucket"
    effect = "Allow"

    actions = ["s3:*"]

    resources = [
      "arn:aws:s3:::${local.bucket_name}",
      "arn:aws:s3:::${local.bucket_name}/*",
    ]
  }

  statement {
    sid    = "CloudFront"
    effect = "Allow"

    actions = [
      "cloudfront:GetDistribution",
      "cloudfront:GetDistributionConfig",
      "cloudfront:CreateDistribution",
      "cloudfront:UpdateDistribution",
      "cloudfront:DeleteDistribution",
      "cloudfront:TagResource",
      "cloudfront:UntagResource",
      "cloudfront:ListTagsForResource",
      "cloudfront:GetOriginAccessControl",
      "cloudfront:GetOriginAccessControlConfig",
      "cloudfront:CreateOriginAccessControl",
      "cloudfront:UpdateOriginAccessControl",
      "cloudfront:DeleteOriginAccessControl",
      "cloudfront:ListOriginAccessControls",
      "cloudfront:GetCachePolicy",
      "cloudfront:ListCachePolicies",
    ]

    resources = ["*"]
  }

  statement {
    sid    = "ACM"
    effect = "Allow"

    actions = [
      "acm:DescribeCertificate",
      "acm:ListCertificates",
      "acm:RequestCertificate",
      "acm:DeleteCertificate",
      "acm:AddTagsToCertificate",
      "acm:RemoveTagsFromCertificate",
      "acm:ListTagsForCertificate",
    ]

    resources = ["*"]
  }

  statement {
    sid    = "Route53GlobalList"
    effect = "Allow"

    actions = [
      "route53:ListHostedZones",
      "route53:ListHostedZonesByName",
    ]

    # Route53 list operations cannot be resource-scoped
    resources = ["*"]
  }

  statement {
    sid    = "Route53ZoneScoped"
    effect = "Allow"

    actions = [
      "route53:GetHostedZone",
      "route53:ListResourceRecordSets",
      "route53:ChangeResourceRecordSets",
      "route53:ListTagsForResource",
    ]

    resources = [data.aws_route53_zone.listell.arn]
  }

  statement {
    sid    = "Route53ChangeStatus"
    effect = "Allow"

    actions = ["route53:GetChange"]

    resources = ["arn:aws:route53:::change/*"]
  }

  # IAM actions needed to manage the OIDC provider and this role via Terraform
  statement {
    sid    = "IAMSelfManagement"
    effect = "Allow"

    actions = [
      "iam:GetOpenIDConnectProvider",
      "iam:CreateOpenIDConnectProvider",
      "iam:DeleteOpenIDConnectProvider",
      "iam:UpdateOpenIDConnectProviderThumbprint",
      "iam:AddClientIDToOpenIDConnectProvider",
      "iam:RemoveClientIDFromOpenIDConnectProvider",
      "iam:TagOpenIDConnectProvider",
      "iam:UntagOpenIDConnectProvider",
      "iam:ListOpenIDConnectProviderTags",
      "iam:GetRole",
      "iam:CreateRole",
      "iam:UpdateRole",
      "iam:DeleteRole",
      "iam:UpdateAssumeRolePolicy",
      "iam:TagRole",
      "iam:UntagRole",
      "iam:ListRoleTags",
      "iam:GetRolePolicy",
      "iam:PutRolePolicy",
      "iam:DeleteRolePolicy",
      "iam:ListRolePolicies",
      "iam:ListAttachedRolePolicies",
      "iam:ListInstanceProfilesForRole",
    ]

    resources = [
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/token.actions.githubusercontent.com",
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/listell-github-actions",
    ]
  }
}

resource "aws_iam_role_policy" "github_actions" {
  name   = "listell-holding-page"
  role   = aws_iam_role.github_actions.id
  policy = data.aws_iam_policy_document.github_actions.json
}
