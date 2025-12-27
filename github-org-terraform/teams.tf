resource "github_team" "teams" {
  for_each = var.team_members

  name        = each.key
  description = each.value.description
  privacy     = each.value.privacy
}

resource "github_team_membership" "members" {
  for_each = merge([
    for team_name, team in var.team_members : {
      for member in team.members :
      "${team_name}-${member}" => {
        team_id  = github_team.teams[team_name].id
        username = member
      }
    }
  ]...)

  team_id  = each.value.team_id
  username = each.value.username
  role     = "member"
}

resource "github_team_repository" "team_repos" {
  for_each = merge([
    for repo_name, repo in local.repositories : {
      for team_name in try(repo.teams, []) :
      "${team_name}-${repo_name}" => {
        team_id    = github_team.teams[team_name].id
        repository = github_repository.repos[repo_name].name
        permission = try(repo.team_permissions[team_name], "pull")
      }
    }
  ]...)

  team_id    = each.value.team_id
  repository = each.value.repository
  permission = each.value.permission
}