provider "aws" {
  region = "ap-south-1"
}

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true # Good practice for identifying instances
}

resource "aws_subnet" "subnet" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-south-1a"
  # FIX: This ensures your instance gets a Public IP address
  map_public_ip_on_launch = true 
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
}

# FIX: You need a Route Table to tell the VPC to send traffic to the Internet Gateway
resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.subnet.id
  route_table_id = aws_route_table.rt.id
}

resource "aws_security_group" "sg" {
  name   = "jenkins-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Open to all; consider using your specific IP
  }

  ingress {
    from_port   = 8080 # Jenkins default port is usually 8080, not 3000
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Add egress rule so the server can download Jenkins/updates
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "jenkins" {
  ami           = "ami-0f5ee92e2d63afc18" 
  key_name      = "KESTER"
  instance_type = "t3.micro"
  
  # FIX: Use vpc_security_group_ids for instances inside a VPC
  subnet_id              = aws_subnet.subnet.id
  vpc_security_group_ids = [aws_security_group.sg.id]

  tags = {
    Name = "jenkins-server"
  }
}