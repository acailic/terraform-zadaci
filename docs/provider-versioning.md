# Terraform Provider Versioning Guide

> A comprehensive reference for managing Terraform provider versions and dependencies

## Table of Contents

1. [Why Provider Versioning Matters](#1-why-provider-versioning-matters)
2. [Version Constraint Syntax](#2-version-constraint-syntax)
3. [Dependency Lock File](#3-dependency-lock-file-terraformlockhcl)
4. [Provider Configuration](#4-provider-configuration)
5. [Upgrade Workflows](#5-upgrade-workflows)
6. [Best Practices Checklist](#6-best-practices-checklist)

---

## 1. Why Provider Versioning Matters

Provider versioning is critical for maintaining stable, predictable infrastructure.

### Why It Matters

1. **Infrastructure Stability** - Pinning versions ensures your Terraform runs behave consistently across environments and over time.

2. **Breaking Changes** - Providers introduce breaking changes as they evolve. Without version constraints, `terraform init` may auto-upgrade to an incompatible version, causing unexpected failures.

3. **Security Updates** - Version constraints allow you to control when to adopt security patches, giving you time to test before deployment.

4. **Team Coordination** - Explicit versions ensure all team members work with the same provider versions, preventing "works on my machine" issues.

### Real-World Impact

```
# Without version constraint → surprises!
terraform init
# Upgrading: aws ~> 4.0 → 5.0 (breaking changes!)
terraform apply
# Error: resource argument renamed
```

## 2. Version Constraint Syntax

Terraform uses PEP 440-style version constraints in the `required_providers` block.

### Constraint Operators

| Operator | Meaning | Example | Matches |
|----------|---------|---------|---------|
| `=` | Exact version | `= 5.0.0` | 5.0.0 only |
| `~>` | Pessimistic (>= X.Y, < X.Y+1) | `~> 5.0` | 5.0.x, not 5.1+ |
| `~>` | Pessimistic (>= X, < X+1) | `~> 5` | 5.x, not 6+ |
| `>=` | Greater or equal | `>= 4.0` | 4.0, 4.1, 5.0... |
| `<=` | Less or equal | `<= 5.0` | ..., 4.9, 5.0 |
| `!=` | Not equal | `!= 4.0.0` | Everything except 4.0.0 |

### Pessimistic Version Constraint (~>)

The most commonly used operator:

```
~> 5.0.0  → accepts 5.0.0, 5.0.1, 5.0.2... (not 5.1.0)
~> 5.0    → accepts 5.0.x, 5.1.x, 5.2.x... (not 6.0.0)
~> 5      → accepts 5.x.x (not 6.0.0)
```

### Example from This Project

`versions.tf`:

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}
```

This configuration allows any AWS provider 6.x.x version (6.0.0 through 6.999.x) but will not auto-upgrade to version 7.0.0.

### Practical Guidance

- **Use `~>` for production** - Get patch/feature updates within a major version
- **Use `=` for critical pinning** - Exact version when maximum stability is needed
- **Avoid unconstrained** - Never omit `version` entirely

## 3. Dependency Lock File (.terraform.lock.hcl)

The `.terraform.lock.hcl` file records the exact provider versions selected for your workspace.

### Purpose

- **Deterministic** - Ensures `terraform init` selects the same versions every time
- **Team sync** - When committed to git, all team members use identical provider versions
- **Audit trail** - Shows exactly which versions are deployed

### Lock File Structure

From this project's `.terraform.lock.hcl`:

```hcl
# This file is maintained by Terraform and should not be edited manually
provider "registry.terraform.io/hashicorp/aws" {
  version     = "6.35.1"
  constraints = "~> 6.0"
  hashes = [
    "h1:xD+5zPhF0ry3sutriARfFVIg5m38VwYt66RveI3aUyI=",
    "zh:0a16d1b0ba9379e5c5295e6b3caa42f0b8ba6b9f0a7cc9dbe58c232cf995db2d",
  ]
}
```

Key fields:
- `version` - Exact version Terraform selected
- `constraints` - Version constraint from versions.tf
- `hashes` - Security checksums for integrity verification

### When to Commit to Git

**YES - Commit the lock file when:**
- Working in a team (ensures everyone uses same versions)
- Using CI/CD (reproduces same environment)
- Following Terraform best practices

**MAYBE - Skip commit when:**
- Local development only (rare)
- Multiple developer environments with intentionally different versions

### How Terraform Uses It

```
$ terraform init
- Reading lock file: .terraform.lock.hcl
- Found existing lock file with aws 6.35.1
- Constraint: ~> 6.0 → 6.35.1 is valid
- Using locked version
```

When running `terraform init -upgrade`, Terraform:
1. Checks for newer versions matching constraints
2. Updates `.terraform.lock.hcl` if new version found
3. Shows upgrade summary

### Security

The `hashes` array contains SHA256 checksums. Terraform verifies these after downloading providers to ensure integrity and authenticity.

## 4. Provider Configuration

The `required_providers` block defines which providers your configuration needs and where to find them.

### Basic Configuration

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
```

### Provider Source Format

`source = "[HOSTNAME]/NAMESPACE/NAME"`

| Source | Registry | Example |
|--------|----------|---------|
| `hashicorp/aws` | Terraform Registry (default) | Official AWS provider |
| `hashicorp/azurerm` | Terraform Registry | Official Azure provider |
| `integrations/github` | Terraform Registry | GitHub provider |
| `custom.corp/custom` | Private registry | Custom internal provider |

### version_constraint vs version Argument

**In `required_providers` block (versions.tf):**

```hcl
required_providers {
  aws = {
    version = "~> 5.0"  # ← CONSTRAINT: acceptable versions
  }
}
```

**In `provider` block (provider.tf):**

```hcl
provider "aws" {
  version = "5.76.0"    # ← DEPRECATED: use required_providers instead
  region  = var.aws_region
}
```

⚠️ **The `version` argument in provider blocks is deprecated.** Always specify versions in `required_providers`.

### Multiple Provider Instances (alias)

Use `alias` for multiple configurations of the same provider:

```hcl
provider "aws" {
  region  = "us-east-1"
  alias   = "east"
}

provider "aws" {
  region  = "eu-west-1"
  alias   = "west"
}

resource "aws_s3_bucket" "primary" {
  provider = aws.east
  # ...
}

resource "aws_s3_bucket" "replica" {
  provider = aws.west
  # ...
}
```

### From This Project

`versions.tf` specifies the constraint:

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}
```

`provider.tf` uses `assume_role` for secure access:

```hcl
provider "aws" {
  region  = var.aws_region

  assume_role {
    role_arn     = var.assume_role_arn
    session_name = "terraform-session"
  }

  default_tags {
    tags = var.default_tags
  }
}
```

This allows the terraform-user to assume TerraformAdminRole for resource management.

## 5. Upgrade Workflows

Upgrading providers requires careful planning to avoid breaking changes.

### Standard Upgrade

```bash
# 1. Check for available upgrades
terraform init -upgrade

# Output:
# - Upgrading hashicorp/aws from 6.35.1 to 6.50.0
# - .terraform.lock.hcl has been updated

# 2. Review the upgrade
cat .terraform.lock.hcl

# 3. Plan to see changes
terraform plan

# 4. If good, commit the lock file
git add .terraform.lock.hcl
git commit -m "chore: upgrade aws provider to 6.50.0"
```

### Safe Upgrade Workflow

For major version upgrades:

```bash
# 1. Read provider changelog
# Visit: https://github.com/hashicorp/terraform-provider-aws/blob/main/CHANGELOG.md

# 2. Test in a branch
git checkout -b upgrade-provider-v7

# 3. Update constraint in versions.tf
# Change: version = "~> 6.0"
# To:     version = "~> 7.0"

# 4. Upgrade and plan
terraform init -upgrade
terraform plan

# 5. Look for deprecation warnings and breaking changes
terraform plan 2>&1 | grep -i warning

# 6. Apply if safe
terraform apply

# 7. Commit both versions.tf and lock file
git add versions.tf .terraform.lock.hcl
git commit -m "chore: upgrade aws provider to v7"
```

### Rollback Strategy

If an upgrade breaks your infrastructure:

```bash
# 1. Revert both files
git checkout HEAD~1 -- versions.tf .terraform.lock.hcl

# 2. Re-initialize with old versions
rm -rf .terraform
terraform init

# 3. Verify
terraform plan
# Should show no provider-related changes
```

### Testing Before Production

- **Dev environment first** - Always test upgrades in non-production
- **terraform plan output** - Review all changes before apply
- **check mode** - Use `terraform apply -target=resource` for specific testing

## 6. Best Practices Checklist

<!-- TODO -->
