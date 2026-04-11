resource "random_password" "db" {
  count   = var.create_rds && var.db_password == "" ? 1 : 0
  length  = 24
  special = true
}

locals {
  effective_db_password = var.create_rds ? (var.db_password != "" ? var.db_password : random_password.db[0].result) : null
}

resource "aws_security_group" "rds" {
  count       = var.create_rds ? 1 : 0
  name        = "SG-RDS-${var.env}"
  description = "Permite PostgreSQL desde capa de aplicacion"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [var.app_sg_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_subnet_group" "main" {
  count      = var.create_rds ? 1 : 0
  name       = "db-subnets-${var.env}"
  subnet_ids = var.data_subnet_ids

  tags = {
    Name = "DB-Subnet-Group-${var.env}"
  }
}

resource "aws_db_instance" "main" {
  count                      = var.create_rds ? 1 : 0
  identifier                 = var.db_identifier
  engine                     = "postgres"
  engine_version             = var.db_engine_version
  instance_class             = var.db_instance_class
  allocated_storage          = var.db_allocated_storage
  db_name                    = var.db_name
  username                   = var.db_username
  password                   = local.effective_db_password
  db_subnet_group_name       = aws_db_subnet_group.main[0].name
  vpc_security_group_ids     = [aws_security_group.rds[0].id]
  multi_az                   = true
  publicly_accessible        = false
  storage_encrypted          = true
  backup_retention_period    = var.db_backup_retention_days
  skip_final_snapshot        = var.db_skip_final_snapshot
  deletion_protection        = false
  auto_minor_version_upgrade = true
}

output "rds_endpoint" {
  value = var.create_rds ? aws_db_instance.main[0].endpoint : null
}

output "rds_identifier" {
  value = var.create_rds ? aws_db_instance.main[0].id : null
}

output "rds_generated_password" {
  value     = var.create_rds ? (var.db_password == "" ? random_password.db[0].result : null) : null
  sensitive = true
}


data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_security_group" "ec2_db" {
  count       = var.create_rds ? 0 : 1
  name        = "SG-EC2-DB-"
  description = "Permite PostgreSQL desde capa de aplicacion a EC2 DB"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [var.app_sg_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "ec2_db" {
  count                  = var.create_rds ? 0 : 1
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.medium"
  subnet_id              = var.data_subnet_ids[0]
  vpc_security_group_ids = [aws_security_group.ec2_db[0].id]
  key_name               = var.key_name

  user_data_base64 = base64gzip(<<-EOF
              #!/bin/bash
              apt-get update
              apt-get install -y postgresql postgresql-contrib git

              # Restart just to ensure paths exist
              systemctl restart postgresql

              sudo -u postgres psql -c "CREATE USER  WITH PASSWORD 'temp_pass_123';"
              sudo -u postgres psql -c "CREATE DATABASE  OWNER ;"

              sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/g" /etc/postgresql/*/main/postgresql.conf
              echo "host all all 0.0.0.0/0 md5" >> /etc/postgresql/*/main/pg_hba.conf
              systemctl restart postgresql

              # SQL Schema inyectado de forma local
              cat << 'SQLEOF' > /tmp/schema.sql
${file("${path.module}/schema.sql")}
SQLEOF

              sudo -u postgres psql -d ${var.db_name} -f /tmp/schema.sql
              EOF
  )

  tags = {
    Name = "EC2-DB-"
  }
}

output "ec2_db_endpoint" {
  value = var.create_rds ? null : aws_instance.ec2_db[0].private_ip
}

