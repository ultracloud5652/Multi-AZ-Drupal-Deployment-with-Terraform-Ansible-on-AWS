### outputs.tf ###

output "rds_security_group_id" {
  description = "The security group ID attached to the RDS instance"
  value       = aws_security_group.rds_sg.id
}

