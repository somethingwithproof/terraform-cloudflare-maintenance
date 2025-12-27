# Backend configuration - choose based on your needs

# OPTION 1: Local backend (default for simplicity)
terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
}

# OPTION 2: S3 backend (uncomment for team use)
# terraform {
#   backend "s3" {
#     bucket  = "your-terraform-state-bucket"
#     key     = "github/terraform.tfstate"
#     region  = "us-west-2"
#     encrypt = true
#   }
# }

# OPTION 3: Terraform Cloud (uncomment for enterprise)
# terraform {
#   cloud {
#     organization = "your-org"
#     workspaces {
#       name = "github-management"
#     }
#   }
# }