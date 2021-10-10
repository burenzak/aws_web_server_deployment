terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "eu-central-1"
  shared_credentials_file = "C:/Users/Buren/.awscreds"
  profile                 = "default"
}

resource "aws_vpc" "vpc_1" {
    cidr_block = "10.1.0.0/24"

    tags = {
      "Name" = "terra_vpc_1"
    }
}

resource "aws_internet_gateway" "gateway_1" {
  vpc_id = aws_vpc.vpc_1.id

  tags = {
    "Name" = "terra_gateway_1"
  }
}

resource "aws_route_table" "route_table_1" {
  vpc_id = aws_vpc.vpc_1.id

  route = [ {
    carrier_gateway_id = null
    cidr_block = "0.0.0.0/0"
    destination_prefix_list_id = null
    egress_only_gateway_id = "aws_internet_gateway.gateway_1.id"
    gateway_id = "aws_internet_gateway.gateway_1.id"
    instance_id = null
    ipv6_cidr_block = "::/0"
    local_gateway_id = null
    nat_gateway_id = null
    network_interface_id = aws_network_interface.network_interface_1.id
    transit_gateway_id = null
    vpc_endpoint_id = null
    vpc_peering_connection_id = null
  } ]

  tags = {
    "Name" = "terra_route_table_1"
  }
}

resource "aws_subnet" "subnet_1" {
  vpc_id     = aws_vpc.vpc_1.id
  cidr_block = "10.1.1.0/24"
  availability_zone = "eu-central-1c"

  tags = {
    "Name" = "terra_subnet_1"
  }
}

resource "aws_route_table_association" "route_table_association_1" {
  subnet_id      = aws_subnet.subnet_1.id
  route_table_id = aws_route_table.route_table_1.id
}

resource "aws_security_group" "sg_1" {
  name = "allow web traffic"
  description = "allow web inbound traffic: 80,8000,443,22"
  vpc_id = aws_vpc.vpc_1.id

  ingress = [ {
    cidr_blocks = ["0.0.0.0/24"]
    description = "https"
    from_port = 443
    ipv6_cidr_blocks = [ "::/0" ]
    prefix_list_ids = []
    protocol = "tcp"
    security_groups = []
    self = false
    to_port = 443
  },
  {
    cidr_blocks = ["0.0.0.0/24"]
    description = "ssh"
    from_port = 22
    ipv6_cidr_blocks = [ "::/0" ]
    prefix_list_ids = []
    protocol = "tcp"
    security_groups = []
    self = false
    to_port = 22
  },
  {
    cidr_blocks = ["0.0.0.0/24"]
    description = "http secondary"
    from_port = 8000
    ipv6_cidr_blocks = [ "::/0" ]
    prefix_list_ids = []
    protocol = "tcp"
    security_groups = []
    self = false
    to_port = 8000
  },
  {
    cidr_blocks = ["0.0.0.0/24"]
    description = "http primary"
    from_port = 80
    ipv6_cidr_blocks = [ "::/0" ]
    prefix_list_ids = []
    protocol = "tcp"
    security_groups = []
    self = false
    to_port = 80
  } ]
  egress = [ {
    cidr_blocks = [ "0.0.0.0/24" ]
    description = "outbound any"
    from_port = 0
    ipv6_cidr_blocks = [ "::/0" ]
    prefix_list_ids = []
    protocol = "-1"
    security_groups = []
    self = false
    to_port = 0
  } ]
  tags = {
    "Name" = "terra_sg_1"
  }
}

resource "aws_network_interface" "network_interface_1" {
  subnet_id = aws_subnet.subnet_1.id
  private_ips = ["10.1.1.15"]
  security_groups = [aws_security_group.sg_1.id]
}

resource "aws_eip" "elastic_1" {
  vpc = true
  network_interface = aws_network_interface.network_interface_1.id
  associate_with_private_ip = "10.1.1.15"

  depends_on = [
    aws_internet_gateway.gateway_1
  ]
}

resource "aws_instance" "terra_node_main" {
  ami = "ami-058e6df85cfc7760b"
  availability_zone = "eu-central-1c"
  instance_type = "t2.micro"
  key_name = "key.pem"

  network_interface {
    device_index = 0
    network_interface_id = aws_network_interface.network_interface_1.id
    delete_on_termination = true
  }
}