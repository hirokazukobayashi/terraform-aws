variable "name" {}
variable "policy" {}
variable "identifier" {}

resource "aws_iam_role" "iam_role" {
  name               = var.name
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = [var.identifier]
    }
  }
}

resource "aws_iam_policy" "iam_policy" {
  name   = var.name
  policy = var.policy
}

resource "aws_iam_role_policy_attachment" "policy_attachment" {
  role       = aws_iam_role.iam_role.name
  policy_arn = aws_iam_policy.iam_policy.arn
}

output "iam_role_arn" {
  value = aws_iam_role.iam_role.arn
}

output "iam_role_name" {
  value = aws_iam_role.iam_role.name
}