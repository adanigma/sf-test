---
name: salesforce-configuring
description: "Configures Salesforce orgs including scratch org setup, permission sets, custom metadata, page layouts, demo data loading, and post-install steps. Use when the user needs org configuration, scratch org setup, permission assignment, or demo data."
---

# Salesforce Org Configuration

Metadata-first: deploy as source rather than clicking through Setup. Every step should be reproducible on any org. Correct dependency order: objects → fields → page layouts → permission sets.

## Scratch Org Setup

```bash
sf org create scratch \
  --definition-file config/project-scratch-def.json \
  --alias scratch-org \
  --duration-days 7 \
  --set-default \
  --target-dev-hub devhub
```

Create `config/project-scratch-def.json` if missing:
```json
{
  "orgName": "Appnigma Dev Org",
  "edition": "Developer",
  "features": ["EnableSetPasswordInApi"],
  "settings": {
    "lightningExperienceSettings": { "enableS1DesktopEnabled": true },
    "mobileSettings": { "enableS1EncryptedStoragePref2": false }
  }
}
```

## Permission Sets

Deploy as metadata in `force-app/main/default/permissionsets/`. Assign via:
```bash
sf org assign permset --name My_App_Admin --target-org scratch-org
```

## Custom Metadata

Deploy records in `force-app/main/default/customMetadata/`.

## Demo Data

```bash
sf apex run --target-org scratch-org --file scripts/seed-data.apex
```

For larger datasets: `sf data import tree --target-org scratch-org --plan data/sample-data-plan.json`

## Post-Install Configuration

For Setup UI steps without CLI/API path, use Playwright MCP tools (`mcp__playwright__browser_navigate`, `mcp__playwright__browser_snapshot`, `mcp__playwright__browser_click`, `mcp__playwright__browser_type`).

## Verification

```bash
sf org display --target-org scratch-org
sf data query --target-org scratch-org --query "SELECT Id, Name, Label FROM PermissionSet WHERE IsCustom = true"
```
