# Terraform Cloud backend configuration
# Uncomment and customize for your organization and workspace

# terraform {
#   cloud {
#     organization = "your-organization"
#
#     workspaces {
#       # For environment-specific workspaces
#       name = "cloudflare-maintenance-${var.environment}"
#       
#       # For a single workspace
#       # name = "cloudflare-maintenance"
#       
#       # For feature-branch development
#       # tags = ["cloudflare", "maintenance", "${var.environment}"]
#     }
#   }
# }

# Alternative: Use a remote backend with S3
# terraform {
#   backend "s3" {
#     bucket         = "tfstate-cloudflare-maintenance"
#     key            = "terraform.tfstate"
#     region         = "us-east-1"
#     encrypt        = true
#     dynamodb_table = "terraform-locks"
#   }
# }

# Alternative: Use a remote backend with Terraform Enterprise
# terraform {
#   backend "remote" {
#     hostname     = "app.terraform.io"
#     organization = "your-organization"
#
#     workspaces {
#       prefix = "cloudflare-maintenance-"
#     }
#   }
# }