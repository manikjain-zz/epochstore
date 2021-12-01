bucket         = "tf-remote-state20211130184829954700000002"
key            = "production/terraform.tfstate"
region         = "eu-central-1"
encrypt        = true
kms_key_id     = "04084dd4-a869-4213-8c7f-69576e5ff5b4"
dynamodb_table = "tf-remote-state-lock"
