provider "aws" {
  profile                 = var.aws_profile
  region                  = var.region_a
  shared_credentials_file = var.aws_creds

  # Make it faster by skipping something
  skip_get_ec2_platforms      = true
  skip_metadata_api_check     = true
  skip_region_validation      = true
  skip_credentials_validation = true
  skip_requesting_account_id  = true
}

provider "aws" {
  profile = var.aws_profile
  alias   = "euwest3"
  region  = var.region_b

  shared_credentials_file = var.aws_creds

  # Make it faster by skipping something
  skip_get_ec2_platforms      = true
  skip_metadata_api_check     = true
  skip_region_validation      = true
  skip_credentials_validation = true
  skip_requesting_account_id  = true
}