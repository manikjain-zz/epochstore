module "s3_bucket" {
  source = "terraform-aws-modules/s3-bucket/aws"

  bucket        = "epoch-store-bucket-${var.myregion}"
  force_destroy = true
}





