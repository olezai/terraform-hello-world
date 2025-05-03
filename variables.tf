variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr_block" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.100.0.0/16"
}

variable "ec2_instance_type" {
  description = "instance type for ec2"
  type        = string
  default     = "t3.micro"
}