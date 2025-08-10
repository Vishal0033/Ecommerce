provider "aws" {
  region = "ap-south-1"
  access_key = "AKIA2QACS3LSA5YT6NM5"
  secret_key = "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"
}

# VPC
resource "aws_vpc" "monitoring_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "monitoring-vpc"
  }
}

# Subnet

resource "aws_subnet" "monitoring_subnet" {
  vpc_id     = aws_vpc.monitoring_vpc.id
  cidr_block = "10.0.1.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "monitoring-subnet"
  }
}

# Internet Gateway

resource "aws_internet_gateway" "monitoring_igw" {
  vpc_id = aws_vpc.monitoring_vpc.id

  tags = {
    Name = "monitoring-igw"
  }
}

# Route Table + Association

resource "aws_route_table" "monitoring_rt" {
  vpc_id = aws_vpc.monitoring_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.monitoring_igw.id
  }

  tags = {
    Name = "monitoring-rt"
  }
}

resource "aws_route_table_association" "monitoring_rta" {
  subnet_id      = aws_subnet.monitoring_subnet.id
  route_table_id = aws_route_table.monitoring_rt.id
}

# Security Group

resource "aws_security_group" "monitoring_sg" {
  name        = "monitoring-sg"
  description = "Allow SSH, HTTP, Jenkins"
  vpc_id      = aws_vpc.monitoring_vpc.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Jenkins"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPs"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "shop"
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "prometheus"
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "grafana"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "monitoring-sg"
  }
}

# Network Interface

resource "aws_network_interface" "monitoring_ni" {
    subnet_id       = aws_subnet.monitoring_subnet.id
    private_ips     = ["10.0.1.50"]
    security_groups = [aws_security_group.monitoring_sg.id]
}


# ECR

resource "aws_ecr_repository" "monitoring_repo" {
  name                 = "e-app"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "Monitoring-ECR-Repository"
  }
}

resource "aws_instance" "monitoring" {
  ami           = "ami-0f918f7e67a3323f0"
  instance_type = "t3.micro"
  subnet_id                   = aws_subnet.monitoring_subnet.id
  vpc_security_group_ids      = [aws_security_group.monitoring_sg.id]
  associate_public_ip_address = true
  key_name      = "e-shop"

  tags = {
    Name = "monitoring-instance"
  }

user_data = <<-EOF
    #!/bin/bash
    sudo yum update -y
    sudo amazon-linux-extras enable docker
    sudo yum install -y docker
    sudo service docker start
    sudo usermod -aG docker ec2-user
    docker run -d -p 5000:5000 ecommerce
    docker run -d -p 9090:9090 prom/prometheus
    docker run -d -p 3000:3000 grafana/grafana
  EOF
}
