# Contributing

## Pull requests

- Branch from `main` and open a pull request; changes reach `main` only
  through squash merges once the required checks pass.
- Sign off every commit (`git commit -s`) to certify the
  [Developer Certificate of Origin](https://developercertificate.org/); the
  DCO check fails without it.
- Run the checks locally before pushing: `./scripts/run-tests.sh` runs the
  Worker and OpenTofu suites, and the README's Development section lists the
  build, lint and format commands.
- After changing `worker/src`, run `npm run build` in `worker/` and commit
  `worker/dist/index.js`; CI fails when the committed bundle is stale.
- After changing variables or outputs, run `terraform-docs .` and commit
  the README; CI fails when the generated tables are stale.

## Pull request titles

The squash commit takes the pull request title, and release-please computes
the next version from those commits, so titles must be
[Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/):

```text
type(optional-scope)!: summary in the imperative
```

Types: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`,
`ci`, `chore`, `revert`. Put `!` before the colon for a breaking change, and
describe what users must change in the pull request and in
[UPGRADING.md](UPGRADING.md).

## Versioning

Releases follow [Semantic Versioning 2.0.0](https://semver.org/). The version
lives in one place, `.release-please-manifest.json`, which release-please
updates together with `CHANGELOG.md` and the `?ref=` in the README examples.

| Release | When the merged commits include |
|---------|---------------------------------|
| Major (`X.0.0`) | a breaking change (`!` or a `BREAKING CHANGE:` footer) |
| Minor (`x.Y.0`) | a `feat` |
| Patch (`x.y.Z`) | only `fix`, `perf` or other changes users can observe as fixes |

A change is breaking when a caller that worked before must change to keep
working the same way:

- a variable or output is removed or renamed, or its type narrows;
- a default changes, or an input is newly validated more strictly;
- the module's behavior changes for the same inputs, for example which
  resources it creates, replaces or deletes, or when it serves the page;
- the Cloudflare provider or OpenTofu/Terraform version constraint drops a
  major version or raises its floor past what callers may run;
- the Worker's HTTP contract changes: status codes, headers, paths it
  answers itself (such as `status_path`), or the bindings it reads;
- the notifications module's inputs, outputs or delivered events change in
  the same ways.

New optional inputs and outputs, new paths that are off by default, and
fixes that make the module do what its documentation already said are not
breaking.

## Deprecation

When something will be removed or will change incompatibly:

1. Mark it deprecated in a minor release: say so in the variable or output
   description, emit a warning where OpenTofu allows (for example a
   `check` block), and name the replacement in the CHANGELOG and
   UPGRADING.md.
2. Keep it working for at least one further minor release.
3. Remove it in the next major release, listed under breaking changes with
   the steps to migrate.

Security fixes may skip this when keeping the old behavior would leave users
exposed; the release notes then say why.

## Registry

The repository already has the layout the Terraform and OpenTofu registries
expect: the `terraform-<provider>-<name>` repository name, a root module
with `main.tf`, `variables.tf`, `outputs.tf` and a README, `examples/`,
`modules/`, and `vX.Y.Z` tags. Publishing is a separate decision for the
owner: the Terraform registry publishes a GitHub repository from
registry.terraform.io, and the OpenTofu registry adds one through a pull
request or issue on `opentofu/registry`. Until then the README examples use
the `git::` source with `?ref=`, which release-please keeps on the latest
release.

## Releases

release-please keeps a release pull request open. Merging it tags `vX.Y.Z`,
creates the GitHub release and starts the `dev` deploy; only repository
administrators can create `v*` tags. Do not tag by hand.
