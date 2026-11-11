# Changelog

All notable changes to this module are documented here. The module uses
[Semantic Versioning](https://semver.org/); see
[CONTRIBUTING.md](CONTRIBUTING.md#versioning) for what counts as breaking.
From 4.0.0 on, release-please writes each entry from the Conventional Commit
titles merged since the previous release. What callers must change for each
major release is in [UPGRADING.md](UPGRADING.md).

## [4.0.0](https://github.com/somethingwithproof/terraform-cloudflare-maintenance/compare/v3.0.0...v4.0.0) (2026-11-10)


### ⚠ BREAKING CHANGES

* /__maintenance/status is answered by the Worker on routed hostnames; set status_path = "" to leave it to the origin.
* **worker:** /__maintenance/status is answered by the Worker on routed hostnames; set status_path = "" to leave it to the origin.
* **cd:** deploy each environment's own settings and never toggle on a tag ([#303](https://github.com/somethingwithproof/terraform-cloudflare-maintenance/issues/303))
* **notifications:** page only for active maintenance and resolve stale incidents ([#299](https://github.com/somethingwithproof/terraform-cloudflare-maintenance/issues/299))
* give each module instance its own Worker script ([#298](https://github.com/somethingwithproof/terraform-cloudflare-maintenance/issues/298))
* **cd:** the cloudflare_api_token variable is removed; callers must configure the Cloudflare provider themselves.
* **notifications:** notification_urls is a map(string) instead of a list, webhook:// targets must be HTTPS, and the null provider is no longer required.
* schedules is removed; a window now limits the page to that window even when enabled is true; maintenance_status reports SCHEDULED while a window is set.
* the ruleset_id, dns_record_id and maintenance_page_url outputs are removed, and the next apply deletes the bypass ruleset and the status DNS record.

### Features

* add a runtime toggle backed by Workers KV ([#311](https://github.com/somethingwithproof/terraform-cloudflare-maintenance/issues/311)) ([24bec3b](https://github.com/somethingwithproof/terraform-cloudflare-maintenance/commit/24bec3bb6091396bc410685628d8b4415acd5faf))
* add e2e/integration tests, CLAUDE.md, and test infrastructure ([b2d8351](https://github.com/somethingwithproof/terraform-cloudflare-maintenance/commit/b2d83515acd8165393964016b086b3258c9c0045))
* **cd:** deploy through HCP Terraform state and keep the module provider-free ([#297](https://github.com/somethingwithproof/terraform-cloudflare-maintenance/issues/297)) ([c6194fc](https://github.com/somethingwithproof/terraform-cloudflare-maintenance/commit/c6194fcdc0e1c5be5515104e13dcedc2d35af245))
* **ci:** add Dependabot auto-merge configuration ([04d51c5](https://github.com/somethingwithproof/terraform-cloudflare-maintenance/commit/04d51c5da43ffa1340664f6140415c283381cf45))
* migrate to OpenTofu ([4b2ed70](https://github.com/somethingwithproof/terraform-cloudflare-maintenance/commit/4b2ed7016cb2c720b4d7c34f0ac23a176a4cb7d0))
* **schedule:** add scheduled maintenance windows with notifications ([#187](https://github.com/somethingwithproof/terraform-cloudflare-maintenance/issues/187)) ([e7410a5](https://github.com/somethingwithproof/terraform-cloudflare-maintenance/commit/e7410a50728a542c102bf157a73045d6071d1452))
* serve the maintenance page only inside a scheduled window ([#293](https://github.com/somethingwithproof/terraform-cloudflare-maintenance/issues/293)) ([3b2ba76](https://github.com/somethingwithproof/terraform-cloudflare-maintenance/commit/3b2ba769ad02c3c7be021a940123284adf481cb2))
* **worker:** add a status endpoint, per-host and per-path pages, and HEAD ([#306](https://github.com/somethingwithproof/terraform-cloudflare-maintenance/issues/306)) ([fb4b455](https://github.com/somethingwithproof/terraform-cloudflare-maintenance/commit/fb4b455a5c455d8d2d67015a76cd282d3919a01a))
* **worker:** match allowed_ips as IPv4/IPv6 addresses and CIDR ranges ([#290](https://github.com/somethingwithproof/terraform-cloudflare-maintenance/issues/290)) ([09b552b](https://github.com/somethingwithproof/terraform-cloudflare-maintenance/commit/09b552b8fa1522ed446788417cdc91a92215f271))


### Bug Fixes

* align @vitest/coverage-v8 with vitest 4 and add a lockfile ([#275](https://github.com/somethingwithproof/terraform-cloudflare-maintenance/issues/275)) ([5bb903f](https://github.com/somethingwithproof/terraform-cloudflare-maintenance/commit/5bb903f212715e1a907b27f1d120f079913f1f8d))
* **cd:** deploy each environment's own settings and never toggle on a tag ([#303](https://github.com/somethingwithproof/terraform-cloudflare-maintenance/issues/303)) ([2f6e33e](https://github.com/somethingwithproof/terraform-cloudflare-maintenance/commit/2f6e33e091d754fd4514e9ed6f630bd6195aa969))
* **cd:** read the allowlists from environment secrets and keep them out of logs ([#323](https://github.com/somethingwithproof/terraform-cloudflare-maintenance/issues/323)) ([07471de](https://github.com/somethingwithproof/terraform-cloudflare-maintenance/commit/07471de79f5cf542c13cfc4bfd6a966612ea3021))
* **ci:** align Vitest 5, Node 24, and worker integration tests ([#268](https://github.com/somethingwithproof/terraform-cloudflare-maintenance/issues/268)) ([8262590](https://github.com/somethingwithproof/terraform-cloudflare-maintenance/commit/826259049f1c9a5adee18a1bceae3378c63f3aee))
* **ci:** limit dependabot auto-merge to passing patch/minor PRs ([#262](https://github.com/somethingwithproof/terraform-cloudflare-maintenance/issues/262)) ([e7b9956](https://github.com/somethingwithproof/terraform-cloudflare-maintenance/commit/e7b99568fa12a21523c76b4053786eeb1c7e63d6))
* **ci:** repair OpenTofu, worker test and CodeQL jobs after Actions re-enable ([#283](https://github.com/somethingwithproof/terraform-cloudflare-maintenance/issues/283)) ([5f8350c](https://github.com/somethingwithproof/terraform-cloudflare-maintenance/commit/5f8350cfba469d1b117f9ae8b6522de3032ae413))
* **ci:** use specific runner labels, fix codeql concurrency ([c8941d0](https://github.com/somethingwithproof/terraform-cloudflare-maintenance/commit/c8941d0c401470fc050cc84dd0cf82da5f848510))
* **ci:** use valid CodeQL concurrency context ([a846efa](https://github.com/somethingwithproof/terraform-cloudflare-maintenance/commit/a846efad20de77177a1822393f2a09db39ae92e7))
* **deploy:** commit the provider lock file and install from it read-only ([#302](https://github.com/somethingwithproof/terraform-cloudflare-maintenance/issues/302)) ([8922792](https://github.com/somethingwithproof/terraform-cloudflare-maintenance/commit/89227924a80b6c36b44b68756a09812d3471025f))
* **deps:** remove non-existent terraform blueprint paths from dependabot config ([4b3cf24](https://github.com/somethingwithproof/terraform-cloudflare-maintenance/commit/4b3cf24789655ee88edc5186cd6e91fe4a6f35ed))
* **deps:** require Cloudflare provider 5.19 and drop unused providers ([#289](https://github.com/somethingwithproof/terraform-cloudflare-maintenance/issues/289)) ([227c3a0](https://github.com/somethingwithproof/terraform-cloudflare-maintenance/commit/227c3a072f4821fd0b197deb087fac2e9828decc))
* **deps:** update vulnerable Go modules in the Terratest suite ([#305](https://github.com/somethingwithproof/terraform-cloudflare-maintenance/issues/305)) ([801ec55](https://github.com/somethingwithproof/terraform-cloudflare-maintenance/commit/801ec55645afc2a89fcd39ecc00c86039dbdf4d4))
* give each module instance its own Worker script ([#298](https://github.com/somethingwithproof/terraform-cloudflare-maintenance/issues/298)) ([1a30e04](https://github.com/somethingwithproof/terraform-cloudflare-maintenance/commit/1a30e04fff01736f38c8fb775acf078088da0f9a))
* **notifications:** keep notification secrets out of state and stop re-alerting ([#296](https://github.com/somethingwithproof/terraform-cloudflare-maintenance/issues/296)) ([eed12a3](https://github.com/somethingwithproof/terraform-cloudflare-maintenance/commit/eed12a318db14dc94be4a02df822cff89235fe95))
* **notifications:** page only for active maintenance and resolve stale incidents ([#299](https://github.com/somethingwithproof/terraform-cloudflare-maintenance/issues/299)) ([19ea973](https://github.com/somethingwithproof/terraform-cloudflare-maintenance/commit/19ea97337148c39028fedb1f26d80ace6f83b3f7))
* **notifications:** validate the notification URL in notify.sh ([#328](https://github.com/somethingwithproof/terraform-cloudflare-maintenance/issues/328)) ([1d2b149](https://github.com/somethingwithproof/terraform-cloudflare-maintenance/commit/1d2b1492e7124b45c47918cb27a82db2e868f63a))
* **security:** comprehensive security hardening ([#221](https://github.com/somethingwithproof/terraform-cloudflare-maintenance/issues/221)) ([0ba1440](https://github.com/somethingwithproof/terraform-cloudflare-maintenance/commit/0ba144099bf6d0c5041fe3031970b7344c680431))
* **security:** remediate 6 security findings across modules ([#225](https://github.com/somethingwithproof/terraform-cloudflare-maintenance/issues/225)) ([8685ba0](https://github.com/somethingwithproof/terraform-cloudflare-maintenance/commit/8685ba040b1155907ad17d4a2d94af16b76b6ff5))
* **security:** update golang.org/x/crypto and x/net to resolve CVEs ([#220](https://github.com/somethingwithproof/terraform-cloudflare-maintenance/issues/220)) ([9a23ca7](https://github.com/somethingwithproof/terraform-cloudflare-maintenance/commit/9a23ca70f053a6ee290f3a7e3cdb0fe1609e66fa))
* stop skipping the WAF for bypass traffic and drop the status DNS record ([#291](https://github.com/somethingwithproof/terraform-cloudflare-maintenance/issues/291)) ([3550450](https://github.com/somethingwithproof/terraform-cloudflare-maintenance/commit/35504509711fb6511b6219a861821186c6064af9))
* **toggle:** resolve the toggle's incident on schedule and share the apply's key ([#329](https://github.com/somethingwithproof/terraform-cloudflare-maintenance/issues/329)) ([0c1b302](https://github.com/somethingwithproof/terraform-cloudflare-maintenance/commit/0c1b3027882f3b006a466979977c6628cb6b0715))
* **toggle:** serve the page for on even with a Terraform window ([#321](https://github.com/somethingwithproof/terraform-cloudflare-maintenance/issues/321)) ([d93e004](https://github.com/somethingwithproof/terraform-cloudflare-maintenance/commit/d93e0049ea81ab6d2f2bfbe2797fffdab4e4691f))
* **toggle:** switch maintenance with a KV-only token ([#324](https://github.com/somethingwithproof/terraform-cloudflare-maintenance/issues/324)) ([56e251d](https://github.com/somethingwithproof/terraform-cloudflare-maintenance/commit/56e251d5522815856323a0d7c57b39a31fb56af3))
* validate allowed_ips with the grammar the Worker accepts ([#301](https://github.com/somethingwithproof/terraform-cloudflare-maintenance/issues/301)) ([8019957](https://github.com/somethingwithproof/terraform-cloudflare-maintenance/commit/80199576563b528c100cc2d6bfcd06cf14cf403b))
* **worker:** escape custom CSS, tighten the CSP and count Retry-After down ([#300](https://github.com/somethingwithproof/terraform-cloudflare-maintenance/issues/300)) ([122cf9a](https://github.com/somethingwithproof/terraform-cloudflare-maintenance/commit/122cf9a05d54c81029947400bf1bd9ba3965f48f))
* **worker:** fail open to the Terraform settings when the toggle cannot be read ([#322](https://github.com/somethingwithproof/terraform-cloudflare-maintenance/issues/322)) ([1a2b0f4](https://github.com/somethingwithproof/terraform-cloudflare-maintenance/commit/1a2b0f46944732f1cd9236b88d8fd2c102848ab7))

## [3.0.0] - 2025-10-04

See the [v3.0.0 release](https://github.com/somethingwithproof/terraform-cloudflare-maintenance/releases/tag/v3.0.0).
