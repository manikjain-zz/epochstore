module "remote_state" {
  source = "nozaq/remote-state-s3-backend/aws"

  providers = {
    aws         = aws
    aws.replica = aws.euwest3
  }
}

resource "aws_iam_user" "terraform" {
  name = "TerraformUser"
}

resource "aws_iam_user_policy_attachment" "remote_state_access" {
  user       = aws_iam_user.terraform.name
  policy_arn = module.remote_state.terraform_iam_policy.arn
}
