provider "aws" {
  region = "eu-north-1"
}

data "aws_security_group" "allow_http_ssh" {
  filter {
    name   = "group-name"
    values = ["allow_http_ssh"]
  }
}

resource "aws_instance" "web" {
  ami           = "ami-02912a5f3748ebfac"
  instance_type = "t3.micro"
  key_name      = "keyforlab1"

  vpc_security_group_ids = [data.aws_security_group.allow_http_ssh.id]

  tags = {
    Name = "Terraform-Managed-Instance"
  }
}