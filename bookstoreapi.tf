terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "3.60.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_instance" "tf-docker-ec2" {
    ami = "ami-087c17d1fe0178315"
    instance_type = "t2.micro"
    key_name = "hakan2"
    security_groups = ["docker-sec-gr-203"]
    tags = {
      "Name" = "Web Server of Bookstore"
    }
    user_data = <<-EOF
               #! /bin/bash
               yum update -y
               amazon-linux-extras install docker -y
               systemctl start docker
               systemctl enable docker
               usermod -a -G docker ec2-user
               curl -L "https://github.com/docker/compose/releases/download/1.26.2/docker-compose-$(uname -s)-$(uname -m)" \
               -o /usr/local/bin/docker-compose
               chmod +x /usr/local/bin/docker-compose
               mkdir -p /home/ec2-user/bookstore-api
               TOKEN="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"
               FOLDER="https://$TOKEN@raw.githubusercontent.com/hakancar/bookstoreapi/master/"
               curl -s --create-dirs -o "/home/ec2-user/bookstore-api/app.py" -L "$FOLDER"bookstore-api.py
               curl -s --create-dirs -o "/home/ec2-user/bookstore-api/requirements.txt" -L "$FOLDER"requirements.txt
               curl -s --create-dirs -o "/home/ec2-user/bookstore-api/Dockerfile" -L "$FOLDER"Dockerfile
               curl -s --create-dirs -o "/home/ec2-user/bookstore-api/docker-compose.yml" -L "$FOLDER"docker-compose.yml
               cd /home/ec2-user/bookstore-api
               docker build -t hakancar/bookstoreapi:latest .
               docker-compose up -d
               EOF
}



resource "aws_security_group" "docker-sec-gr" {
    name = "docker-sec-gr-203"
    tags = {
      "Name" = "Bookstore web service sec gr"
    }

    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

        ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

        egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
  
}

output "webapi" {
    value = "http://${aws_instance.tf-docker-ec2.public_dns}"
  
}