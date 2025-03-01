provider "aws" {
  region = "eu-north-1"
}

resource "aws_security_group" "allow_http_ssh" {
  name        = "allow_http_ssh_terraform_1"
  description = "Security group that allows SSH and HTTP access"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "web" {
  ami           = "ami-02912a5f3748ebfac"
  instance_type = "t3.micro"
  key_name      = "keyforlab1"

  security_groups = [aws_security_group.allow_http_ssh.name]

  user_data = <<-EOF
    #!/bin/bash
    sudo apt update -y
    sudo apt install -y docker.io
    sudo systemctl start docker
    sudo systemctl enable docker
    sudo docker run -d -p 80:80 martastepaniuk/lab1:latest
  EOF

  tags = {
    Name = "Terraform-Managed-Instance"
  }
}