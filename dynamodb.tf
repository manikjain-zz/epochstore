locals {
  tags = {
    Terraform   = "true"
    Environment = "Production"
  }
}

resource "aws_kms_key" "primary" {
  description = "CMK for primary region"
  tags        = local.tags
}

resource "aws_kms_key" "secondary" {
  provider = aws.euwest3

  description = "CMK for secondary region"
  tags        = local.tags
}

module "epoch_store_dynamodb_table" {
  source = "./modules/epoch_store_dynamodb_table"

  name             = var.dynamodb_table_name
  hash_key         = "id"
  billing_mode     = "PROVISIONED"
  read_capacity    = 5
  write_capacity   = 5
  stream_enabled   = true
  stream_view_type = "NEW_AND_OLD_IMAGES"

  autoscaling_read = {
    scale_in_cooldown  = 50
    scale_out_cooldown = 40
    target_value       = 45
    max_capacity       = 10
  }

  autoscaling_write = {
    scale_in_cooldown  = 50
    scale_out_cooldown = 40
    target_value       = 45
    max_capacity       = 10
  }

  server_side_encryption_enabled     = true
  server_side_encryption_kms_key_arn = aws_kms_key.primary.arn

  attributes = [
    {
      name = "id"
      type = "S"
    }
  ]

  # The following block for replication is commented out due to 
  # an AWS API issue as described in: https://github.com/hashicorp/terraform-provider-aws/issues/13097
  # To mitigate this, a local-exec provisioner is being used to enable
  # replication on the dynamodb table
  # NOTE: Uncomment 'replica_regions' after first run, if you plan to run TF
  # again, so as to prevent TF from removing the replica settings.

    # replica_regions = [{
    #   region_name = "eu-west-3"
    #   kms_key_arn = aws_kms_key.secondary.arn
    # }]

  point_in_time_recovery_enabled = true

  tags = local.tags

}

resource "time_sleep" "table_creation" {
  create_duration = "120s"

  depends_on = [
    module.epoch_store_dynamodb_table
  ]
}

resource "null_resource" "enable_replication_dynamodb" {
  depends_on = [
    module.epoch_store_dynamodb_table,
    time_sleep.table_creation
  ]

  provisioner "local-exec" {
    command = "aws dynamodb update-table --region ${var.region_a} --table-name ${var.dynamodb_table_name}  --replica-updates 'Create={RegionName=${var.region_b},KMSMasterKeyId=${aws_kms_key.secondary.arn}}'"
  }
  
}

resource "time_sleep" "replica_table_creation" {
  create_duration = "300s"

  depends_on = [
    null_resource.enable_replication_dynamodb
  ]
}

resource "null_resource" "enable_pitr_dynamodb" {

  provisioner "local-exec" {
    command = "aws dynamodb update-continuous-backups --region ${var.region_b} --table-name ${var.dynamodb_table_name} --point-in-time-recovery-specification PointInTimeRecoveryEnabled=true"
  }

  depends_on = [
    time_sleep.replica_table_creation
  ]
}