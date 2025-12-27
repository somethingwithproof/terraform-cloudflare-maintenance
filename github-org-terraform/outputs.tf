output "repository_urls" {
  description = "URLs of all managed repositories"
  value = {
    for name, repo in github_repository.repos :
    name => repo.html_url
  }
}

output "repository_ssh_urls" {
  description = "SSH clone URLs for all repositories"
  value = {
    for name, repo in github_repository.repos :
    name => repo.ssh_clone_url
  }
}

output "repository_ids" {
  description = "Repository IDs for reference"
  value = {
    for name, repo in github_repository.repos :
    name => repo.repo_id
  }
}

output "team_ids" {
  description = "Team IDs for reference"
  value = {
    for name, team in github_team.teams :
    name => team.id
  }
}

output "repository_default_branches" {
  description = "Default branches for all repositories"
  value = {
    for name, repo in github_repository.repos :
    name => repo.default_branch
  }
}