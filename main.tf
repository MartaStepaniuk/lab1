provider "aws" {
  region = "eu-north-1"
}

terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
}

resource "aws_instance" "my_instance" {
  ami           = "ami-09a9858973b288bdd"
  instance_type = "t2.nano"
  key_name      = "keyforlab1"

  vpc_security_group_ids = ["sg-0f80e74fb54f67309"]

  user_data = <<-EOF
    #! /bin/bash
    sudo apt-get update
    sudo apt-get install -y apache2
    sudo systemctl start apache2
    sudo systemctl enable apache2
    echo "<h1>Deployed via Terraform</h1>" | sudo tee /var/www/html/index.html
  EOF

  tags = {
    Name = "my-instance"
  }
}

output "instance_ip" {
  value = aws_instance.my_instance.public_ip
}
