resource "aws_efs_file_system" "this" {
  creation_token = "efs-k3s-${terraform.workspace}"
  encrypted      = true
  tags           = { Name = "EFS-K3s-${terraform.workspace}" }
}

resource "aws_security_group" "efs_sg" {
  name   = "SG-fs-${terraform.workspace}"
  vpc_id = var.vpc_id

  ingress {
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [var.worker_sg_id]
  }
}

resource "aws_efs_mount_target" "this" {
  count           = length(var.subnet_ids)
  file_system_id  = aws_efs_file_system.this.id
  subnet_id       = var.subnet_ids[count.index]
  security_groups = [aws_security_group.efs_sg.id]
}