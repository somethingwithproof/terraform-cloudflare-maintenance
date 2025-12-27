locals {
  repositories = {
    "chef-r-language-cookbook" = {
      description = "[infrastructure] Installs and configures the R programming language (Chef)."
      visibility  = "private"
      topics      = ["chef", "cookbook", "r-language", "infrastructure", "devops"]
    }

    "wordpress-gmail-cli" = {
      description = "A simple CLI tool to quickly configure WordPress and Postfix for sending outbound emails using Gmail SMTP. Ideal for automating reliable email delivery setup on your WordPress server."
      visibility  = "private"
      topics      = ["wordpress", "gmail", "smtp", "cli", "email", "postfix"]
    }

    "utility-scripts-collection" = {
      description = "[data] Provides utility scripts for system maintenance and automation tasks."
      visibility  = "private"
      topics      = ["utilities", "scripts", "automation", "maintenance", "data"]
    }

    "cloudflare-ufw-sync" = {
      description = "Enterprise-grade Cloudflare UFW Sync"
      visibility  = "private"
      topics      = ["cloudflare", "ufw", "firewall", "security", "sync"]
    }

    "jenkins-script-library" = {
      description = "Jenkins shared library with Groovy utilities for CI/CD automation and pipeline management"
      visibility  = "private"
      topics      = ["jenkins", "groovy", "ci-cd", "pipeline", "automation"]
    }

    "chef-nginx-cookbook" = {
      description = "Comprehensive Chef cookbook for NGINX with advanced features"
      visibility  = "private"
      topics      = ["chef", "cookbook", "nginx", "webserver", "infrastructure"]
    }

    "commitkit-rust" = {
      description = "[utilities] A command-line tool written in Rust for creating conventional commit messages."
      visibility  = "private"
      topics      = ["rust", "cli", "git", "conventional-commits", "utilities"]
    }

    "terraform-cloudflare-maintenance" = {
      description = "Terraform module for CloudFlare maintenance page with Workers integration"
      visibility  = "private"
      topics      = ["terraform", "cloudflare", "workers", "maintenance", "infrastructure"]
    }

    "rust-findagrave-citation-parser" = {
      description = "[data] A Rust-based parser for extracting citation data from Find a Grave memorial pages, including birth, death, and burial information."
      visibility  = "private"
      topics      = ["rust", "parser", "genealogy", "data", "findagrave"]
    }

    "mantl" = {
      description = "Mantl is a modern platform for rapidly deploying globally distributed services"
      visibility  = "private"
      topics      = ["platform", "distributed-systems", "deployment", "infrastructure"]
    }

    "oracle-inventory-management-tool" = {
      description = "[utilities] Manages Oracle inventory, focusing on assets and configurations."
      visibility  = "private"
      topics      = ["oracle", "inventory", "management", "utilities", "database"]
    }

    "ansible-role-mariadb" = {
      description = "An enterprise-grade Ansible role for deploying and managing MariaDB/MySQL database servers with high availability, security, and performance optimization."
      visibility  = "private"
      topics      = ["ansible", "mariadb", "mysql", "database", "high-availability"]
    }

    "aws-ssm-automation-scripts" = {
      description = "[infrastructure] Automates AWS Systems Manager (SSM) operations."
      visibility  = "private"
      topics      = ["aws", "ssm", "automation", "infrastructure", "devops"]
    }

    "python-network-discovery-tool" = {
      description = "[networking] Discovers network devices and configurations (Python)."
      visibility  = "private"
      topics      = ["python", "networking", "discovery", "automation"]
    }

    "chef-cookbook-template" = {
      description = "Modern Chef cookbook template with best practices for Chef 19+ development"
      visibility  = "private"
      topics      = ["chef", "cookbook", "template", "best-practices"]
    }

    "chef-httpd-cookbook" = {
      description = "Modern Chef cookbook for Apache HTTP Server configuration and management"
      visibility  = "private"
      topics      = ["chef", "cookbook", "apache", "httpd", "webserver"]
    }

    "yieldmax-dashboard" = {
      description = "Dashboard for YieldMax analytics and monitoring"
      visibility  = "private"
      topics      = ["dashboard", "analytics", "monitoring"]
    }

    "chef-tcp-wrappers" = {
      description = "[infrastructure] Manages TCP Wrappers for host-based access control (Chef)."
      visibility  = "private"
      topics      = ["chef", "cookbook", "tcp-wrappers", "security", "infrastructure"]
    }

    "dotfiles" = {
      description = "Personal configuration files and environment setup"
      visibility  = "private"
      topics      = ["dotfiles", "configuration", "setup"]
    }

    "terraform-aws-dedicated-host" = {
      description = "[infrastructure] Terraform module to efficiently manage AWS Dedicated Hosts and integrate with AWS License Manager, simplifying autoscaling setup."
      visibility  = "private"
      topics      = ["terraform", "aws", "dedicated-host", "license-manager", "infrastructure"]
    }
  }
}

resource "github_repository" "repos" {
  for_each = local.repositories

  name        = each.key
  description = each.value.description
  visibility  = each.value.visibility

  has_issues             = var.enable_issues
  has_projects           = var.enable_projects
  has_wiki               = var.enable_wiki
  has_discussions        = var.enable_discussions
  has_downloads          = true
  delete_branch_on_merge = var.delete_branch_on_merge
  auto_init              = false

  allow_squash_merge = var.allow_squash_merge
  allow_merge_commit = var.allow_merge_commit
  allow_rebase_merge = var.allow_rebase_merge
  allow_auto_merge   = false

  vulnerability_alerts = var.vulnerability_alerts

  topics = try(each.value.topics, [])

  lifecycle {
    prevent_destroy = true
  }
}

resource "github_branch_protection" "main" {
  for_each = { for k, v in local.repositories : k => v if try(var.branch_protection_rules[k], null) != null }

  repository_id = github_repository.repos[each.key].node_id
  pattern       = try(var.branch_protection_rules[each.key].pattern, "main")

  enforce_admins         = try(var.branch_protection_rules[each.key].enforce_admins, false)
  require_signed_commits = try(var.branch_protection_rules[each.key].require_signed_commits, false)

  required_status_checks {
    strict   = true
    contexts = try(var.branch_protection_rules[each.key].required_status_checks, [])
  }

  required_pull_request_reviews {
    dismiss_stale_reviews           = try(var.branch_protection_rules[each.key].dismiss_stale_reviews, true)
    require_code_owner_reviews      = try(var.branch_protection_rules[each.key].require_code_owner_reviews, false)
    required_approving_review_count = try(var.branch_protection_rules[each.key].required_approving_review_count, 1)
  }
}