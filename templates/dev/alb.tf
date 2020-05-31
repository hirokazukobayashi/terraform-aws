#albはサブネットのpublicに設置
resource "aws_lb" "alb" {
  name                       = "${var.service_name}-alb-${var.stage}"
  load_balancer_type         = "application"
  internal                   = false
  idle_timeout               = 60
  enable_deletion_protection = false

  #違うazを2つ設定する必要あり
  subnets = [
    aws_subnet.public_a.id,
    aws_subnet.public_c.id
  ]

  access_logs {
    bucket  = aws_s3_bucket.alb_log.id
    enabled = true
  }

  security_groups = [
    module.http_sg.security_group_id,
    module.https_sg.security_group_id,
    module.http_redirect_sg.security_group_id,
  ]
}

#セキュリティグループ設定 http https redirectの設定
module "http_sg" {
  source      = "../modules/security_group_cidr"
  name        = "${var.service_name}-http-sg-${var.stage}"
  vpc_id      = aws_vpc.vpc.id
  port        = 80
  description = "${var.service_name}-http-sg-${var.stage}"
  cidr_blocks = ["0.0.0.0/0"]
}

module "https_sg" {
  source      = "../modules/security_group_cidr"
  name        = "${var.service_name}-https-sg-${var.stage}"
  vpc_id      = aws_vpc.vpc.id
  port        = 443
  description = "${var.service_name}-https-sg-${var.stage}"
  cidr_blocks = ["0.0.0.0/0"]
}

module "http_redirect_sg" {
  source      = "../modules/security_group_cidr"
  name        = "${var.service_name}-http-redirect-sg-${var.stage}"
  vpc_id      = aws_vpc.vpc.id
  port        = 8080
  description = "${var.service_name}-http-redirect-sg-${var.stage}"
  cidr_blocks = ["0.0.0.0/0"]
}

#ECS Fargateでは IPアドレスによるルーティングが 必要なので「ip」を指定
resource "aws_lb_target_group" "alb_target_group" {
  name                 = "${var.service_name}-target-group-${var.stage}"
  vpc_id               = aws_vpc.vpc.id
  target_type          = "ip"
  port                 = 80
  protocol             = "HTTP"
  deregistration_delay = 300

  health_check {
    path                = "/actuator/health"
    healthy_threshold   = 5
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    matcher             = 200
    port                = "traffic-port"
    protocol            = "HTTP"
  }

  stickiness {
    type            = "lb_cookie"
    cookie_duration = "86400"
  }

  depends_on = [aws_lb.alb]
}

#リスナーの設定 どのポートにどのプロトコルで問い合わせを受けつけるか　HTTPなので「80」
# forward - リクエストを別のターゲットグループに転送
# fixed-response - 固定の HTTPレスポンスを応答
# redirect - 別の URL にリダイレクト
resource "aws_lb_listener" "alb_listener_http" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "これは『HTTP』です"
      status_code  = "200"
    }
  }
}

#優先順位は数字が小さいほど高い　デフォルトルールは一番低い
resource "aws_lb_listener_rule" "alb_listener_rule" {
  listener_arn = aws_lb_listener.alb_listener_http.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_target_group.arn
  }

  condition {
    field  = "path-pattern"
    values = ["/*"]
  }
}

