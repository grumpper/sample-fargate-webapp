# Output the DNS of the ALB
output "alb_url" {
  value = nonsensitive(module.alb.dns_name)
}