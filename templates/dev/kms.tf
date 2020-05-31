#鍵管理
resource "aws_kms_key" "kms" {
  description             = "${var.service_name} Customer Master Key"
  enable_key_rotation     = true
  is_enabled              = true
  deletion_window_in_days = 30
}

resource "aws_kms_alias" "kms_alias" {
  name          = "alias/${var.service_name}-kms-${var.stage}"
  target_key_id = aws_kms_key.kms.key_id
}
