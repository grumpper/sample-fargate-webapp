# Output the DNS of the ALB
output "alb_url" {
  value = module.alb.dns_name
}