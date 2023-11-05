terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.24.0"
    }
  }
}

provider "aws" {
  profile = "default"
}

resource "aws_vpc" "custom_vpc_network" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = var.datacentre
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.custom_vpc_network.id

  tags = {
    Name = "${var.datacentre}-internet-gw"
  }
}

resource "aws_subnet" "public_vpc_subnetwork" {
  vpc_id                  = aws_vpc.custom_vpc_network.id
  cidr_block              = "10.0.0.0/24"
  map_public_ip_on_launch = true

  depends_on = [ aws_internet_gateway.gw ]
  tags = {
    Name = "${var.datacentre}-public-vpc"
  }
}

resource "aws_subnet" "private_vpc_subnetwork" {
  vpc_id     = aws_vpc.custom_vpc_network.id
  cidr_block = "10.0.1.0/24"
  tags = {
    Name = "${var.datacentre}-private-vpc"
  }
}

resource "aws_eip" "nat" {
  domain   = "vpc"

  tags = {
    Name = "${var.datacentre}-nat"
  }
}

resource "aws_nat_gateway" "gw" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_vpc_subnetwork.id

  depends_on = [aws_internet_gateway.gw]
  tags = {
    Name = "${var.datacentre}-nat-gw"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.custom_vpc_network.id

  route {
    cidr_block = aws_vpc.custom_vpc_network.cidr_block
    gateway_id = "local"
  }

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.custom_vpc_network.id

  route {
    cidr_block = aws_vpc.custom_vpc_network.cidr_block
    gateway_id = "local"
  }

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.gw.id
  }
}

# resource "aws_network_acl" "public" {
#   vpc_id = aws_vpc.custom_vpc_network.id
#   subnet_ids = [ aws_subnet.public_vpc_subnetwork.id ]

#   ingress {
#     protocol   = "tcp"
#     rule_no    = 100
#     action     = "allow"
#     cidr_block = "0.0.0.0/0"
#     from_port  = 22
#     to_port    = 22
#   }

#   egress {
#     protocol   = "-1"
#     rule_no    = 100
#     action     = "allow"
#     cidr_block = "0.0.0.0/0"
#     from_port  = 0
#     to_port    = 0
#     icmp_type = -1
#     icmp_code = -1
#   }

#   ingress {
#     protocol   = "icmp"
#     rule_no    = 101
#     action     = "allow"
#     cidr_block = "0.0.0.0/0"
#     from_port  = 0
#     to_port    = 0
#     icmp_type = -1
#     icmp_code = -1
#   }
# }

data "aws_ami" "amazon" {
  most_recent = true
  filter {
    name   = "name"
    values = ["*ami-2023*"]
  }
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
  owners = ["amazon"] # Canonical
}

resource "aws_security_group" "bastion" {
  description = "Allow SSH Ingress"
  vpc_id      = aws_vpc.custom_vpc_network.id

  ingress {
    description      = "Allow SSH ingress"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "Allow ICMP"
    from_port        = -1
    to_port          = -1
    protocol         = "icmp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    description      = "Allow All traffic to go out"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = [ "0.0.0.0/0" ]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public_vpc_subnetwork.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private_vpc_subnetwork.id
  route_table_id = aws_route_table.private.id
}

resource "aws_instance" "bastion" {
  ami           = data.aws_ami.amazon.id
  instance_type = var.instance_type
  subnet_id     = aws_subnet.public_vpc_subnetwork.id
  key_name      = var.ssh_key_pair_name

  vpc_security_group_ids = [ aws_security_group.bastion.id ]

  tags = {
    Name = "bastion"
  }
}

resource "aws_security_group" "internal" {
  description = "For internal traffic within vpc"
  vpc_id      = aws_vpc.custom_vpc_network.id

  ingress {
    description      = "Allow Internal Traffic"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = [ "0.0.0.0/0" ]
  }

  egress {
    description      = "Allow Internal Traffic"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = [ "0.0.0.0/0" ]
  }
}


data "aws_ami" "debian" {
  most_recent = true
  filter {
    name   = "name"
    values = ["*debian-12-amd64*"]
  }
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

resource "aws_instance" "etcd" {
  count = contains(var.components, "etcd") ? 3 : 0

  ami           = data.aws_ami.debian.id
  instance_type = var.instance_type
  subnet_id     = aws_subnet.private_vpc_subnetwork.id
  key_name      = var.ssh_key_pair_name

  vpc_security_group_ids = [ aws_security_group.internal.id ]

  tags = {
    Name = "etcd-${count.index}"
  }
}