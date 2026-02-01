# Terraform Cloudflare Maintenance

## Purpose
Enterprise-grade maintenance mode solution for Cloudflare using OpenTofu and Cloudflare Workers.

## Stack
- OpenTofu >= 1.6.0 (HCL)
- Cloudflare provider >= 5.2
- Cloudflare Workers (JavaScript)

## Structure
- `main.tf`, `variables.tf`, `outputs.tf`, `versions.tf`, `backend.tf` - module root
- `modules/` - sub-modules
- `worker/` and `worker.js` - Cloudflare Worker source
- `tests/` - OpenTofu native tests
- `scripts/` - helper scripts
- `examples/` - usage examples

## Build & Test
```bash
tofu init
tofu validate
tofu test
tofu plan
```

## Standards
- OpenTofu preferred, native testing framework
- Tag all resources consistently
- Google Terraform Style Guide
- Secrets as sensitive variables, never in code
- Conventional Commits: `type(scope): description`

## Conventions
- IP allowlisting for bypass during maintenance
- Scheduled windows via RFC3339 timestamps or cron
- Slack/PagerDuty/webhook notification integrations
- Multi-environment support (prod, staging, dev)
