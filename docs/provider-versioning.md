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

<!-- TODO -->

## 4. Provider Configuration

<!-- TODO -->

## 5. Upgrade Workflows

<!-- TODO -->

## 6. Best Practices Checklist

<!-- TODO -->
