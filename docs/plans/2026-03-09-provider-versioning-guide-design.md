# Provider Versioning Guide — Design Document

**Date:** 2026-03-09
**Status:** Approved
**Output:** `docs/provider-versioning.md`

## Objective

Create a comprehensive reference guide for Terraform provider versioning as a learning resource for this project. The README notes "istraziti versionisanje providera" (explore provider versioning) as an open item.

## Target Audience

- Developers learning Terraform
- Users maintaining this terraform-zadaci project
- Anyone needing reference on provider versioning best practices

## Content Structure

1. **Why Provider Versioning Matters**
   - Infrastructure stability
   - Breaking changes awareness
   - Security updates

2. **Version Constraint Syntax**
   - Pessimistic version constraint (`~>`)
   - Exact (`=`), greater/less than (`>=`, `<=`)
   - Exclusion (`!=`), ranges
   - Practical examples using AWS provider

3. **Dependency Lock File (`.terraform.lock.hcl`)**
   - Purpose and contents
   - When to commit to git
   - How Terraform uses it
   - Analysis of this project's lock file

4. **Provider Configuration**
   - `required_providers` block
   - Provider sources (`hashicorp/aws`)
   - `version_constraint` vs `version` argument
   - Multiple providers with `alias`

5. **Upgrade Workflows**
   - `terraform init -upgrade`
   - Reviewing version changes
   - Testing before upgrading
   - Rollback strategies

6. **Best Practices Checklist**

## Design Decisions

1. **Use project artifacts as examples** — Reference actual `versions.tf` and `.terraform.lock.hcl` from this repo
2. **Include before/after comparisons** — Show effect of different constraint patterns
3. **Command output examples** — Real `terraform init` output demonstrating version selection
4. **Warning callouts** — Highlight risky operations like force upgrades

## Success Criteria

- Guide is clear and actionable
- All four selected topics are covered adequately
- Examples use this project's actual configuration where applicable
- Format is markdown, compatible with GitHub rendering
