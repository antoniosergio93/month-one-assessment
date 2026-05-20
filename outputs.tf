output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.techcorp_vpc.id
}

output "load_balancer_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.app_alb.dns_name
}

output "bastion_public_ip" {
  description = "Public IP address of the Bastion Host"
  value       = aws_eip.bastion_eip.public_ip
}