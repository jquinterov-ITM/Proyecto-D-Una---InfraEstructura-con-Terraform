
resource "aws_security_group" "alb" {
  name   = "SG-ALB-${var.env}"
  vpc_id = var.vpc_id
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "master" {
  name   = "SG-Master-${var.env}"
  vpc_id = var.vpc_id
  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    #cidr_blocks = [var.my_ip]
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    #cidr_blocks = [var.my_ip]
    cidr_blocks = ["0.0.0.0/0"]                               
  }
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
  }
  ingress { #n8n
    from_port = 30567
    to_port = 30567
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    }              
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "worker" {
  name   = "SG-Worker-${var.env}"
  vpc_id = var.vpc_id
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

output "sg_alb_id" { value = aws_security_group.alb.id }
output "sg_master_id" { value = aws_security_group.master.id }
output "sg_worker_id" { value = aws_security_group.worker.id }