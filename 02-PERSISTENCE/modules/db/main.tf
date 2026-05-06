resource "aws_db_subnet_group" "this" {
  name       = "sng-db-${terraform.workspace}"
  subnet_ids = var.subnet_ids
}

resource "aws_security_group" "rds_sg" {
  name   = "SG-rds-${terraform.workspace}"
  vpc_id = var.vpc_id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [var.worker_sg_id] # Solo los Workers entran
  }
}

resource "aws_db_instance" "this" {
  identifier             = "db-n8n-${terraform.workspace}"
  engine                 = "postgres"
  engine_version         = "17.6"
  instance_class         = var.db_instance_class
  allocated_storage      = var.db_allocated_storage
  db_name                = "n8ndb"
  username               = "dunAdmin"
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  skip_final_snapshot    = true
  multi_az               = true
}