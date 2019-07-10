provider "aws" {
  region = "ap-southeast-2"
}

resource "aws_db_subnet_group" "prod-rds-private-subnet" {
  name       = "prod-rds-private-subnet-group"
  subnet_ids = ["${var.rds_subnet1}", "${var.rds_subnet2}", "${var.rds_subnet3}"]
}

resource "aws_security_group" "prod-rds-sg" {
  name   = "prod-rds-sg"
  vpc_id = "${var.vpc_id}"
}

# Ingress Security Port 3306
resource "aws_security_group_rule" "prod_mysql_inbound_access" {
  from_port         = 3306 
  protocol          = "tcp"
  security_group_id = "${aws_security_group.prod-rds-sg.id}"
  to_port           = 3306
  type              = "ingress"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_db_instance" "prod_mysql" {
  identifier		      = "${var.db_identifier}"
  allocated_storage           = "${var.allocated_storage}"
  storage_type                = "gp2"
  engine                      = "mysql"
  engine_version              = "${var.engine_version}"
  instance_class              = "${var.db_instance}"
  name                        = "${var.db_name}"
  username                    = "${var.db_username}"
  password                    = "${var.db_password}"
  storage_encrypted           = true
  db_subnet_group_name        = "${aws_db_subnet_group.prod-rds-private-subnet.name}"
  vpc_security_group_ids      = ["${aws_security_group.prod-rds-sg.id}"]
  allow_major_version_upgrade = true
  auto_minor_version_upgrade  = true
  backup_retention_period     = "${var.backup_retention_period}"
  backup_window               = "${var.backup_window}"
  maintenance_window          = "Sat:00:00-Sat:03:00"
  multi_az                    = true
  skip_final_snapshot         = true
}
