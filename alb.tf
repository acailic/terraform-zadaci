# =============================================================================
# ALB – Application Load Balancer (Layer 7) sa 2 EC2 instance za HA
#
# ALB radi na Layer 7 (HTTP/HTTPS) — razume HTTP protokol i moze da rutira
# po URL path-u, host header-u, itd.
# Razlike u odnosu na NLB:
#   - ALB IMA security group — kontrolise pristup na Layer 7
#   - ALB podrzava path-based i host-based routing
#   - ALB moze da terminira SSL/TLS
#   - ALB ima veci latency od NLB-a, ali je fleksibilniji
#   - Health check: HTTP GET na /index.html (200 OK)
#
# Arhitektura:
#   Internet -> ALB (public subnets, 2 AZ)
#            -> EC2-1 (private, us-east-1a)
#            -> EC2-2 (private_b, us-east-1b)
# =============================================================================

# ----- ALB Security Group -----------------------------------------------------
# Dozvoli HTTP sa interneta ka ALB-u. EC2 SG dozvoljava HTTP samo od ovog SG-a.

resource "aws_security_group" "alb" {
  count = local.create_alb ? 1 : 0

  vpc_id      = aws_vpc.test[0].id
  description = "Allow HTTP inbound to ALB from the internet"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP from internet"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS from internet"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${local.name_prefix}-alb-sg" }
}

# ----- ALB --------------------------------------------------------------------

resource "aws_lb" "alb" {
  count = local.create_alb ? 1 : 0

  name               = "${local.name_prefix}-alb"
  internal           = false # internet-facing
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb[0].id]
  subnets            = [aws_subnet.public[0].id, aws_subnet.public_b[0].id]

  tags = { Name = "${local.name_prefix}-alb" }
}

# ----- ALB Target Group (HTTP port 80) ----------------------------------------
# ALB koristi protocol = "HTTP" (ne TCP kao NLB).
# Health check je HTTP GET na /index.html — ocekuje 200 OK.
# Round-robin distribucija izmedju 2 EC2 instance.

resource "aws_lb_target_group" "alb_web" {
  count = local.create_alb ? 1 : 0

  name     = "${local.name_prefix}-alb-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.test[0].id

  health_check {
    path                = "/index.html"
    protocol            = "HTTP"
    port                = 80
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30 # ALB minimum je 30s (NLB podrzava 10s)
    matcher             = "200"
  }

  tags = { Name = "${local.name_prefix}-alb-tg" }
}

# ----- ALB Target Group Attachments (2 EC2 instance) --------------------------
# Registruje obe EC2 instance u ALB target group.
# ALB automatski distribuira HTTP zahteve izmedju zdravih targeta.
# Kad jedna instanca padne, ALB salje sav saobracaj na drugu.

resource "aws_lb_target_group_attachment" "alb_web" {
  count = local.create_alb ? local.ec2_instance_count : 0

  target_group_arn = aws_lb_target_group.alb_web[0].arn
  target_id        = aws_instance.test[count.index].id
  port             = 80
}

# ----- ALB HTTP Listener (port 80) --------------------------------------------
# Slusa na ALB-u na portu 80 i prosledjuje HTTP zahteve na Target Group.

resource "aws_lb_listener" "alb_http" {
  count = local.create_alb ? 1 : 0

  load_balancer_arn = aws_lb.alb[0].arn
  port              = 80
  protocol          = "HTTP"

  dynamic "default_action" {
    for_each = local.create_dns ? [] : [1]
    content {
      type             = "forward"
      target_group_arn = aws_lb_target_group.alb_web[0].arn
    }
  }

  dynamic "default_action" {
    for_each = local.create_dns ? [1] : []
    content {
      type = "redirect"
      redirect {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
  }
}

# ----- ALB HTTPS Listener (port 443) -----------------------------------------
# Slusa na ALB-u na portu 443 sa ACM certifikatom i prosledjuje na Target Group.
# Kreira se samo kad je DNS aktivan (jer ACM cert zavisi od Route 53).

resource "aws_lb_listener" "alb_https" {
  count = local.create_dns ? 1 : 0

  load_balancer_arn = aws_lb.alb[0].arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate_validation.main[0].certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_web[0].arn
  }
}
