module "get_epoch_lambda_function" {
  source = "terraform-aws-modules/lambda/aws"

  function_name = "get-epoch-store"
  description   = "Get epoch time storage from DynamoDB"
  handler       = "get-epoch-store.handler"
  runtime       = "nodejs14.x"
  architectures = ["x86_64"]
  publish       = true

  #   provisioned_concurrent_executions = 1

  source_path = "./src/handlers/get-epoch-store.js"

  store_on_s3 = true
  s3_bucket   = module.s3_bucket.s3_bucket_id
  s3_prefix   = "lambda-builds_get_epoch/"

  role_name = "get-epoch-store_${var.myregion}"
  attach_policy = true
  policy        = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"

  attach_policy_json = true
  policy_json        = <<EOF
{
    "Version" : "2012-10-17",
    "Statement" : [
        {
            "Effect" : "Allow",
            "Action" : [
                "kms:Decrypt"
            ],
            "Resource" : [
                "*"
            ]
        }
    ]
}
EOF

  environment_variables = {
    DBTable    = var.dynamodb_table_name
    Serverless = "Terraform"
    Region = var.myregion
  }

  tags = {
    Module = "lambda_function"
  }
}

module "store_epoch_lambda_function" {
  source = "terraform-aws-modules/lambda/aws"

  function_name = "store-epoch-time"
  description   = "Store the current epoch time into DynamoDB"
  handler       = "store-epoch-time.handler"
  runtime       = "nodejs14.x"
  architectures = ["x86_64"]
  publish       = true

  #   provisioned_concurrent_executions = 1

  source_path = "./src/handlers/store-epoch-time.js"

  store_on_s3 = true
  s3_bucket   = module.s3_bucket.s3_bucket_id
  s3_prefix   = "lambda-builds_store_epoch/"

  role_name = "store-epoch-time_${var.myregion}"
  attach_policy = true
  policy        = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"

  attach_policy_json = true
  policy_json        = <<EOF
{
    "Version" : "2012-10-17",
    "Statement" : [
        {
            "Effect" : "Allow",
            "Action" : [
                "kms:Decrypt"
            ],
            "Resource" : [
                "*"
            ]
        }
    ]
}
EOF

  environment_variables = {
    DBTable    = var.dynamodb_table_name
    Serverless = "Terraform"
    Region = var.myregion
  }

  tags = {
    Module = "lambda_function"
  }
}

module "health-check_lambda_function" {
  source = "terraform-aws-modules/lambda/aws"

  function_name = "health-check"
  description   = "Health check"
  handler       = "health-check.handler"
  runtime       = "python3.6"
  architectures = ["x86_64"]
  publish       = true

  #   provisioned_concurrent_executions = 1

  source_path = "./src/handlers/health-check.py"

  store_on_s3 = true
  s3_bucket   = module.s3_bucket.s3_bucket_id
  s3_prefix   = "lambda-builds_health_check/"

  role_name = "health-check_${var.myregion}"

  environment_variables = {
    STATUS = "200"
    Serverless = "Terraform"
  }

  tags = {
    Module = "lambda_function"
  }
}