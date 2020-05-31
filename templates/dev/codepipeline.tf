#パイプラインに何を許可するか
data "aws_iam_policy_document" "codepipeline" {
  statement {
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:GetBucketVersioning",
      "codebuild:BatchGetBuilds",
      "codebuild:StartBuild",
      "ecs:DescribeServices",
      "ecs:DescribeTaskDefinition",
      "ecs:DescribeTasks",
      "ecs:ListTasks",
      "ecs:RegisterTaskDefinition",
      "ecs:UpdateService",
      "iam:PassRole",
    ]
  }
}

#パイプラインと権限を紐付け
module "codepipeline_role" {
  source     = "../modules/iam_role"
  name       = "${var.service_name}-codepipeline-role-${var.stage}"
  identifier = "codepipeline.amazonaws.com"
  policy     = data.aws_iam_policy_document.codepipeline.json
}

#成果物の置き場所をS3に
resource "aws_s3_bucket" "artifact" {
  bucket        = "${var.service_name}-artifact-${var.stage}"
  force_destroy = true

  lifecycle_rule {
    enabled = true

    expiration {
      days = "180"
    }
  }
}

#パイプラインの本体
#ソースのブランチを環境ごとに変更すること develop staging productionなど
resource "aws_codepipeline" "codepipeline" {
  name     = "${var.service_name}-codepipeline-${var.stage}"
  role_arn = module.codepipeline_role.iam_role_arn

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "ThirdParty"
      provider         = "GitHub"
      version          = 1
      output_artifacts = ["Source"]

      configuration = {
        Owner                = "${var.github_organization}"
        Repo                 = "${var.github_repository}"
        Branch               = "${var.github_branch}"
        PollForSourceChanges = false
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "BuildJava"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = 1
      input_artifacts  = ["Source"]
      output_artifacts = ["Java"]

      configuration = {
        ProjectName = aws_codebuild_project.codebuild_project.id
      }
      run_order = 1
    }

    action {
      name             = "BuildApp"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = 1
      input_artifacts  = ["Java"]
      output_artifacts = ["Build"]

      configuration = {
        ProjectName = aws_codebuild_project.codebuild_project_app.id
      }
      run_order = 2
    }

  }

  stage {
    name = "Deploy"

    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "ECS"
      version         = 1
      input_artifacts = ["Build"]

      configuration = {
        ClusterName = aws_ecs_cluster.cluster.name
        ServiceName = aws_ecs_service.ecs_service.name
        FileName    = "imagedefinitions.json"
      }
    }
  }

  artifact_store {
    location = aws_s3_bucket.artifact.id
    type     = "S3"
  }
}

# GitHubからのデータ取得設定
resource "aws_codepipeline_webhook" "codepipeline_webhook" {
  name            = "${var.service_name}"
  target_pipeline = aws_codepipeline.codepipeline.name
  target_action   = "Source"
  authentication  = "GITHUB_HMAC"

  authentication_configuration {
    secret_token = "VeryRandomStringMoreThan20Byte!"
  }

  filter {
    json_path    = "$.ref"
    match_equals = "refs/heads/{Branch}"
  }
}

provider "github" {
  organization = "${var.github_organization}"
}

#　イベントはプルリクなどpush以外も設定可能 name属性は不要
resource "github_repository_webhook" "repository_webhook" {
  repository = "${var.github_repository}"

  configuration {
    url          = aws_codepipeline_webhook.codepipeline_webhook.url
    secret       = "VeryRandomStringMoreThan20Byte!"
    content_type = "json"
    insecure_ssl = false
  }

  events = ["push"]
}