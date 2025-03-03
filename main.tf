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
  name        = "sgroup"
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
    exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
    echo "Starting user data script execution at $(date)"

    echo "Updating packages..."
    apt-get update || { echo "Failed to update packages"; exit 1; }
    apt-get install -y apt-transport-https ca-certificates curl software-properties-common || { echo "Failed to install prerequisites"; exit 1; }

    echo "Installing Docker..."
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add - || { echo "Failed to add Docker GPG key"; exit 1; }
    add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" || { echo "Failed to add Docker repository"; exit 1; }
    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io || { echo "Failed to install Docker"; exit 1; }

    usermod -aG docker ubuntu
    systemctl start docker || { echo "Failed to start Docker"; exit 1; }
    systemctl enable docker || { echo "Failed to enable Docker"; exit 1; }

    echo "Checking Docker status..."
    docker --version || { echo "Docker installation failed"; exit 1; }

    echo "Waiting for Docker to be fully ready..."
    sleep 10

    echo "Running application container..."
    docker rm -f web-app 2>/dev/null || true
    docker run -d --name web-app --restart always -p 80:80 martastepaniuk/lab1:latest || { echo "Failed to run web app container"; exit 1; }

    echo "Running watchtower container..."
    docker rm -f watchtower 2>/dev/null || true
    docker run -d --name watchtower --restart always \
      -v /var/run/docker.sock:/var/run/docker.sock \
      containrrr/watchtower \
      --interval 30 \
      web-app || { echo "Failed to run watchtower container"; exit 1; }

    echo "Listing running containers..."
    docker ps

    echo "User data script completed at $(date)!"
  EOF

  user_data_replace_on_change = true

  tags = {
    Name = "web-server"
  }
}

output "instance_public_ip" {
  value = aws_instance.web_instance.public_ip
}