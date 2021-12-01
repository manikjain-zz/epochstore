# output "API_URL_GET" {
#   value       = "${aws_api_gateway_stage.epochstore.invoke_url}${aws_api_gateway_resource.getepochstore.path}"
#   description = "API URL for getting DB data"
# }

# output "API_URL_POST" {
#   value       = "${aws_api_gateway_stage.epochstore.invoke_url}${aws_api_gateway_resource.storeepochtime.path}"
#   description = "API URL for storing epoch data"
# }

# output "API_URL_HEALTH" {
#   value       = "${aws_api_gateway_stage.epochstore.invoke_url}${aws_api_gateway_resource.health-check.path}"
#   description = "API URL for storing epoch data"
# }

output "API_DOMAIN_NAME" {
  value       = aws_api_gateway_domain_name.epochstore.regional_domain_name
  description = "Regional domain name for the custom domain"
}

output "healthcheckid" {
  value = aws_route53_health_check.epochstore.id
}

output "zone_id" {
  value = data.aws_route53_zone.epochstore.zone_id
}