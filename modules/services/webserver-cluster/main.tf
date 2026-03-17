# Locally referenced variables for the webserver cluster module

locals {
 http_port = 80
 any_port = 0
 any_protocol = "-1"
 tcp_protocol = "tcp"
 all_ips = ["0.0.0.0/0"]
}


# Read only data source for AWS AMI
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }
  owners = ["099720109477"]
}

# Imported online available module for VPC (not using default VPC, for learning purpose)

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  version = "5.19.0"

  name = "example-vpc"
  cidr = "10.0.0.0/16"

  azs = ["us-east-1a", "us-east-1d", "us-east-1b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_dns_hostnames = true
}


# Security group resources

resource "aws_security_group" "app_sg" {
  name = "${var.cluster_name}-instance-sg"
  description = "Allow 8080 incoming traffic"
  vpc_id = module.vpc.vpc_id

  ingress {
    description = "HTTP 8080"
    from_port = var.server_port
    to_port = var.server_port
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "alb" {
 name = "${var.cluster_name}-alb-sg"

 vpc_id = module.vpc.vpc_id
 # Allow inbound HTTP requests
 ingress {
 from_port = local.http_port
 to_port = local.http_port
 protocol = local.tcp_protocol
 cidr_blocks = local.all_ips
 }
 # Allow all outbound requests
 egress {
 from_port = local.any_port
 to_port = local.any_port
 protocol = local.any_protocol
 cidr_blocks = local.all_ips
 }
}


# AWS Launch template for EC2 insttances

resource "aws_launch_template" "example" {
  name_prefix   = "${var.cluster_name}-"

  image_id      = data.aws_ami.ubuntu.id
  instance_type = var.instance_type

  vpc_security_group_ids = [aws_security_group.app_sg.id]

  user_data = base64encode(templatefile("${path.module}/user-data.sh", {
  server_port = var.server_port
  db_address  = var.address
  db_port     = var.port
}))
}


# AWS Target group container creation using the moduled VPC

resource "aws_lb_target_group" "asg" {
  name = "${var.cluster_name}-tg"
  port = var.server_port
  protocol = "HTTP"
  vpc_id = module.vpc.vpc_id

  health_check {
 path = "/"
 protocol = "HTTP"
 matcher = "200"
 interval = 15
 timeout = 3
 healthy_threshold = 2
 unhealthy_threshold = 2
 }
}


# AWS Auto scaling group resource with above launch template and target group enrichment with EC2 arns

resource "aws_autoscaling_group" "example" {
  vpc_zone_identifier = module.vpc.private_subnets

  launch_template {
  id      = aws_launch_template.example.id
  version = "$Latest"
  }

  target_group_arns = [aws_lb_target_group.asg.arn]
  health_check_type = "ELB"
  
  min_size = var.min_size
  max_size = var.max_size

  tag {
    key = "Name"
    value = "${var.cluster_name}-asg"
    propagate_at_launch = true
  }

}


# AWS Elastic Load Balancer resource on public subnet of moduled VPC with link ALB SG.

resource "aws_lb" "example" {
  name = "${var.cluster_name}-alb"
  load_balancer_type = "application"
  subnets = module.vpc.public_subnets
  security_groups = [aws_security_group.alb.id]
}

# AWS ALB listener resource linked to above AWS ELB resource

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.example.arn
  port = 80
  protocol = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "404: Page not found"
      status_code = 404
    }
  }
}

# AWS ALB listener rule applied on above AWS ALB Listener

resource "aws_lb_listener_rule" "asg" {
  listener_arn = aws_lb_listener.http.arn
  priority = 100

  condition {
    path_pattern {
    values = ["*"]
    }
  }

  action {
  type = "forward"
  target_group_arn = aws_lb_target_group.asg.arn
  }
}



# data "aws_vpc" default {
#   default = true
# }

# data "aws_subnet_ids" "default" {
#  vpc_id = data.aws_vpc.default.id
# }

# resource "aws_instance" "app_server" {
#     ami           = data.aws_ami.ubuntu.id
#     instance_type = var.instance_type

#     user_data = <<-EOF
#                 #!/bin/bash
#                 echo "Hello World" > index.html
#                 nohup busybox httpd -f -p ${var.server_port} &
#                 EOF

#     vpc_security_group_ids = [aws_security_group.app_sg.id]
#     subnet_id = module.vpc.public_subnets[0]

#     associate_public_ip_address = true

#     tags = {
#         Name = var.instance_name
#     }
# }