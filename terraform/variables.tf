variable "cidr" {
  default = "10.0.0.0/16"
}

variable "key_name" {
  description = "Name of the AWS key pair"
  default     = "infracloud"
}

variable "db_name" {
  default = "drupal_db"
}

variable "db_user" {
  default = "drupal_user"
}

variable "db_password" {
  default = "drupaldb123!"
}

variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}


variable "instance_type" {
  description = "Server Type"
  type        = string
  default     = "t3.micro"
}


variable "ami_id" {
  description = "AMI ID for the EC2 instances"
  type        = string
  default     = "ami-084568db4383264d4"
}