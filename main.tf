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
  # assign_generated_ipv6_cidr_block = true

  tags = merge(
    var.resource_tags,
    {
      Name = "AwesomeVPC"
    }
  )
}

resource "aws_subnet" "subnets" {
  for_each          = local.subnets
  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value.cidr_block
  availability_zone = "${var.aws_region}${each.value.az_suffix}"
  # ipv6_cidr_block                 = cidrsubnet(aws_vpc.main.ipv6_cidr_block, 8, index(keys(local.subnets), each.key))
  # assign_ipv6_address_on_creation = true

  tags = var.resource_tags
}

resource "aws_route_table" "public-rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    # ipv6_cidr_block = "::/0"
    gateway_id = aws_internet_gateway.igw.id
  }

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
  tags   = var.resource_tags
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

resource "aws_security_group" "web_sg" {
  name   = "web-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
    # ipv6_cidr_blocks = ["::/0"] # Allow from anywhere (or restrict as needed)
  }

  # Optional: also allow SSH/HTTP if needed
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    # ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    # ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    # ipv6_cidr_blocks = ["::/0"]
  }

  tags = var.resource_tags
}

resource "aws_key_pair" "ssh_key" {
  key_name   = "ssh-key"
  public_key = var.ssh_public_key
}

resource "aws_instance" "web" {
  ami                    = data.aws_ami.linux.id
  instance_type          = var.ec2_instance_type
  subnet_id              = aws_subnet.subnets["my_public_subnet1"].id
  vpc_security_group_ids = [aws_security_group.web_sg.id]

  associate_public_ip_address = true
  # associate_public_ip_address = false # disable IPv4
  # ipv6_address_count          = 1     # Assign one IPv6 address

  key_name = aws_key_pair.ssh_key.key_name

  root_block_device {
    volume_size = 2
    volume_type = "gp2"
  }

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd
              echo "Hello, World from Amazon Linux!" > /var/www/html/index.html
              systemctl enable httpd
              systemctl start httpd
            EOF

  depends_on = [aws_internet_gateway.igw]

  tags = merge(
    var.resource_tags,
    {
      Name = random_pet.name.id
    }
  )
}
