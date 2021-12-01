resource "aws_api_gateway_rest_api" "epochstore" {
  name = "epoch-store"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_resource" "getepochstore" {
  parent_id   = aws_api_gateway_rest_api.epochstore.root_resource_id
  path_part   = "getEpochStore"
  rest_api_id = aws_api_gateway_rest_api.epochstore.id
}

resource "aws_api_gateway_method" "getepochstore" {
  authorization = "NONE"
  http_method   = "GET"
  resource_id   = aws_api_gateway_resource.getepochstore.id
  rest_api_id   = aws_api_gateway_rest_api.epochstore.id
}

resource "aws_api_gateway_integration" "getepochstore" {
  http_method             = aws_api_gateway_method.getepochstore.http_method
  resource_id             = aws_api_gateway_resource.getepochstore.id
  rest_api_id             = aws_api_gateway_rest_api.epochstore.id
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = module.get_epoch_lambda_function.lambda_function_invoke_arn
}

resource "aws_api_gateway_deployment" "epochstore" {
  rest_api_id = aws_api_gateway_rest_api.epochstore.id

  triggers = {
    # NOTE: The configuration below will satisfy ordering considerations,
    #       but not pick up all future REST API changes. More advanced patterns
    #       are possible, such as using the filesha1() function against the
    #       Terraform configuration file(s) or removing the .id references to
    #       calculate a hash against whole resources. Be aware that using whole
    #       resources will show a difference after the initial implementation.
    #       It will stabilize to only change when resources change afterwards.
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.getepochstore.id,
      aws_api_gateway_method.getepochstore.id,
      aws_api_gateway_integration.getepochstore.id,
      aws_api_gateway_resource.storeepochtime.id,
      aws_api_gateway_method.storeepochtime.id,
      aws_api_gateway_integration.storeepochtime.id,
      aws_api_gateway_resource.health-check.id,
      aws_api_gateway_method.health-check.id,
      aws_api_gateway_integration.health-check.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "epochstore" {
  deployment_id = aws_api_gateway_deployment.epochstore.id
  rest_api_id   = aws_api_gateway_rest_api.epochstore.id
  stage_name    = "prod"
}

resource "aws_lambda_permission" "get_epoch_apigw_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = module.get_epoch_lambda_function.lambda_function_name
  principal     = "apigateway.amazonaws.com"

  # More: http://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-control-access-using-iam-policies-to-invoke-api.html
  source_arn = "arn:aws:execute-api:${var.myregion}:${var.accountId}:${aws_api_gateway_rest_api.epochstore.id}/*/${aws_api_gateway_method.getepochstore.http_method}${aws_api_gateway_resource.getepochstore.path}"
}

resource "aws_api_gateway_resource" "storeepochtime" {
  parent_id   = aws_api_gateway_rest_api.epochstore.root_resource_id
  path_part   = "storeEpochTime"
  rest_api_id = aws_api_gateway_rest_api.epochstore.id
}

resource "aws_api_gateway_method" "storeepochtime" {
  authorization = "NONE"
  http_method   = "POST"
  resource_id   = aws_api_gateway_resource.storeepochtime.id
  rest_api_id   = aws_api_gateway_rest_api.epochstore.id
}

resource "aws_api_gateway_integration" "storeepochtime" {
  http_method             = aws_api_gateway_method.storeepochtime.http_method
  resource_id             = aws_api_gateway_resource.storeepochtime.id
  rest_api_id             = aws_api_gateway_rest_api.epochstore.id
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = module.store_epoch_lambda_function.lambda_function_invoke_arn
}

resource "aws_lambda_permission" "store_epoch_apigw_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = module.store_epoch_lambda_function.lambda_function_name
  principal     = "apigateway.amazonaws.com"

  # More: http://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-control-access-using-iam-policies-to-invoke-api.html
  source_arn = "arn:aws:execute-api:${var.myregion}:${var.accountId}:${aws_api_gateway_rest_api.epochstore.id}/*/${aws_api_gateway_method.storeepochtime.http_method}${aws_api_gateway_resource.storeepochtime.path}"
}

resource "aws_api_gateway_resource" "health-check" {
  parent_id   = aws_api_gateway_rest_api.epochstore.root_resource_id
  path_part   = "health"
  rest_api_id = aws_api_gateway_rest_api.epochstore.id
}

resource "aws_api_gateway_method" "health-check" {
  authorization = "NONE"
  http_method   = "GET"
  resource_id   = aws_api_gateway_resource.health-check.id
  rest_api_id   = aws_api_gateway_rest_api.epochstore.id
}

resource "aws_api_gateway_integration" "health-check" {
  http_method             = aws_api_gateway_method.health-check.http_method
  resource_id             = aws_api_gateway_resource.health-check.id
  rest_api_id             = aws_api_gateway_rest_api.epochstore.id
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = module.health-check_lambda_function.lambda_function_invoke_arn
}

resource "aws_lambda_permission" "health-check_apigw_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = module.health-check_lambda_function.lambda_function_name
  principal     = "apigateway.amazonaws.com"

  # More: http://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-control-access-using-iam-policies-to-invoke-api.html
  source_arn = "arn:aws:execute-api:${var.myregion}:${var.accountId}:${aws_api_gateway_rest_api.epochstore.id}/*/${aws_api_gateway_method.health-check.http_method}${aws_api_gateway_resource.health-check.path}"
}

resource "aws_api_gateway_domain_name" "epochstore" {
  domain_name              = "api.epoch-store.xyz"
  regional_certificate_arn = aws_acm_certificate_validation.epochstore.certificate_arn

  security_policy = "TLS_1_2"

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  depends_on = [
    aws_acm_certificate_validation.epochstore 
  ]
}

resource "aws_api_gateway_base_path_mapping" "epochstore" {
  api_id      = aws_api_gateway_rest_api.epochstore.id
  stage_name  = aws_api_gateway_stage.epochstore.stage_name
  domain_name = aws_api_gateway_domain_name.epochstore.domain_name
}