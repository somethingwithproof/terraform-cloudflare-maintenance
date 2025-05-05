# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [3.0.0] - 2025-05-03

### Added
- Terraform Cloud integration with backend.tf examples
- Support for IP ranges with CIDR notation
- Geographical region-based bypassing
- Multi-language support for maintenance pages
- Rate limiting for maintenance page to prevent abuse
- Environment-specific configurations (dev, staging, production)
- Extensive validation rules for input variables
- Comprehensive GitHub Actions workflow for CI/CD
- Complete test coverage with terraform test framework

### Changed
- Updated to use latest Cloudflare provider syntax
- Improved security posture with TFSec compliance
- Enhanced the worker script performance
- More detailed examples for different use cases
- Migrated from deprecated filter/firewall to rulesets

### Fixed
- Issues with worker bindings format
- IP allowlisting edge cases 
- DNS record configuration

## [2.0.0] - 2025-03-15

### Added
- Analytics engine binding for Cloudflare worker
- IP allowlisting feature
- Scheduled maintenance windows
- Custom CSS support
- Logo URL configuration

### Changed
- Upgraded to Terraform 1.7.0+
- Improved worker script architecture
- Enhanced test coverage

## [1.0.0] - 2025-01-10

### Added
- Initial release
- Basic maintenance page functionality
- Simple toggle to enable/disable
- Customizable maintenance title and contact email