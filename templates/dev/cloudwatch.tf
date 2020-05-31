resource "aws_cloudwatch_log_group" "for_ecs" {
  name              = "/ecs/${var.service_name}-${var.stage}"
  retention_in_days = 180
}