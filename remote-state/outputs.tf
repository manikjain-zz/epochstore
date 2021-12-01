output "state_bucket" {
  value       = module.remote_state.state_bucket.bucket
  description = "Name of the remote state bucket"
}

output "kms_key" {
  value       = module.remote_state.kms_key.id
  description = "KMS key for remote state"
}

output "state_dynamo_db" {
  value       = module.remote_state.dynamodb_table.id
  description = "Dynamo DB for remote state"
}