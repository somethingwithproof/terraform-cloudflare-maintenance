# Security Policy

## Supported versions

Security fixes are released for the latest major version. After a new major
release, the previous major gets fixes for critical issues for 90 days.

## Reporting a vulnerability

Report vulnerabilities privately through
[GitHub private vulnerability reporting](https://github.com/somethingwithproof/terraform-cloudflare-maintenance/security/advisories/new),
not in public issues or pull requests. Include the affected version, the
configuration involved and how to reproduce the problem.

You should get an acknowledgement within 5 business days. Fixes are
prepared privately and released with an advisory once a fixed version is
available.

## Scope

In scope: the OpenTofu module and the notifications module, the Worker
(`worker/`), `scripts/maintenance`, and this repository's workflows.

Out of scope: Cloudflare's platform and the providers this module uses;
report those to their maintainers.
