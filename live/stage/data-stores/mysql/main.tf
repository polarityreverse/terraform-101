provider "aws" {
  region = "us-east-1"
}


data "aws_vpc" "default" {
  default = true
}


resource "aws_security_group" "mysql_access" {
  name        = "allow-mysql-access"
  description = "Allow MySQL access from my IP"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "MySQL access from my IP"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["103.7.206.157/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_db_instance" "example" {
  identifier_prefix   = "terraform-up-and-running"
  engine              = "mysql"
  engine_version      = "8.0"
  allocated_storage   = 10
  instance_class      = "db.t3.micro"     # Free Tier eligible
  username            = "admin"
  password            = var.db_password
  skip_final_snapshot = true
  publicly_accessible = true

  vpc_security_group_ids = [
    aws_security_group.mysql_access.id
  ]
}

resource "null_resource" "create_database" {
  depends_on = [aws_db_instance.example]

  provisioner "local-exec" {
    interpreter = ["PowerShell", "-Command"]
    command = "mysql -h ${aws_db_instance.example.address} -P ${aws_db_instance.example.port} -u ${aws_db_instance.example.username} --password=\"${var.db_password}\" -e \"CREATE DATABASE IF NOT EXISTS example_database;\""
  }
}