resource "aws_route53_health_check" "epochstore" {
  fqdn              = "${aws_api_gateway_rest_api.epochstore.id}.execute-api.${var.myregion}.amazonaws.com"
  port              = 443
  type              = "HTTPS"
  resource_path     = "/prod/health"
  failure_threshold = "5"
  request_interval  = "30"

  tags = {
    Name = "epoch-store-health-check_${var.myregion}"
  }

  depends_on = [
      aws_api_gateway_base_path_mapping.epochstore
  ]
}