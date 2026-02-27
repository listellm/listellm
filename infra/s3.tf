resource "aws_s3_bucket" "origin" {
  #checkov:skip=CKV_AWS_18: Access logging not required for a static holding page
  #checkov:skip=CKV_AWS_21: Versioning not required for a static holding page
  #checkov:skip=CKV_AWS_144: Cross-region replication not required for a static holding page
  #checkov:skip=CKV2_AWS_62: Event notifications not required for a static holding page

  bucket = local.bucket_name

  tags = {
    Name = local.bucket_name
  }
}

resource "aws_s3_bucket_public_access_block" "origin" {
  bucket = aws_s3_bucket.origin.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "origin" {
  bucket = aws_s3_bucket.origin.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

data "aws_iam_policy_document" "origin_oac" {
  statement {
    sid    = "AllowCloudFrontOAC"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.origin.arn}/*"]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.listell.arn]
    }
  }
}

resource "aws_s3_bucket_policy" "origin" {
  # Reference public access block to create implicit dependency — policy must be
  # applied after the block is in place
  bucket = aws_s3_bucket_public_access_block.origin.bucket
  policy = data.aws_iam_policy_document.origin_oac.json
}

resource "aws_s3_object" "index" {
  bucket       = aws_s3_bucket.origin.id
  key          = "index.html"
  content_type = "text/html"
  source       = "${path.module}/files/index.html"
  source_hash  = filemd5("${path.module}/files/index.html")
}
