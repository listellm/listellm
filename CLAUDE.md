# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Purpose

Personal GitHub profile (`listellm/listellm`) combined with infrastructure for the `listell.co.uk` static holding page. The `README.md` at the repo root is rendered on the GitHub profile page.

## Infrastructure Overview

All Terraform lives in `infra/`. It provisions:

- **S3** — private origin bucket (`listell-co-uk-origin`), OAC-restricted
- **CloudFront** — distribution with HTTP/2+3, IPv6, TLS 1.2+, `PriceClass_100`
- **ACM** — certificate for `listell.co.uk` + `www.listell.co.uk`, provisioned in `us-east-1` (CloudFront requirement) via the `aws.us_east_1` provider alias
- **Route53** — A/AAAA alias records for apex and www, plus ACM DNS validation CNAMEs
- **State** — S3 backend (`listell-co-uk-terraform-state/holding-page/terraform.tfstate`, `eu-west-2`) with native S3 locking (`use_lockfile = true`)

Two AWS providers are required: the default (`eu-west-2`) and an alias `us_east_1` (`us-east-1`). The `us_east_1` alias must be passed explicitly to ACM resources.

No Terraform Cloud — state runs locally/in CI against S3.

## Commands

All Terraform commands run from `infra/`:

```bash
# Format check
terraform fmt -check -recursive

# Lint (tflint must be initialised first on a fresh checkout)
tflint --init --config=../.config/.tflint.hcl
tflint --recursive --config=../.config/.tflint.hcl

# Security scan
trivy config . --skip-dirs "**/.terraform" --ignorefile ../.config/.trivyignore
checkov -d . --config-file ../.config/.checkov.yaml

# Plan / Apply (requires AWS credentials)
terraform init
terraform validate
terraform plan
terraform apply
```

## CI/CD

GitHub Actions workflow (`.github/workflows/deploy-infra.yml`) triggers on `infra/**` changes:

- **PR** → lint → plan (plan output posted as PR comment)
- **Push to `main`** → lint → apply
- **`workflow_dispatch`** → supports optional `-target` flag (e.g. `-target=aws_cloudfront_distribution.listell`)

AWS auth is via OIDC (`listell-github-actions` IAM role). No Terraform Cloud involved.

## Linting & Security Config

Config files live in `.config/` (not `infra/`):

| File | Purpose |
|------|---------|
| `.config/.tflint.hcl` | tflint rules — snake_case naming, typed variables, pinned modules, unused declarations |
| `.config/.checkov.yaml` | Checkov skip-checks with rationale comments (bootstrap IAM role, holding-page overkill checks) |
| `.config/.trivyignore` | Trivy ignores for CloudFront/S3 checks inappropriate for a personal static page |

Do not suppress checkov/tflint/trivy findings without adding a documented rationale comment.

## Key Patterns

- **No variables file** — all configuration is in `locals.tf`; no `variables.tf` exists because this is a single-environment, single-account deployment
- **`imports.tf`** — all existing resources were bootstrapped manually and adopted into Terraform state; this file should be retained for reference but the imports are idempotent after the first `apply`
- **Implicit dependencies** — `aws_s3_bucket_policy` references `aws_s3_bucket_public_access_block.origin.bucket` (not `.id`) to ensure the policy is applied after the block; follow this pattern for ordering-sensitive resources
