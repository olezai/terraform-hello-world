# Create a VPC
resource "aws_vpc" "main" {

  cidr_block = var.vpc_cidr_block

  tags = var.resource_tags
}

resource "aws_subnet" "my_public_subnet1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.100.0.0/24"
  availability_zone = "${var.aws_region}a"

  tags = var.resource_tags
}

resource "aws_subnet" "my_public_subnet2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.100.1.0/24"
  availability_zone = "${var.aws_region}b"

  tags = var.resource_tags
}

resource "aws_subnet" "my_private_subnet1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.100.10.0/24"
  availability_zone = "${var.aws_region}a"

  tags = var.resource_tags
}

resource "aws_subnet" "my_private_subnet2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.100.11.0/24"
  availability_zone = "${var.aws_region}b"

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
  subnet_id     = aws_subnet.my_public_subnet1.id

  tags = merge(
    var.resource_tags,
    {
      Name = random_pet.name.id
    }
  )
}
