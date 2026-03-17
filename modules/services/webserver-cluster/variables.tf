variable "instance_name" {
    description = "Name of the EC2 instance."
    type = string
    default = "learn-terraform"
}

variable "instance_type" {
    description = "EC2 Instance type.."
    type = string
    default = "t3.micro"
}

variable "min_size" {
 description = "The minimum number of EC2 Instances in the ASG"
 type = number
}
variable "max_size" {
 description = "The maximum number of EC2 Instances in the ASG"
 type = number
}

variable "server_port" {
    description = "Incoming HTTP request server port.."
    type = number
    default = 8080
}

variable "cluster_name" {
    description = "The name to use for all the cluster resources"
    type = string
}

variable "address" {
  description = "Database endpoint passed from root module"
  type        = string
}

variable "port" {
  description = "Database port passed from root module"
  type        = number
}