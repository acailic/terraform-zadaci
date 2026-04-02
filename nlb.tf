# =============================================================================
# NLB – Network Load Balancer (zakomentarisan — koristimo ALB umesto NLB-a)
#
# NLB radi na Layer 4 (TCP/UDP) — prosleđuje TCP konekcije bez inspekcije.
# Razlike u odnosu na ALB:
#   - NLB NEMA security group — client IP se propušta direktno do EC2
#   - NLB podržava statičke IP adrese (Elastic IP po AZ-u)
#   - NLB ima mnogo manji latency (milioni req/s)
#   - NLB ne može da rutira po URL path-u (to radi ALB na Layer 7)
#   - Health check: TCP konekcija na port 22 (ne HTTP GET)
# =============================================================================

# resource "aws_lb" "nlb" {
#   count = local.create_nlb ? 1 : 0
#
#   name               = "${local.name_prefix}-nlb"
#   internal           = false # internet-facing
#   load_balancer_type = "network"
#   # NLB nema security_groups parametar!
#   subnets = [aws_subnet.public[0].id, aws_subnet.public_b[0].id]
#
#   tags = { Name = "${local.name_prefix}-nlb" }
# }

# ----- NLB Target Group (TCP port 22) ----------------------------------------
# Target Group za NLB koristi protocol = "TCP" (ne HTTP).
# Health check je TCP — samo proverava da li može da otvori konekciju na port 22.

# resource "aws_lb_target_group" "ssh" {
#   count = local.create_nlb ? 1 : 0
#
#   name     = "${local.name_prefix}-ssh-tg"
#   port     = 22
#   protocol = "TCP"
#   vpc_id   = aws_vpc.test[0].id
#
#   health_check {
#     protocol            = "TCP"
#     port                = 22
#     healthy_threshold   = 2
#     unhealthy_threshold = 2
#     interval            = 10
#   }
#
#   tags = { Name = "${local.name_prefix}-ssh-tg" }
# }

# ----- NLB Target Group Attachment --------------------------------------------

# resource "aws_lb_target_group_attachment" "ssh" {
#   count = local.create_nlb ? local.ec2_instance_count : 0
#
#   target_group_arn = aws_lb_target_group.ssh[0].arn
#   target_id        = aws_instance.test[count.index].id
#   port             = 22
# }

# ----- NLB TCP Listener (port 22) --------------------------------------------
# Sluša na NLB-u na portu 22 i prosleđuje TCP konekcije na Target Group.

# resource "aws_lb_listener" "ssh" {
#   count = local.create_nlb ? 1 : 0
#
#   load_balancer_arn = aws_lb.nlb[0].arn
#   port              = 22
#   protocol          = "TCP"
#
#   default_action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.ssh[0].arn
#   }
# }

# ----- NLB Target Group (TCP port 80) — web app --------------------------------
# TCP target group za HTTP web app — zakomentarisan jer ALB preuzima HTTP.

# resource "aws_lb_target_group" "web" {
#   count = local.create_nlb && !local.create_alb ? 1 : 0
#
#   name     = "${local.name_prefix}-web-tg"
#   port     = 80
#   protocol = "TCP"
#   vpc_id   = aws_vpc.test[0].id
#
#   health_check {
#     protocol            = "HTTP"
#     port                = 80
#     path                = "/index.html"
#     healthy_threshold   = 2
#     unhealthy_threshold = 2
#     interval            = 10
#   }
#
#   tags = { Name = "${local.name_prefix}-web-tg" }
# }

# resource "aws_lb_target_group_attachment" "web" {
#   count = local.create_nlb && !local.create_alb ? local.ec2_instance_count : 0
#
#   target_group_arn = aws_lb_target_group.web[0].arn
#   target_id        = aws_instance.test[count.index].id
#   port             = 80
# }

# ----- NLB TCP Listener (port 80) — web app ----------------------------------

# resource "aws_lb_listener" "http" {
#   count = local.create_nlb && !local.create_alb ? 1 : 0
#
#   load_balancer_arn = aws_lb.nlb[0].arn
#   port              = 80
#   protocol          = "TCP"
#
#   default_action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.web[0].arn
#   }
# }
