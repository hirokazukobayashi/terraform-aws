//resource "aws_db_subnet_group" "db_subnet_group" {
//  name       = "${var.service_name}-db-subnet-group-${var.stage}"
//  subnet_ids = [aws_subnet.private_a.id, aws_subnet.private_c.id]
//}
//
//resource "aws_db_instance" "db" {
//  identifier        = "${var.service_name}-${var.stage}"
//  engine            = "postgres"
//  engine_version    = "11.7"
//  instance_class    = "db.t2.micro"
//  allocated_storage = 20
//  storage_type      = "gp2"
//  //  t2 microは暗号化できない
//  //  storage_encrypted          = true
//  //  kms_key_id                 = aws_kms_key.kms.arn
//  name                       = "${var.db_name}"
//  username                   = "postgres"
//  password                   = "postgres"
//  multi_az                   = false
//  publicly_accessible        = false
//  backup_window              = "09:10-09:40"
//  backup_retention_period    = 30
//  maintenance_window         = "mon:10:10-mon:10:40"
//  auto_minor_version_upgrade = false
//  deletion_protection        = false
//  skip_final_snapshot        = false
//  port                       = 5432
//  apply_immediately          = false
//  vpc_security_group_ids     = [module.postgres_ecs_sg.security_group_id]
//  #parameter_group_name       = aws_db_parameter_group.example.name
//  #option_group_name          = aws_db_option_group.example.name
//
//  db_subnet_group_name = aws_db_subnet_group.db_subnet_group.name
//
//  lifecycle {
//    ignore_changes = [password]
//  }
//}
//
//module "postgres_ecs_sg" {
//  source            = "../modules/security_group_ids"
//  name              = "${var.service_name}-postgres-${var.stage}"
//  vpc_id            = aws_vpc.vpc.id
//  port              = 5432
//  description       = "from ecs to postgres"
//  security_group_id = module.ecs_sg.security_group_id
//}
//
//
//
