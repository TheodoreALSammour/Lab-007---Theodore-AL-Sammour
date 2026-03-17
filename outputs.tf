output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "external_alb_dns" {
  description = "DNS name of the external ALB — open this in your browser"
  value       = aws_lb.external.dns_name
}

output "internal_alb_dns" {
  description = "DNS name of the internal ALB (used by the web tier nginx config)"
  value       = aws_lb.internal.dns_name
}

output "bastion_public_ip" {
  description = "Public IP of the bastion host"
  value       = aws_instance.bastion.public_ip
}

output "ssm_parameter_paths" {
  description = "SSM Parameter Store paths created by this stack"
  value = [
    aws_ssm_parameter.db_password.name,
    aws_ssm_parameter.app_env.name,
  ]
}
