#設定したセキュリティグループを指定する場合に使用する
#DBのセキュリティグループのingressルールで活用
variable "name" {}
variable "vpc_id" {}
variable "port" {}
variable "security_group_id" {}
variable "description" {}



resource "aws_security_group" "security_group" {
  name   = var.name
  vpc_id = var.vpc_id
  description = "${var.description}"
}

resource "aws_security_group_rule" "ingress" {
  type              = "ingress"
  from_port         = var.port
  to_port           = var.port
  protocol          = "tcp"
  security_group_id = aws_security_group.security_group.id
  source_security_group_id = var.security_group_id
}

resource "aws_security_group_rule" "egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.security_group.id
}

output "security_group_id" {
  value = aws_security_group.security_group.id
}
