terraform {
  required_version = ">= 0.10.0"
}
provider "aws" {
  region = var.aws_region
}
# Provides EC2 key pair allowing for SSH into the master node
resource "aws_key_pair" "terraformkey" {
  key_name   = "terraform_key"
  public_key = tls_private_key.kube_ssh.public_key_openssh
}
# Creates VPC network
resource "aws_vpc" "k8s_vpc" {
  cidr_block       = "10.0.0.0/16"
  enable_dns_hostnames=true
  enable_dns_support =true

}
# Create security group to allow incoming traffic and be able to SSH into the master node
resource "aws_security_group" "allow_ssh_http" {
  name        = "kubernetes_SG"
  description = "Allow SSH and HTTP inbound traffic"
  vpc_id      = aws_vpc.k8s_vpc.id
  ingress {
    description      = "Allow All"
    from_port        = 0
    to_port          = 0
    protocol         = -1
    cidr_blocks      = [ "0.0.0.0/0" ]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  tags = {
    Name = "K8S SG"
  }
}
# Create Subnet which is assigned to the VPC
resource "aws_subnet" "public_subnet" {
  vpc_id     = aws_vpc.k8s_vpc.id
  cidr_block = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone = var.aws_availability_zone

}# Creates the internet gateway and assigned to the VPC
resource "aws_internet_gateway" "k8s_gw" {
  vpc_id = aws_vpc.k8s_vpc.id

}# Creates routing for the VPC
resource "aws_route_table" "k8s_route" {
    vpc_id = aws_vpc.k8s_vpc.id
    
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.k8s_gw.id
    }
}
# Associate Routing table with the subnets
resource "aws_route_table_association" "k8s_asso" {
    subnet_id = aws_subnet.public_subnet.id
    route_table_id = aws_route_table.k8s_route.id
}

# Launch EC2 instance for Master Node alongside the machine image and instance type
resource "aws_instance" "kube_master" {
  ami                   = "ami-060c0d1361bbd1bd7"
  instance_type         = "t2.medium"
  key_name              = aws_key_pair.terraformkey.key_name
  associate_public_ip_address = true
  subnet_id             = aws_subnet.public_subnet.id
  vpc_security_group_ids      = [ aws_security_group.allow_ssh_http.id ] 
  root_block_device {
    volume_size = 64
    volume_type = "gp2"
    encrypted = true
  }
  tags = {
    Name = "MasterNode"
  }
}