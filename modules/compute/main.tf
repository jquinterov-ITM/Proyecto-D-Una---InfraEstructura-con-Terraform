locals {
  master_private_ips = [for cidr in var.app_subnet_cidrs : cidrhost(cidr, 10)]
  total_masters      = min(var.master_count, length(var.app_subnets))
}

resource "aws_iam_role" "ec2_ssm_role" {
  count = var.create_ec2_iam_resources ? 1 : 0

  name = "Duna-${var.env}-EC2-SSM-Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ec2_ssm_core" {
  count      = var.create_ec2_iam_resources ? 1 : 0
  role       = aws_iam_role.ec2_ssm_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2_ssm_profile" {
  count = var.create_ec2_iam_resources ? 1 : 0

  name = "Duna-${var.env}-EC2-SSM-Profile"
  role = aws_iam_role.ec2_ssm_role[0].name
}

locals {
  instance_profile_name = var.existing_instance_profile_name != "" ? var.existing_instance_profile_name : (
    var.create_ec2_iam_resources ? aws_iam_instance_profile.ec2_ssm_profile[0].name : null
  )
}

resource "aws_instance" "master_primary" {
  ami                         = "ami-0c7217cdde317cfec"
  instance_type               = var.master_type
  subnet_id                   = var.app_subnets[0]
  private_ip                  = local.master_private_ips[0]
  vpc_security_group_ids      = [var.sg_master_id]
  iam_instance_profile        = local.instance_profile_name
  associate_public_ip_address = false
  key_name                    = var.key_name
  user_data                   = <<-EOF
              #!/bin/bash
              curl -sfL https://get.k3s.io | 
              K3S_TOKEN=${var.k3s_token} sh -s server --cluster-init --write-kubeconfig-mode 644
              EOF
  tags                        = { Name = "Master-${var.env}-0" }
}

resource "aws_instance" "master_secondary" {
  count                       = max(local.total_masters - 1, 0)
  ami                         = "ami-0c7217cdde317cfec"
  instance_type               = var.master_type
  subnet_id                   = var.app_subnets[count.index + 1]
  private_ip                  = local.master_private_ips[count.index + 1]
  vpc_security_group_ids      = [var.sg_master_id]
  iam_instance_profile        = local.instance_profile_name
  associate_public_ip_address = false
  key_name                    = var.key_name
  user_data                   = <<-EOF
              #!/bin/bash
              sleep 60
              curl -sfL https://get.k3s.io | 
              K3S_URL=https://${aws_instance.master_primary.private_ip}:6443 \
              K3S_TOKEN=${var.k3s_token} sh -s server
              EOF
  tags                        = { Name = "Master-${var.env}-${count.index + 1}" }
}

locals {
  # Sufijos de nombre para workers: index 0 -> ppal, index 1 -> second
  worker_suffixes = [
    "ppal",
    "second",
  ]
}
resource "aws_instance" "worker" {
  count                  = var.worker_count
  ami                    = "ami-0c7217cdde317cfec"
  instance_type          = var.worker_type
  subnet_id              = var.app_subnets[count.index % length(var.app_subnets)]
  vpc_security_group_ids = [var.sg_worker_id]
  iam_instance_profile   = local.instance_profile_name
  key_name               = var.key_name
  user_data              = <<-EOF
              #!/bin/bash
              sleep 60
              # Set hostname based on mapping: worker-<n>-<suffix>
              hostnamectl set-hostname worker-${var.env}-$(( ${count.index} + 1 ))-${length(local.worker_suffixes) > count.index ? local.worker_suffixes[count.index] : "worker"}
              curl -sfL https://get.k3s.io | 
              K3S_URL=https://${aws_instance.master_primary.private_ip}:6443 \
              K3S_TOKEN=${var.k3s_token} sh -s - agent --kubelet-arg=max-pods=${var.worker_max_pods}
              EOF
  tags = {
    Name = "worker-${var.env}-${count.index + 1}-${length(local.worker_suffixes) > count.index ? local.worker_suffixes[count.index] : "worker"}"
  }
}

output "worker_ids" { value = aws_instance.worker[*].id }

output "master_primary_id" {
  description = "Instance ID del master primario"
  value       = aws_instance.master_primary.id
}

output "master_ids" {
  description = "Instance IDs de todos los masters"
  value       = concat([aws_instance.master_primary.id], aws_instance.master_secondary[*].id)
}

output "master_private_ips" {
  value = concat([aws_instance.master_primary.private_ip], aws_instance.master_secondary[*].private_ip)
}