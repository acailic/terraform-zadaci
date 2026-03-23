# =============================================================================
# NLB – Network Load Balancer (option b)
#
# NLB radi na Layer 4 (TCP/UDP) — prosleđuje TCP konekcije bez inspekcije.
# Razlike u odnosu na ALB:
#   - NLB NEMA security group — client IP se propušta direktno do EC2
#   - NLB podržava statičke IP adrese (Elastic IP po AZ-u)
#   - NLB ima mnogo manji latency (milioni req/s)
#   - NLB ne može da rutira po URL path-u (to radi ALB na Layer 7)
#   - Health check: TCP konekcija na port 22 (ne HTTP GET)
# =============================================================================

resource "aws_lb" "nlb" {
  name               = "${local.name_prefix}-nlb"
  internal           = false # internet-facing
  load_balancer_type = "network"
  # NLB nema security_groups parametar!
  subnets = [aws_subnet.public.id, aws_subnet.public_b.id]

  tags = { Name = "${local.name_prefix}-nlb" }
}

# ----- NLB Target Group (TCP port 22) ----------------------------------------
# Target Group za NLB koristi protocol = "TCP" (ne HTTP).
# Health check je TCP — samo proverava da li može da otvori konekciju na port 22.

resource "aws_lb_target_group" "ssh" {
  name     = "${local.name_prefix}-ssh-tg"
  port     = 22
  protocol = "TCP"
  vpc_id   = aws_vpc.test.id

  health_check {
    protocol            = "TCP"       # TCP check — samo proveri da li je port otvoren
    port                = 22
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 10          # NLB podržava 10s interval (ALB min 30s)
  }

  tags = { Name = "${local.name_prefix}-ssh-tg" }
}

# ----- NLB Target Group Attachment --------------------------------------------

resource "aws_lb_target_group_attachment" "ssh" {
  target_group_arn = aws_lb_target_group.ssh.arn
  target_id        = aws_instance.test.id
  port             = 22
}

# ----- NLB TCP Listener (port 22) --------------------------------------------
# Sluša na NLB-u na portu 22 i prosleđuje TCP konekcije na Target Group.

resource "aws_lb_listener" "ssh" {
  load_balancer_arn = aws_lb.nlb.arn
  port              = 22
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ssh.arn
  }
}

# ----- NLB Target Group (TCP port 80) — web app --------------------------------
# TCP target group za HTTP web app. NLB prosledjuje TCP konekciju na port 80.

resource "aws_lb_target_group" "web" {
  name     = "${local.name_prefix}-web-tg"
  port     = 80
  protocol = "TCP"
  vpc_id   = aws_vpc.test.id

  health_check {
    protocol            = "HTTP"
    port                = 80
    path                = "/index.html"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 10
  }

  tags = { Name = "${local.name_prefix}-web-tg" }
}

resource "aws_lb_target_group_attachment" "web" {
  target_group_arn = aws_lb_target_group.web.arn
  target_id        = aws_instance.test.id
  port             = 80
}

# ----- NLB TCP Listener (port 80) — web app ----------------------------------
# Sluša na NLB-u na portu 80 i prosleđuje TCP konekcije na Web Target Group.

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.nlb.arn
  port              = 80
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}

# =============================================================================
# ALB – zakomentarisan (option b: NLB umesto ALB-a)
# =============================================================================

# ----- ALB Security Group (zakomentarisan — NLB nema SG) ---------------------
# resource "aws_security_group" "alb" {
#   vpc_id      = aws_vpc.test.id
#   description = "Allow HTTP inbound to ALB from the internet"
#
#   ingress {
#     from_port   = 80
#     to_port     = 80
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#     description = "HTTP from internet"
#   }
#
#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
#
#   tags = { Name = "${local.name_prefix}-alb-sg" }
# }

# ----- ALB (zakomentarisan) ---------------------------------------------------
# resource "aws_lb" "main" {
#   name               = "${local.name_prefix}-alb"
#   internal           = false
#   load_balancer_type = "application"
#   security_groups    = [aws_security_group.alb.id]
#   subnets            = [aws_subnet.public.id, aws_subnet.public_b.id]
#
#   tags = { Name = "${local.name_prefix}-alb" }
# }

# ----- ALB Target Group (zakomentarisan) --------------------------------------
# resource "aws_lb_target_group" "web" {
#   name     = "${local.name_prefix}-tg"
#   port     = 80
#   protocol = "HTTP"
#   vpc_id   = aws_vpc.test.id
#
#   health_check {
#     path                = "/index.html"
#     protocol            = "HTTP"
#     healthy_threshold   = 2
#     unhealthy_threshold = 3
#     timeout             = 5
#     interval            = 30
#     matcher             = "200"
#   }
#
#   tags = { Name = "${local.name_prefix}-tg" }
# }

# ----- ALB Target Group Attachment (zakomentarisan) ---------------------------
# resource "aws_lb_target_group_attachment" "web" {
#   target_group_arn = aws_lb_target_group.web.arn
#   target_id        = aws_instance.test.id
#   port             = 80
# }

# ----- ALB HTTP Listener (zakomentarisan) -------------------------------------
# resource "aws_lb_listener" "http" {
#   load_balancer_arn = aws_lb.main.arn
#   port              = 80
#   protocol          = "HTTP"
#
#   default_action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.web.arn
#   }
# }
