# Changelog

All notable changes to this module are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the module uses
[Semantic Versioning](https://semver.org/).

## [Unreleased]

### Breaking changes

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

- `allowed_ips` accepts IPv4 and IPv6 CIDR ranges, matches IPv6 addresses in
  any spelling and treats IPv4-mapped IPv6 as IPv4. Entries are validated at
  plan time.

### Fixed

- The rate limiting rule uses `expression = "true"` instead of a `matches`
  regex, which needs a Business or Enterprise plan.

## [3.0.0] - 2025-10-04

See the [v3.0.0 release](https://github.com/somethingwithproof/terraform-cloudflare-maintenance/releases/tag/v3.0.0).
