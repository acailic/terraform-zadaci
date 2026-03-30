# =============================================================================
# DNS – Route 53 Public Hosted Zone + A Alias Record
#
# Kreira public hosted zone za custom domen i A alias record koji pokazuje
# na ALB. Alias record je AWS-specifican — radi za root (apex) domen,
# besplatan je za DNS upite, i interno rezolvira ALB DNS na IP adrese.
#
# Posle apply-a:
#   1. Procitaj output route53_nameservers (4 NS servera)
#   2. Kod domain registrara postavi ta 4 NS servera
#   3. Sacekaj DNS propagaciju (15min–48h)
#   4. Otvori http://<domain_name> u browseru
#
# Cena: $0.50/mesec za hosted zone + $0.40/milion upita
# =============================================================================

# ----- Public Hosted Zone -----------------------------------------------------

resource "aws_route53_zone" "main" {
  count = local.create_dns ? 1 : 0

  name = var.domain_name

  tags = { Name = "${local.name_prefix}-dns-zone" }
}

# ----- A Alias Record -> ALB --------------------------------------------------
# Alias record (ne CNAME) jer:
#   - CNAME ne moze na root/apex domenu (RFC ogranicenje)
#   - Alias je besplatan za Route 53 upite
#   - Route 53 automatski rezolvira ALB DNS na trenutne IP adrese

resource "aws_route53_record" "alb_alias" {
  count = local.create_dns ? 1 : 0

  zone_id = aws_route53_zone.main[0].zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_lb.alb[0].dns_name
    zone_id                = aws_lb.alb[0].zone_id
    evaluate_target_health = true
  }
}
