# Create a VPC
locals {
  subnets = {
    my_public_subnet1  = { cidr_block = "10.100.0.0/24", az_suffix = "a" }
    my_public_subnet2  = { cidr_block = "10.100.1.0/24", az_suffix = "b" }
    my_private_subnet1 = { cidr_block = "10.100.10.0/24", az_suffix = "a" }
    my_private_subnet2 = { cidr_block = "10.100.11.0/24", az_suffix = "b" }
  }
}

resource "aws_vpc" "main" {

  cidr_block = var.vpc_cidr_block

  tags = var.resource_tags
}

resource "aws_subnet" "subnets" {
  for_each          = local.subnets
  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value.cidr_block
  availability_zone = "${var.aws_region}${each.value.az_suffix}"

  tags = var.resource_tags
}

resource "aws_route_table" "public-rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  # route {
  #   ipv6_cidr_block        = "::/0"
  #   egress_only_gateway_id = aws_egress_only_internet_gateway.igw.id
  # }

  tags = var.resource_tags
}

resource "aws_route_table_association" "rta1" {
  subnet_id      = aws_subnet.subnets["my_public_subnet1"].id
  route_table_id = aws_route_table.public-rt.id
}

resource "aws_route_table_association" "rta2" {
  subnet_id      = aws_subnet.subnets["my_public_subnet2"].id
  route_table_id = aws_route_table.public-rt.id
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = var.resource_tags
}

data "aws_ami" "linux" {
  most_recent = true

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["137112412989"] # Amazon
}

resource "random_pet" "name" {}

resource "aws_security_group" "allow_http" {
  name        = "allow-http"
  description = "Allow HTTP inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.main.id

  tags = var.resource_tags
}

resource "aws_vpc_security_group_ingress_rule" "allow_http_ipv4" {
  security_group_id = aws_security_group.allow_http.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

# My VPC doesn't have IPv6
# resource "aws_vpc_security_group_ingress_rule" "allow_http_ipv6" {
#   security_group_id = aws_security_group.allow_http.id
#   cidr_ipv6         = aws_vpc.main.ipv6_cidr_block
#   from_port         = 80
#   ip_protocol       = "tcp"
#   to_port           = 80
# }

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.allow_http.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

# resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv6" {
#   security_group_id = aws_security_group.allow_http.id
#   cidr_ipv6         = "::/0"
#   ip_protocol       = "-1" # semantically equivalent to all ports
# }

resource "aws_security_group" "allow_ssh" {
  name        = "allow-ssh"
  description = "Allow SSH inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.main.id

  tags = var.resource_tags
}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh_ipv4" {
  security_group_id = aws_security_group.allow_ssh.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

# My VPC doesn't have IPv6
# resource "aws_vpc_security_group_ingress_rule" "allow_ssh_ipv6" {
#   security_group_id = aws_security_group.allow_ssh.id
#   cidr_ipv6         = aws_vpc.main.ipv6_cidr_block
#   from_port         = 22
#   ip_protocol       = "tcp"
#   to_port           = 22
# }

resource "aws_security_group" "allow_icmp" {
  name        = "allow-icmp"
  description = "Allow SSH inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.main.id

  tags = var.resource_tags
}

resource "aws_vpc_security_group_ingress_rule" "allow_icmp_ipv4" {
  security_group_id = aws_security_group.allow_icmp.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = -1
  ip_protocol       = "icmp"
  to_port           = -1
}

resource "aws_instance" "web" {
  ami           = data.aws_ami.linux.id
  instance_type = var.ec2_instance_type
  subnet_id     = aws_subnet.subnets["my_public_subnet1"].id
  vpc_security_group_ids = [
    aws_security_group.allow_http.id,
    aws_security_group.allow_ssh.id,
    aws_security_group.allow_icmp.id,
  ]

  associate_public_ip_address = true

  root_block_device {
    volume_size = 2
    volume_type = "gp2"
  }

  depends_on = [aws_internet_gateway.igw]

  tags = merge(
    var.resource_tags,
    {
      Name = random_pet.name.id
    }
  )
}
