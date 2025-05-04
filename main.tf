# Create a VPC
locals {
  subnets = {
    my_public_subnet1  = { cidr_block = "10.100.0.0/24", az_suffix = "a" }
    my_public_subnet2  = { cidr_block = "10.100.1.0/24", az_suffix = "b" }
    my_private_subnet1 = { cidr_block = "10.100.10.0/24", az_suffix = "a" }
    my_private_subnet2 = { cidr_block = "10.100.11.0/24", az_suffix = "b" }
  }
}

resource "aws_subnet" "subnets" {
  for_each          = local.subnets
  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value.cidr_block
  availability_zone = "${var.aws_region}${each.value.az_suffix}"

  tags = var.resource_tags
}

resource "aws_vpc" "main" {

  cidr_block = var.vpc_cidr_block

  tags = var.resource_tags
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "random_pet" "name" {}

resource "aws_instance" "web" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.ec2_instance_type
  subnet_id     = aws_subnet.subnets["my_public_subnet1"].id

  associate_public_ip_address = true

  tags = merge(
    var.resource_tags,
    {
      Name = random_pet.name.id
    }
  )
}
