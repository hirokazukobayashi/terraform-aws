#権限　ecrへの接続には"ecr:GetAuthorizationToken"を付与必須　
data "aws_iam_policy_document" "codebuild" {
  statement {
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:GetObjectVersion",
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:GetRepositoryPolicy",
      "ecr:DescribeRepositories",
      "ecr:ListImages",
      "ecr:DescribeImages",
      "ecr:BatchGetImage",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
      "ecr:PutImage",
      "secretsmanager:GetSecretValue",
      "kms:*",
      "ec2:*"
    ]
  }
}

module "codebuild_role" {
  source     = "../modules/iam_role"
  name       = "${var.service_name}-codebuild-role-${var.stage}"
  identifier = "codebuild.amazonaws.com"
  policy     = data.aws_iam_policy_document.codebuild.json
}

resource "aws_codebuild_project" "codebuild_project" {
  name         = "${var.service_name}-codebuild-${var.stage}"
  service_role = module.codebuild_role.iam_role_arn

  source {
    type      = "CODEPIPELINE"
    buildspec = "codebuild/buildspec-java.yml"
  }

  artifacts {
    type = "CODEPIPELINE"
  }

  ##コードビルドからDBへ接続するためにはVPC設定、セキュリティグループの設定が必要（マイぐれやテストでDBに接続する）
  ##初期時に設定できないので、後付けした
  vpc_config {
    vpc_id = aws_vpc.vpc.id

    subnets = [
      aws_subnet.private_a.id,
      aws_subnet.private_c.id
    ]

    security_group_ids = [module.ecs_sg.security_group_id]

  }

  # aws-cliを入れたカスタムイメージにした方が良い
  environment {
    type            = "LINUX_CONTAINER"
    compute_type    = "BUILD_GENERAL1_SMALL"
    image           = "aws/codebuild/standard:1.0"
    privileged_mode = true

    environment_variable {
      name  = "IMAGE_TAG"
      value = "${var.stage}"
    }

    environment_variable {
      name  = "ECR_BASE"
      value = "${var.account_id}.dkr.ecr.ap-northeast-1.amazonaws.com/${var.service_name}"
    }

    environment_variable {
      name  = "FlywayClean"
      value = ""
    }
  }
}

resource "aws_codebuild_project" "codebuild_project_app" {
  name         = "${var.service_name}_app"
  service_role = module.codebuild_role.iam_role_arn

  source {
    type      = "CODEPIPELINE"
    buildspec = "codebuild/buildspec-appserver.yml"
  }

  artifacts {
    type = "CODEPIPELINE"
  }

  ##コードビルドからDBへ接続するためにはVPC設定、セキュリティグループの設定が必要（マイぐれやテストでDBに接続する）
  ##初期時に設定できないので、後付けした
  vpc_config {
    vpc_id = aws_vpc.vpc.id

    subnets = [
      aws_subnet.private_a.id,
      aws_subnet.private_c.id
    ]

    security_group_ids = [module.ecs_sg.security_group_id]

  }

  environment {
    type            = "LINUX_CONTAINER"
    compute_type    = "BUILD_GENERAL1_SMALL"
    image           = "aws/codebuild/standard:1.0"
    privileged_mode = true

    environment_variable {
      name  = "IMAGE_TAG"
      value = "${var.stage}"
    }

    environment_variable {
      name  = "ECR_BASE"
      value = "${var.account_id}.dkr.ecr.ap-northeast-1.amazonaws.com/${var.service_name}"
    }
  }
}
