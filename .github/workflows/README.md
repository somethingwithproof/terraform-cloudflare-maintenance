# GitHub Workflows

## CodeQL Configuration

The custom `codeql-analysis.yml` workflow has been disabled because this repository is using GitHub's default CodeQL setup. 

Having both the default CodeQL setup and a custom workflow causes conflicts during analysis. The default setup is preferred as it's maintained by GitHub and includes the latest security rules.

If you need to re-enable the custom workflow, rename `codeql-analysis.yml.disabled` back to `codeql-analysis.yml` and ensure the default CodeQL setup is disabled in the repository settings.