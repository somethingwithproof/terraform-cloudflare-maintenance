# Contributing to Terraform Cloudflare Maintenance

Thank you for considering contributing to this project! This document outlines the guidelines and workflows for contributing to the Terraform Cloudflare Maintenance module.

## Table of Contents

- [Contributing to Terraform Cloudflare Maintenance](#contributing-to-terraform-cloudflare-maintenance)
  - [Table of Contents](#table-of-contents)
  - [Code of Conduct](#code-of-conduct)
  - [Getting Started](#getting-started)
  - [Development Workflow](#development-workflow)
  - [Commit Conventions](#commit-conventions)
    - [Format](#format)
    - [Types and Emojis](#types-and-emojis)
    - [Examples](#examples)
  - [Pull Request Process](#pull-request-process)
  - [Testing Guidelines](#testing-guidelines)
    - [Worker Tests](#worker-tests)
    - [Terraform Tests](#terraform-tests)
    - [Pre-commit Checks](#pre-commit-checks)
  - [Documentation Guidelines](#documentation-guidelines)
  - [Release Process](#release-process)

## Code of Conduct

This project adheres to a Code of Conduct that expects all contributors to act with respect and professionalism. By participating, you are expected to uphold this code.

## Getting Started

1. Fork the repository on GitHub
2. Clone your fork locally
3. Add the original repository as a remote named "upstream"
4. Create a new branch for your changes

```bash
git clone https://github.com/YOUR-USERNAME/terraform-cloudflare-maintenance.git
cd terraform-cloudflare-maintenance
git remote add upstream https://github.com/thomasvincent/terraform-cloudflare-maintenance.git
git checkout -b feat/your-feature-name
```

## Development Workflow

1. Make sure your branch is up to date with the latest changes from upstream
2. Make your changes following the coding standards
3. Add tests for your changes
4. Update documentation as needed
5. Run tests locally to ensure everything passes
6. Commit your changes following the commit conventions
7. Push your changes to your fork
8. Submit a pull request

## Commit Conventions

This project uses Conventional Commits with emojis to make the commit history more readable and to automate versioning and changelog generation.

### Format

```
<type>[optional scope]: <description> <emoji>

[optional body]

[optional footer(s)]
```

### Types and Emojis

- `feat`: A new feature ✨
- `fix`: A bug fix 🐛
- `docs`: Documentation changes 📝
- `style`: Changes that do not affect code functionality (formatting, etc.) 🎨
- `refactor`: Code changes that neither fix bugs nor add features ♻️
- `test`: Adding or modifying tests 🧪
- `chore`: Changes to the build process or auxiliary tools 🔧
- `perf`: Performance improvements ⚡️
- `ci`: Changes to CI configuration files and scripts 👷
- `security`: Security-related changes 🔒

### Examples

```bash
git commit -m "feat(worker): add IP allowlisting functionality ✨"
git commit -m "fix(terraform): resolve edge case with maintenance window 🐛"
git commit -m "docs: update README with advanced examples 📝"
git commit -m "test(integration): add tests for firewall rules 🧪"
```

## Pull Request Process

1. Update the README.md or documentation with details of changes if appropriate
2. Make sure all tests pass and code quality checks succeed
3. The PR should work for all supported Terraform versions
4. Request review from maintainers
5. Address any feedback from reviewers
6. Once approved, a maintainer will merge your PR

## Testing Guidelines

### Worker Tests

- All worker code should have unit tests
- Run worker tests with `cd worker && npm test`
- Aim for 100% test coverage for critical paths

### Terraform Tests

- Integration tests should be written in Go using Terratest
- Run Terraform tests with `cd tests/integration && go test -v`
- Test all major features and configurations

### Pre-commit Checks

Before submitting a PR, run these checks locally:

```bash
# Format Terraform code
terraform fmt -recursive

# Validate Terraform code
terraform validate

# Lint Terraform code
tflint

# Run worker tests
cd worker && npm test

# Run integration tests
cd tests/integration && go test -v
```

## Documentation Guidelines

- Follow the [standard-readme](https://github.com/RichardLitt/standard-readme) specification
- Document all variables, outputs, and features
- Include examples for common use cases
- Keep the README.md up to date with the latest features
- Use proper Markdown formatting

## Release Process

Releases are managed by the maintainers and follow semantic versioning:

- MAJOR version for incompatible API changes
- MINOR version for backwards-compatible functionality additions
- PATCH version for backwards-compatible bug fixes

Thank you for contributing to the Terraform Cloudflare Maintenance module!
