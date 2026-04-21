resource "aws_lb" "main" {
  name               = "ALB-${var.env}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_sg_id]
  subnets            = var.public_subnets
  tags               = { Name = "ALB-${var.env}" }
}

resource "aws_lb_target_group" "tg" {
  name     = "TG-${var.env}"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  health_check {
    path     = "/"
    interval = 30
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}

resource "aws_lb_target_group_attachment" "worker_attach" {
  count            = length(var.worker_instance_ids)
  target_group_arn = aws_lb_target_group.tg.arn
  target_id        = var.worker_instance_ids[count.index]
}

output "alb_dns" { value = aws_lb.main.dns_name }