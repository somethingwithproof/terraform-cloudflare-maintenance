# This file sets up the AWS backend infrastructure
# Run this separately first: terraform apply -target=module.backend_setup

module "backend_setup" {
  source = "./modules/backend-setup"

  bucket_name    = "github-terraform-state"
  dynamodb_table = "terraform-state-locks"
  kms_alias      = "alias/github-terraform"
  environment    = "production"

  tags = {
    ManagedBy   = "Terraform"
    Purpose     = "GitHub Organization State"
    Environment = "Production"
  }
}

# modules/backend-setup/main.tf
resource "aws_s3_bucket" "terraform_state" {
  bucket = var.bucket_name

  lifecycle {
    prevent_destroy = true
  }

  tags = var.tags
}

resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.terraform_state.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_logging" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  target_bucket = aws_s3_bucket.log_bucket.id
  target_prefix = "terraform-state-logs/"
}

resource "aws_s3_bucket" "log_bucket" {
  bucket = "${var.bucket_name}-logs"

  lifecycle {
    prevent_destroy = true
  }

  tags = var.tags
}

resource "aws_s3_bucket_lifecycle_configuration" "log_bucket" {
  bucket = aws_s3_bucket.log_bucket.id

  rule {
    id     = "delete-old-logs"
    status = "Enabled"

    expiration {
      days = 90
    }
  }
}

resource "aws_dynamodb_table" "terraform_locks" {
  name         = var.dynamodb_table
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = aws_kms_key.terraform_state.arn
  }

  point_in_time_recovery {
    enabled = true
  }

  lifecycle {
    prevent_destroy = true
  }

  tags = var.tags
}

resource "aws_kms_key" "terraform_state" {
  description             = "KMS key for GitHub Terraform state encryption"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  tags = var.tags
}

resource "aws_kms_alias" "terraform_state" {
  name          = var.kms_alias
  target_key_id = aws_kms_key.terraform_state.key_id
}

# modules/backend-setup/variables.tf
variable "bucket_name" {
  description = "Name of the S3 bucket for Terraform state"
  type        = string
}

variable "dynamodb_table" {
  description = "Name of the DynamoDB table for state locks"
  type        = string
}

variable "kms_alias" {
  description = "Alias for the KMS key"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

# modules/backend-setup/outputs.tf
output "bucket_name" {
  value = aws_s3_bucket.terraform_state.id
}

output "dynamodb_table" {
  value = aws_dynamodb_table.terraform_locks.id
}

output "kms_key_id" {
  value = aws_kms_key.terraform_state.id
}

output "kms_key_arn" {
  value = aws_kms_key.terraform_state.arn
}