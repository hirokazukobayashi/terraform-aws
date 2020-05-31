#リポジトリ作成
resource "aws_ecr_repository" "ecr_repository" {
  # タグで管理するので、ECRは1アカウントで1つで良い
  name = "${var.service_name}"
}

#リポジトリに保存する期間の設定
resource "aws_ecr_lifecycle_policy" "ecr_lifecycle_policy" {
  repository = aws_ecr_repository.ecr_repository.name

  policy = <<EOF
  {
    "rules": [
      {
        "rulePriority": 1,
        "description": "Keep last 30 release tagged images",
        "selection": {
          "tagStatus": "tagged",
          "tagPrefixList": ["${var.stage}"],
          "countType": "imageCountMoreThan",
          "countNumber": 30
        },
        "action": {
          "type": "expire"
        }
      }
    ]
  }
EOF
}