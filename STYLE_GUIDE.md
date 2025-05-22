# Terraform Style Guide

This project follows Terraform best practices aligned with Google Cloud Platform conventions.

## Key Principles

### Code Formatting
- **Line Length**: 80 characters maximum
- **Indentation**: 2 spaces (no tabs)
- **Formatting**: Use `terraform fmt` for consistent formatting

### Tools
- **terraform fmt**: Automatic code formatting
- **terraform validate**: Syntax validation
- **tflint**: Advanced linting (if configured)

### Running Style Checks

```bash
# Format code recursively
terraform fmt -recursive .

# Check formatting without applying changes
terraform fmt -check -recursive .

# Validate syntax
terraform validate

# Run all checks
terraform fmt -check -recursive . && terraform validate
```

### Configuration Files
- `.editorconfig`: Editor settings

## File Organization

```
├── main.tf          # Main resource definitions
├── variables.tf     # Input variables
├── outputs.tf       # Output values
├── versions.tf      # Provider requirements
├── examples/        # Usage examples
├── tests/          # Tests
└── worker/         # Cloudflare Worker code
```

## Naming Conventions
- **Resources**: Use underscores, descriptive names
- **Variables**: Use underscores, clear descriptions
- **Files**: Use standard Terraform naming (main.tf, variables.tf, etc.)

## Multi-Language Support
This project includes:
- **Terraform**: Infrastructure as Code
- **JavaScript**: Cloudflare Worker functions (follows Google JS style)
- **Go**: Testing code (follows Google Go style)

## Integration

Style checks are integrated into:
- Pre-commit hooks
- CI/CD pipeline
- IDE/editor settings via `.editorconfig`