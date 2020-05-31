#IAM
data "aws_iam_policy" "ecs_task_execution_role_policy" {
  arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

#SSMの権限も追加
data "aws_iam_policy_document" "ecs_task_execution" {
  source_json = data.aws_iam_policy.ecs_task_execution_role_policy.policy

  statement {
    effect    = "Allow"
    actions   = ["ssm:GetParameters", "kms:Decrypt"]
    resources = ["*"]
  }
}

module "ecs_task_execution_role" {
  source     = "../modules/iam_role"
  name       = "${var.service_name}-ecs-task-execution-${var.stage}"
  identifier = "ecs-tasks.amazonaws.com"
  policy     = data.aws_iam_policy_document.ecs_task_execution.json
}

#ECSの大枠　クラスターの作成
resource "aws_ecs_cluster" "cluster" {
  name = "${var.service_name}-ecs-cluster-${var.stage}"
}

# コンテナ定義
data "template_file" "container" {
  template = "${file("./container_definitions.json")}"

  vars = {
    service_name = "${var.service_name}"
    stage        = "${var.stage}"
    region       = "${var.region}"
    port         = 80
  }
}

#タスク定義　どのコンテナをどれぐらいのスペックでどの起動タイプで起動するか
resource "aws_ecs_task_definition" "task" {
  # ファミリーとはタスク定義名のプレフィックスで、familyに設定します。ファミリー にリビジョン番号を付与したものがタスク定義名になります。
  family                   = "${var.service_name}-task-${var.stage}"
  cpu                      = "${var.cpu}"
  memory                   = "${var.memory}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  container_definitions    = "${data.template_file.container.rendered}"
  execution_role_arn       = module.ecs_task_execution_role.iam_role_arn
}

#サービス定義　どのコンテナ（タスク定義）を起動するか
resource "aws_ecs_service" "ecs_service" {
  name                              = "${var.service_name}-ecs-service-${var.stage}"
  cluster                           = aws_ecs_cluster.cluster.arn
  task_definition                   = aws_ecs_task_definition.task.arn
  desired_count                     = 1
  launch_type                       = "FARGATE"
  platform_version                  = "1.3.0"
  health_check_grace_period_seconds = 60

  network_configuration {
    assign_public_ip = false
    security_groups  = [module.ecs_sg.security_group_id]

    subnets = [
      aws_subnet.private_a.id,
      aws_subnet.private_c.id
    ]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.alb_target_group.arn
    container_name   = "appserver-${var.service_name}"
    container_port   = 80
  }

  lifecycle {
    ignore_changes = [task_definition]
  }
}

module "ecs_sg" {
  source      = "../modules/security_group_cidr"
  name        = "${var.service_name}-ecs-sg-${var.stage}"
  vpc_id      = aws_vpc.vpc.id
  port        = 80
  description = "ecs_sg"
  cidr_blocks = [aws_vpc.vpc.cidr_block]
}