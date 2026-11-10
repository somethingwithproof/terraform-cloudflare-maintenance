# Changelog

All notable changes to this module are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the module uses
[Semantic Versioning](https://semver.org/).

## [Unreleased]

### Breaking changes

- CD reads every deploy input from the GitHub environment: `TF_API_TOKEN`
  is now an environment secret (one HCP token per environment) instead of a
  repository secret, and `MAINTENANCE_ENABLED`, `MAINTENANCE_WINDOW`,
  `ALLOWED_IPS`, `ALLOWED_REGIONS` and `CONTACT_EMAIL` are environment
  variables. Before, Local execution ignored the HCP workspace variables, so
  every apply reset the allowlists and contact address to empty, and a tag
  push turned maintenance off in `dev`. A tag push now deploys the
  environment's variables unchanged, and **Run workflow** overrides
  `enabled` (`environment`, `true` or `false`) and the window for one run
  only. Move `TF_API_TOKEN` into each environment before the next deploy.

- The Worker script is named by the new `script_name` variable, which
  defaults to `maintenance-page-<environment>` instead of the fixed
  `maintenance-page-worker`. Two module instances in one account (for
  example one per environment) used to share that Worker: each apply
  overwrote the other's code and bindings, and destroying one deleted the
  Worker the others routed to. The next apply creates the new Worker, moves
  the route to it and then deletes the old one, so the route never points at
  a missing Worker. Every instance that shared the old Worker moves to its
  own name on its own next apply; until then it still routes to the shared
  one, so apply each of them. To keep the old name, set
  `script_name = "maintenance-page-worker"` in at most one instance per
  account. Names must be 1-63 lowercase letters, digits or dashes; an empty
  string is rejected.

- Notifications module: `SCHEDULED` no longer triggers a PagerDuty incident
  (it never resolved on its own, because nothing applies when a window ends).
  Slack and webhook targets still get the message, and `event_action` is
  `none` for it. When `schedule_name` or `environment` changes while an
  incident is open, or the status drops back to `SCHEDULED`, the old incident
  is now resolved under its old dedup key. Incidents opened by an earlier
  release for `SCHEDULED` are not tracked; resolve them by hand.

- The module no longer configures the Cloudflare provider and the
  `cloudflare_api_token` variable is removed. Configure the provider in the
  calling root module (for example from `CLOUDFLARE_API_TOKEN`) and drop the
  `cloudflare_api_token` argument. A module with its own provider block cannot
  be used with `count`, `for_each` or `depends_on`, and it silently overrode
  the caller's provider. The commented-out `backend.tf` is removed as well.

- Notifications module: `notification_urls` is now a sensitive
  `map(string)` of non-secret names to URLs instead of a list, and
  `webhook://` targets must use HTTPS. Before, the URLs were stored in state
  and shown in plan diffs, a sensitive list failed `for_each`, and every
  apply re-sent a PagerDuty trigger because the trigger included
  `timestamp()`. Notifications are now `terraform_data` resources that fire
  only when the status, schedule, environment or window changes, PagerDuty
  incidents are resolved when the status is `DISABLED` or `COMPLETED`, and
  requests use `curl -fsS --max-time 10 --retry 2`. The module no longer
  requires the null provider. On the first apply after upgrading, the old
  `null_resource` entries are destroyed and one notification per target is
  sent.

- Removed the `schedules` variable and output. Nothing consumed them; the
  cron schedules were never acted on. Remove `schedules` from module calls.
- A `maintenance_window` now restricts the page to that window even when
  `enabled = true`. Before, `enabled = true` served the page at all times and
  the window had no effect. To serve the page immediately, set `enabled = true`
  and leave `maintenance_window` unset.
- `maintenance_status` reports `SCHEDULED` whenever a window is set.

- Removed the `maintenance-bypass-<environment>` ruleset. It created the
  zone's `http_request_firewall_custom` entry-point ruleset and skipped the
  WAF, managed rules and rate limiting for every request from
  `allowed_regions` and `allowed_ips`. The Worker already performs its own
  bypass, so the next apply deletes that ruleset. The `ruleset_id` output is
  gone.
- The Cloudflare provider floor is now 5.19, the first v5 release with the
  automatic v4 state upgraders. The unused external, local, null and random
  provider requirements are gone.
- Removed the `maintenance-status-<environment>` DNS record and the
  `maintenance_page_url` and `dns_record_id` outputs. No Worker route covered
  that hostname, so the URL never served the maintenance page. The next apply
  deletes the record.

### Added

- `deploy/` root configuration and a CD workflow that applies it with state in
  HCP Terraform, one workspace per environment, and fails before `init` when
  the HCP or Cloudflare settings are missing.

- Scheduled maintenance windows work without `enabled = true`: setting
  `maintenance_window` deploys the Worker route, and the Worker serves the
  page from `start_time` (inclusive) to `end_time` (exclusive) and passes
  traffic through outside it. `end_time` must be after `start_time`.

- `allowed_ips` accepts IPv4 and IPv6 CIDR ranges, matches IPv6 addresses in
  any spelling and treats IPv4-mapped IPv6 as IPv4. Entries are validated at
  plan time.

### Security

- `deploy/.terraform.lock.hcl` is committed for linux_amd64, darwin_arm64 and
  darwin_amd64 and CI and CD initialize with `-lockfile=readonly`, so CD
  can no longer pick up an unreviewed provider build.

### Fixed

- The `maintenance_status` and `maintenance_window` outputs depend on the
  Worker script and route, so notifications that consume them are sent only
  after the Cloudflare changes in the same apply succeed.

- The rate limiting rule uses `expression = "true"` instead of a `matches`
  regex, which needs a Business or Enterprise plan.

## [3.0.0] - 2025-10-04

See the [v3.0.0 release](https://github.com/somethingwithproof/terraform-cloudflare-maintenance/releases/tag/v3.0.0).
