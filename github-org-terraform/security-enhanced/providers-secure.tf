# Secure provider configuration with multiple authentication methods

terraform {
  required_version = ">= 1.0"

  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 6.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    vault = {
      source  = "hashicorp/vault"
      version = "~> 3.0"
    }
  }
}

# GitHub App Authentication (Most Secure)
provider "github" {
  owner = var.github_organization

  # Option 1: GitHub App (Recommended for production)
  app_auth {
    id              = var.github_app_id
    installation_id = var.github_app_installation_id
    pem_file        = var.github_app_pem_file
  }

  # Option 2: Personal Access Token from AWS Secrets Manager
  # token = data.aws_secretsmanager_secret_version.github_token.secret_string

  # Option 3: Token from HashiCorp Vault
  # token = data.vault_generic_secret.github_token.data["token"]
}

# AWS Provider for Secrets Manager
provider "aws" {
  region = var.aws_region

  # Use IAM role instead of access keys
  assume_role {
    role_arn     = var.terraform_role_arn
    session_name = "terraform-github-management"
  }

  default_tags {
    tags = {
      ManagedBy   = "Terraform"
      Project     = "GitHub Organization"
      Environment = var.environment
    }
  }
}

# HashiCorp Vault Provider (Optional)
provider "vault" {
  address = var.vault_address

  # Use AWS IAM auth method
  auth_login {
    path = "auth/aws/login"

    parameters = {
      role = "terraform-github"
    }
  }
}

# Data sources for secure token retrieval
data "aws_secretsmanager_secret" "github_token" {
  name = "github/terraform/token"
}

data "aws_secretsmanager_secret_version" "github_token" {
  secret_id = data.aws_secretsmanager_secret.github_token.id
}

# GitHub App PEM file from Secrets Manager
data "aws_secretsmanager_secret" "github_app_pem" {
  name = "github/app/pem"
}

data "aws_secretsmanager_secret_version" "github_app_pem" {
  secret_id = data.aws_secretsmanager_secret.github_app_pem.id
}

# Current AWS account information
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Variables for secure provider configuration
variable "github_app_id" {
  description = "GitHub App ID for authentication"
  type        = string
  sensitive   = true
}

variable "github_app_installation_id" {
  description = "GitHub App Installation ID"
  type        = string
  sensitive   = true
}

variable "github_app_pem_file" {
  description = "Path to GitHub App PEM file"
  type        = string
  default     = null
  sensitive   = true
}

variable "terraform_role_arn" {
  description = "IAM role ARN for Terraform to assume"
  type        = string
}

variable "vault_address" {
  description = "HashiCorp Vault address"
  type        = string
  default     = "https://vault.example.com"
}

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-west-2"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "production"

  validation {
    condition     = contains(["dev", "staging", "production"], var.environment)
    error_message = "Environment must be dev, staging, or production."
  }
}