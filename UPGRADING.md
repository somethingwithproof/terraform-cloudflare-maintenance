# Upgrading

Steps for each major release. The [CHANGELOG](CHANGELOG.md) lists every
change; this file lists only what callers must do.

## 3.x to 4.0

Configuration:

- Configure the Cloudflare provider in your root module (for example from
  `CLOUDFLARE_API_TOKEN`) and remove the `cloudflare_api_token` argument;
  the module no longer has a provider block, so it now works with `count`,
  `for_each` and `depends_on`.
- Remove `schedules` from module calls; it was never acted on.
- `allowed_ips` rejects entries the Worker could never match: IPv4 octets
  with leading zeros (`010.0.0.1`) and IPv4-mapped IPv6 ranges shorter
  than `/96`. Fix or remove them; they matched nobody before either.
- Notifications module: `notification_urls` is now a sensitive
  `map(string)` of non-secret names to URLs, and `webhook://` targets must
  use HTTPS. Convert the list to a map, for example
  `{ oncall = "pagerduty://<routing key>" }`.

Behavior:

- The Worker is named `maintenance-page-<environment>` (variable
  `script_name`) instead of `maintenance-page-worker`. The next apply
  creates the new Worker, moves the route and deletes the old one. If
  several instances shared the old Worker, apply each of them. To keep the
  old name, set `script_name = "maintenance-page-worker"` in at most one
  instance per account.
- A `maintenance_window` now limits the page to that window even with
  `enabled = true`. To serve the page immediately, set `enabled = true` and
  leave `maintenance_window` unset. `maintenance_status` reports
  `SCHEDULED` whenever a window is set.
- The Worker answers `/__maintenance/status` with a JSON status document on
  every routed hostname. If your origin serves that path, set
  `status_path = ""`.
- The page's `Content-Type` is `text/html; charset=utf-8` and `HEAD` gets
  the 503 without a body.
- Notifications module: `SCHEDULED` no longer pages PagerDuty, and an open
  incident is resolved under its old key when the schedule or environment
  changes. Resolve incidents that an earlier release opened for
  `SCHEDULED` by hand.

Resources the next apply deletes:

- The `maintenance-bypass-<environment>` firewall ruleset, which skipped the
  WAF and rate limiting for bypass traffic (the `ruleset_id` output is
  gone). The Worker performs the bypass itself.
- The `maintenance-status-<environment>` DNS record (outputs
  `maintenance_page_url` and `dns_record_id` are gone); no route ever served
  it.
- The notifications module's `null_resource` entries; one notification per
  target is sent on that apply.

Requirements:

- Cloudflare provider `>= 5.19, < 6.0`. State from provider v4 upgrades
  automatically; see the README section on v4 state.

If you deploy with this repository's CD workflow:

- Move `TF_API_TOKEN` from a repository secret to each GitHub environment,
  scoped to that environment's HCP workspace.
- Set `MAINTENANCE_ENABLED`, `MAINTENANCE_WINDOW` and `CONTACT_EMAIL` as
  environment variables and `ALLOWED_IPS` and `ALLOWED_REGIONS` as
  environment secrets; a tag push deploys them unchanged instead of turning
  maintenance off.
