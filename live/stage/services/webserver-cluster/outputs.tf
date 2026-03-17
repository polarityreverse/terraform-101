# output "instance_hostname" {
#     description = "Private DNS name of the EC2 instance."
#     value = aws_instance.app_server.private_dns
# }

# output "web_server_url" {
#   description = "Direct URL to access the web server on port 8080."
#   value       = "http://${aws_instance.app_server.public_ip}:8080"
# }

output "alb_dns_name" {
 value = module.webserver_cluster.alb_dns_name
 description = "The domain name of the load balancer"
}

