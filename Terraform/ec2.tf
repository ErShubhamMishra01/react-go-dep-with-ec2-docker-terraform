# ssh key creation cmd - ssh-keygen -f terraform_go_ec2_key  -m 'PEM'

#aws provider setup
provider "aws" {
  region     = "ap-south-1"
  access_key = "*************"
  secret_key = "*************************"
}


# VPC creation
resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc-cidr
  instance_tenancy     = "default"
  enable_dns_hostnames = true
  tags = {
    Name = "go_test_VPC"
  }
}
# Internet Gateway and Attach it to VPC
resource "aws_internet_gateway" "internet-gateway" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "go_internet_gateway"
  }
}
# Public Subnet 1
resource "aws_subnet" "public-subnet-1" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.Public_Subnet_1
  availability_zone       = "ap-south-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "go_public-subnet-1"
  }
}
# Route Table and Add Public Route
resource "aws_route_table" "public-route-table" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet-gateway.id
  }
  tags = {
    Name = "go_public_route_table"
  }
}

# Associate Public Subnet 1 to "Public Route Table"
resource "aws_route_table_association" "public-subnet-1-route-table-association" {
  subnet_id      = aws_subnet.public-subnet-1.id
  route_table_id = aws_route_table.public-route-table.id
}

# SG setup
resource "aws_security_group" "go_test_sg" {
  name        = "go_test"
  description = "SG for go instance"
  vpc_id      = aws_vpc.vpc.id
  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    protocol    = "tcp"
    from_port   = 8080
    to_port     = 8080
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#EC2 setup
resource "aws_instance" "go_test_dep_instance" {
  ami                    = "ami-03a933af70fa97ad2"
  instance_type          = var.instance_type
  security_groups        = [aws_security_group.go_test_sg.id]
  subnet_id              = aws_subnet.public-subnet-1.id
  key_name               = "terraform_go_ec2_key"
  vpc_security_group_ids = [aws_security_group.go_test_sg.id]
  depends_on             = [aws_security_group.go_test_sg]

  tags = {
    Name               = "go_test_dep_instance"
    aws_security_group = aws_security_group.go_test_sg.id
  }

# local to ec2 file transfer config
  provisioner "file" {
    source      = "./TechVerito-docker-compose-env.zip"
    destination = "/home/ubuntu/TechVerito-docker-compose-env.zip"
    # connection {
    #   type        = "ssh"
    #   host        = self.public_ip
    #   port        = 22
    #   user        = "ubuntu"
    #   private_key = file("terraform_go_ec2_key.pem")
    # }
  }

# cmd to ececute on ec2 for docker, docker-compose setup and starting the containers
  provisioner "remote-exec" {
    inline = [
      "sudo apt update -y",
      "sudo apt install zip unzip apt-transport-https ca-certificates curl software-properties-common -y",
      "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -",
      "sudo add-apt-repository 'deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable'",
      "sudo apt install docker-ce -y",
      "sudo apt  install docker-compose -y",
      "sudo chown -R $USER:$USER /var/run/docker.sock",
      "sudo systemctl restart docker.service",
      "unzip TechVerito-docker-compose-env.zip",
      "pwd",
      "ls TechVerito-docker-compose-env",
      "cd TechVerito-docker-compose-env",
      "docker-compose up -d"
    ]
  }

# connection for provisioner file and remote-exec
  connection {
    type        = "ssh"
    host        = self.public_ip
    port        = 22
    user        = "ubuntu"
    private_key = file("terraform_go_ec2_key.pem")
  }

}

# key pair setup for ssh connection
resource "aws_key_pair" "terraform_go_ec2_key" {
  key_name   = "terraform_go_ec2_key"
  public_key = file("terraform_go_ec2_key.pub")
}

#outout variables for public IP and SSH cmd for ec2
output "ec2PubIP" {
  value      = aws_instance.go_test_dep_instance.public_ip
  depends_on = [aws_instance.go_test_dep_instance]
}

output "ssh_cmd" {
  value = "ssh -i 'terraform_go_ec2_key.pem' ubuntu@${aws_instance.go_test_dep_instance.public_dns}"
  
}