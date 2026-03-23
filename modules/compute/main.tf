resource "aws_instance" "master" {
  ami = "ami-0c7217cdde317cfec"
  instance_type = var.master_type
  subnet_id = var.public_subnet
  vpc_security_group_ids = [var.sg_master_id]
  associate_public_ip_address = true
  key_name = var.key_name
  user_data = <<-EOF
              #!/bin/bash
              PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
              curl -sfL https://get.k3s.io | 
              K3S_TOKEN=${var.k3s_token} sh -s server \
              --tls-san=$PUBLIC_IP --write-kubeconfig-mode 644
              EOF
  tags = { Name = "Master-${var.env}" }
}

resource "aws_instance" "worker" {
  ami = "ami-0c7217cdde317cfec"
  instance_type = var.worker_type
  subnet_id = var.private_subnet
  vpc_security_group_ids = [var.sg_worker_id]
  key_name = var.key_name
  user_data = <<-EOF
              #!/bin/bash
              sleep 60
              curl -sfL https://get.k3s.io | 
              K3S_URL=https://${aws_instance.master.private_ip}:6443 \
              K3S_TOKEN=${var.k3s_token} sh -
              EOF
  tags = { Name = "Worker-${var.env}" }
}

output "worker_id" { value = aws_instance.worker.id }
output "master_ip" { value = aws_instance.master.public_ip }