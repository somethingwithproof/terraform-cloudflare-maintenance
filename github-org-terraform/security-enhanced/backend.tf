terraform {
  backend "s3" {
    bucket         = "github-terraform-state"
    key            = "github-org/terraform.tfstate"
    region         = "us-west-2"
    encrypt        = true
    kms_key_id     = "arn:aws:kms:us-west-2:ACCOUNT_ID:key/KMS_KEY_ID"
    dynamodb_table = "terraform-state-locks"

    # Additional security settings
    versioning = true
    server_side_encryption_configuration {
      rule {
        apply_server_side_encryption_by_default {
          sse_algorithm     = "aws:kms"
          kms_master_key_id = "arn:aws:kms:us-west-2:ACCOUNT_ID:key/KMS_KEY_ID"
        }
      }
    }
  }
}

# Alternative local backend for development
# Uncomment to use local state during development
# terraform {
#   backend "local" {
#     path = "terraform.tfstate"
#   }
# }