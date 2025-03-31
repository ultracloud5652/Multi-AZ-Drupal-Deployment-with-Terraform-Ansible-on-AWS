### outputs.tf ###
output "ec2_public_ips" {
  description = "Public IPs of the EC2 instances"
  value       = aws_instance.drupal[*].public_ip
}

output "ec2_ids" {
  description = "Instance IDs of the EC2 instances"
  value       = aws_instance.drupal[*].id
}

output "instance_public_ips" {
  value = aws_instance.drupal[*].public_ip
}
