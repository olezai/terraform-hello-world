output "ec2__instance_private_ip_addr" {
  value = aws_instance.web.private_ip
}

output "ec2_instance_public_ip_addr" {
  value = aws_instance.web.public_ip
}

output "ec2_instance_id" {
  value = aws_instance.web.id
}

output "instance_ipv6" {
  value = aws_instance.web.ipv6_addresses
}

output "vpc_id" {
  value = aws_vpc.main.id
}
