terraform {
  backend "s3" {
    bucket = "awsbucketforlab2group3"
    key    = "terraform/state"
    region = "eu-north-1"
  }
}

provider "aws" {
  region = "eu-north-1"
}

resource "aws_security_group" "security_group" {
  name        = "security-group"
  description = "Security group for web application"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
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
    Name = "web-server-sg"
  }
}

data "aws_key_pair" "existing" {
  key_name = "keyforlab1"
}

resource "aws_instance" "web_instance" {
  ami                    = "ami-0989fb15ce71ba39e"
  instance_type          = "t3.micro"
  key_name               = data.aws_key_pair.existing.key_name
  vpc_security_group_ids = [aws_security_group.security_group.id]

  user_data = <<-EOF
    #!/bin/bash
    apt-get update
    apt-get install -y curl
    curl -fsSL https://get.docker.com | sh
    usermod -aG docker ubuntu
    systemctl start docker
    systemctl enable docker
    docker run -d --name web-app --restart always -p 80:80 martastepaniuk/lab1:latest
    docker run -d --name watchtower --restart always \
      -v /var/run/docker.sock:/var/run/docker.sock \
      containrrr/watchtower \
      --interval 30 \
      web-app
  EOF

  user_data_replace_on_change = true

  tags = {
    Name = "web-server"
  }
}

output "instance_public_ip" {
  value = aws_instance.web_instance.public_ip
}