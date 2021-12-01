
# epochstore (API in AWS)

Author and Developer: `Manik Jain`

The Terraform code in this repository deploys an active-active multi-region API application in AWS which is used to store the current epoch time in a DB. It mainly comprises of the following AWS services: API Gateway, Lambda, DynamoDB, Route53 (traffic policies, health checks), CloudWatch for logging and monitoring, S3 bucket for storing Lambda packages and Terraform state.

Table of Contents
=================
* [Architecture](#architecture)
  * [Resiliency](#resiliency)
  * [Scalability](#scalability)
  * [Security](#security)
  * [Monitoring](#monitoring)
* [Folder structure](#folder-structure)
* [Prerequisites](#prerequisites)
* [Setup](#setup)
  * [Remote state and TF session management (optional)](#remote-state-and-tf-session-management-optional)
  * [Deployment](#deployment)
* [Delete resources](#delete-resources)
* [Test HA and failover](#test-ha-and-failover)

## Architecture

![image](https://user-images.githubusercontent.com/21245503/144255050-0119d0ec-f4b4-4874-b493-19f689fdd0b9.png)

### Resiliency

1. Active-active multi-region setup.
2. Point-in-time recovery enabled for DynamoDB along with multi-region replication.

### Scalability

1. DynamoDB setup for autoscaling read and write capacity based on a target utilisation metric.
2. Lambda is scalable by default up to a certain number of invocations based on the region. Additionally, latency that comes from a cold start is addressed via provisioned concurrency (pre-prepare Lambda for a warm start). Provisioned concurrency could be auto-scaled as well.

### Security

1. Data encryption via CMK KMS keys for DynamoDB.
2. TLS-based access for the API endpoint URLs.

### Monitoring

1. CloudWatch logs all data and metrics related to Lambda function invocation and DynamoDB operations.

## Folder structure

    .
    ├── modules (dir)                  # Custom terraform modules
    |   ├── epoch_store_dynamodb_table # Customised native dynamodb module
    |   └── epoch_store_front          # Custom built module
    ├── remote-state (dir)             # Terraform files for setting up remote state artifacts in S3 and dynamodb
    ├── src/handlers                   # Lambda functions/handlers
    |   ├── get-epoch-store.js.        # Get function
    |   ├── store-epoch-time.js        # Post function
    |   └── health-check.py            # Health check function
    ...
    (terraform files)
    ...             
    └── README.md

## Prerequisites:
1. Terraform (> `v1.0.11` or higher) must be installed on your machine.
1. aws-cli (> `2.1.8` or higher).
1. AWS security credentials - ACCESS_KEY and SECRET_ACCESS_KEY stored in a file such as `~/.aws/credentials`. Refer the following guide to learn how to store your AWS creds: [https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html).

## Setup

### Remote state and TF session management (optional)

The following steps set up an S3 bucket with replication, KMS keys for encrypting state files, dynamoDB table for state locking. You can read more about what we will setup here at this link: https://registry.terraform.io/modules/nozaq/remote-state-s3-backend/aws/latest.

1. `cd remote-state/`
2. Populate the `terraform.tfvars` file as follows:
```
aws_creds  =  "PATH TO AWS CREDS"
region_a  =  "eu-central-1" # Choose a region 1
region_b  =  "eu-west-3" # Choose a region 2
aws_profile  =  "default" # Specify an AWS PROFILE
```
 3. Run `terraform init` to initialise.
 4. Check with `terraform plan` if everything looks good. Run `terraform apply` to apply the changes. You will receive an output which looks like this:
```
Apply complete! Resources: 15 added, 0 changed, 0 destroyed.

Outputs:

kms_key = "xxxxxxx-xxxxxx-xxxx-xxxx"
state_bucket = "tf-remote-state............."
state_dynamo_db = "tf-remote-state-lock"
```
5. Grab the output values from step 4 as per what you received, we will need these to create a remote backend in the deployment steps.

### Deployment

The following steps mainly set up -

An API Gateway with a custom domain using an ACM certificate.
Three Lambda functions as in `src/handlers` with CloudWatch monitoring. S3 bucket for storing Lambda zip.
DynamoDB table in two regions (as chosen) with point-in-time backups enabled and read/write capacity autoscaling.
Route53 health checks (uses the `health-check.py` lambda function), traffic policy (weighted routing) and a policy record.

1. You must be in the root folder.  If you did not follow the first optional setup, skip the next few steps and proceed to step 5 directly. 
2. Populate the `backend.tfvars` as follows:
```
bucket =  "" # Value as grabbed earlier
key =  "production/terraform.tfstate" # location of state file in S3
region =  "eu-central-1" # region based on region selection earlier
encrypt =  true
kms_key_id =  "xxxxxxx-xxxxxx-xxxx-xxxx" # Key from previous setup
dynamodb_table =  "tf-remote-state-lock"
```
3. Export environment variables on your command line as follows:
```
export AWS_ACCESS_KEY_ID=""
export AWS_SECRET_ACCESS_KEY=""
```
4. Populate the `terraform.tfvars` file as follows. **Note:-** Your domain name will need to be managed by Route53. Be sure to create a hosted zone in Route53 with your domain name and change the nameservers in your domain provider settings to Route53 nameservers.
```
dynamodb_table_name  =  "EpochStoreDB" # A name for the DB table
accountId  =  AWS_ACCOUNT_ID
region_a  =  "eu-central-1" # Choose a region 1
region_b  =  "eu-west-3" # Choose a region 2
domain  =  "api.example.com" # Your domain name to use for the API
aws_creds  =  PATH TO AWS CREDS
aws_profile  =  AWS_PROFILE
```
5. Run `terraform init -backend-config=backend.tfvars`.
6. If you did not follow the previous steps, remove `backend.tfvars` and `remote-backend.tf` before proceeding.
7. Run `terraform plan` to check if everything looks good. Run `terraform apply` to apply the changes. **Note:-** Sometimes apply can fail on archiving the lambda functions, in this case, a re-run of `terraform apply` should be fine.
8. Verify if the health checks in Route53 show as healthy.
9. Run a POST API call: `curl -X POST https://your.domain.name/storeEpochTime`.
10. Run a GET API call: `curl https://your.domain.name/getEpochStore` or browse `https://your.domain.name/getEpochStore`.

## Delete resources

Run `terraform destroy` in both the root and `remote-state` directory. (Skip running in `remote-state` if it was not setup earlier)

## Test HA and failover

1.  As you post on the API, it alternates between both regions. If one region is unavailable, all the traffic will be routed to the second region.
2. To test a failover, purposefully fail a region by setting the `STATUS` environment variable to `fail` on the `health-check` lambda function.
3. The health checks for the modified region should now start to fail and all new traffic is automatically routed to the other region. Try making a few POST calls to verify if the other region is getting all the traffic.
