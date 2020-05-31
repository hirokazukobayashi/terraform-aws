# state保管バケット
resource "aws_s3_bucket" "state" {
  bucket        = "${var.service_name}-state-${var.stage}"
  force_destroy = true

  lifecycle_rule {
    enabled = true

    expiration {
      days = "180"
    }
  }
}

resource "aws_s3_bucket_policy" "state" {
  bucket = aws_s3_bucket.state.id
  policy = data.aws_iam_policy_document.state.json
}

data "aws_iam_policy_document" "state" {
  statement {
    effect    = "Allow"
    actions   = ["s3:GetObject", "s3:PutObject"]
    resources = ["arn:aws:s3:::${aws_s3_bucket.state.id}/*"]

    principals {
      type        = "AWS"
      identifiers = ["582318560864"]
    }
  }
}

# ALB ログバケット
resource "aws_s3_bucket" "alb_log" {
  bucket        = "${var.service_name}-alb-log-${var.stage}"
  force_destroy = true

  lifecycle_rule {
    enabled = true

    expiration {
      days = "180"
    }
  }
}

resource "aws_s3_bucket_policy" "alb_log" {
  bucket = aws_s3_bucket.alb_log.id
  policy = data.aws_iam_policy_document.alb_log.json
}

data "aws_iam_policy_document" "alb_log" {
  statement {
    effect    = "Allow"
    actions   = ["s3:PutObject"]
    resources = ["arn:aws:s3:::${aws_s3_bucket.alb_log.id}/*"]

    principals {
      type        = "AWS"
      identifiers = ["582318560864"]
    }
  }
}