provider "aws" {
  region = "us-east-1"
}

data "terraform_remote_state" "db" {
  backend = "s3"
  config = {
  bucket = "terraform-state-file-store-for-polarity"
  key = "stage/data-stores/mysql/terraform.tfstate"
  region = "us-east-1"
 }
}

module "webserver_cluster" {
  source = "../../../modules/services/webserver-cluster"
  cluster_name = "webservers-stage"
  
  server_port = var.server_port
  address  = data.terraform_remote_state.db.outputs.address
  port     = data.terraform_remote_state.db.outputs.port

  instance_type = "t3.micro"
  min_size = 2
  max_size = 2
}


resource "aws_autoscaling_schedule" "scale_out_during_business_hours" {
 scheduled_action_name = "scale-out-during-business-hours"
 min_size = 2
 max_size = 10
 desired_capacity = 10
 recurrence = "0 9 * * *"
 autoscaling_group_name = module.webserver_cluster.asg_name
}

resource "aws_autoscaling_schedule" "scale_in_at_night" {
 scheduled_action_name = "scale-in-at-night"
 min_size = 2
 max_size = 10
 desired_capacity = 2
 recurrence = "0 17 * * *"
 autoscaling_group_name = module.webserver_cluster.asg_name
}