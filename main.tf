module "epoch_store_front_frankfurt" {
  source = "./modules/epoch_store_front"
  myregion            = var.region_a
  accountId           = "523764881531"
  dynamodb_table_name = "EpochStore"
}

module "epoch_store_front_paris" {
  providers = {
    aws = aws.euwest3
  }
  source = "./modules/epoch_store_front"
  myregion            = var.region_b
  accountId           = "523764881531"
  dynamodb_table_name = "EpochStore"
}