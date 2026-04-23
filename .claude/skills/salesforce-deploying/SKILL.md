---
name: salesforce-deploying
description: "Deploys Salesforce 2GP managed packages through a strict sequential pipeline: scratch org provisioning, source deployment with error recovery, Apex test execution, package version creation, and PR creation. Use when the user asks to deploy, build, package, push to Salesforce, or release their code."
---

# Salesforce 2GP Deployment Pipeline

CRITICAL: This is a strict sequential pipeline. Execute every step in order. Do NOT skip any step. If a step fails, fix and retry — do not move on without completing it.

## Prerequisites

Verify ALL of these before starting. If any fail, stop and tell the user:
1. Salesforce DX project exists (check for `sfdx-project.json`)
2. DevHub is authenticated: `sf org list` should show `devhub` alias
3. You are on the correct agent branch (check `agent_branch` from `<session_context>`)

## Step 1: Verify Working Branch

```bash
git branch --show-current
```

Must match `agent_branch` from `<session_context>`. If not, run `git checkout <agent_branch>`.

## Step 2: Get or Create Scratch Org

Try these approaches in order. Move to the next only if the previous fails.

### 2a. Check our database first
Call `mcp__backend__get_active_scratch_org` with `companyId` and `packageId`.
- If found with `authUrl`: authenticate via `sf org login access-token --instance-url <authUrl> --no-prompt --alias scratch-org`
- If found with `username` but no `authUrl`: try DevHub re-auth via `sf org login scratch --target-dev-hub devhub --username <username> --alias scratch-org --no-prompt`
- If authentication succeeds, proceed to Step 3.

### 2b. Create a new scratch org
If no usable org in our database:
- Create: `sf org create scratch --definition-file config/project-scratch-def.json --alias scratch-org --duration-days 7 --set-default --target-dev-hub devhub`
- If creation fails (e.g. active scratch org limit reached), go to 2c.
- If creation succeeds, get org details: `sf org display --target-org scratch-org --json`
- Register with ALL fields via `mcp__backend__register_scratch_org`: `packageId`, `sfOrgId` (result.id), `username` (result.username), `instanceUrl` (result.instanceUrl), `authUrl` (result.sfdxAuthUrl), `expirationDate` (result.expirationDate). The `authUrl` is REQUIRED for reuse.

### 2c. Find existing scratch org via DevHub
If creation failed, check the DevHub for existing scratch orgs:
```bash
sf org list --all --json
```
Look for active scratch orgs in the output. Pick the most recently created one:
```bash
sf org login scratch --target-dev-hub devhub --username <username> --alias scratch-org --no-prompt
```
Register it in our database via `mcp__backend__register_scratch_org` with all fields including `authUrl` from `sf org display --target-org scratch-org --json`.

## Step 3: Deploy to Scratch Org

```bash
sf project deploy start --target-org scratch-org --wait 30
```

If deployment fails: read errors, fix code, commit fix, retry. Max 5 attempts.

Do NOT proceed until deployment succeeds.

## Step 4: Run Tests (do NOT skip)

```bash
sf apex run test --target-org scratch-org --code-coverage --result-format human --wait 15
```

If coverage < 75%: write/improve tests, redeploy, rerun. If tests fail: fix and rerun.

Do NOT proceed until all tests pass with >= 75% coverage.

## Step 5: Create Package Version (do NOT skip)

### CRITICAL: Package name matching rules

The project name in `sfdx-project.json` (`name` field) is the source of truth. The DevHub may contain OTHER packages from OTHER projects — they are IRRELEVANT. Never use a package from the DevHub that doesn't match this project's name.

### Procedure

1. Read `sfdx-project.json`:
   - Get the project name from the `name` field
   - Check if `packageDirectories[].package` exists (the package name for this project)
   - Check `packageAliases` for a package ID (starts with `0Ho`)

2. If `packageDirectories[].package` and `packageAliases` both exist — the project already has a package configured. Use it.

3. If no package is configured for this project:
   - Check if a package with the SAME name as the project exists in the DevHub: `sf package list --target-dev-hub devhub`
   - If a matching package exists — wire it up in `sfdx-project.json`
   - If NO matching package exists — create a new one with the project name:
     ```bash
     sf package create --name "[project name from sfdx-project.json]" --package-type Managed --path force-app --target-dev-hub devhub
     ```
   - **NEVER use an existing package with a DIFFERENT name.** Other packages in the DevHub belong to other projects. Using them would corrupt both projects.
   - After creating or finding the package, persist the `0Ho...` Package ID to our database by calling `mcp__backend__update_package_field` with:
     - `packageId` — from `<session_context>` or `appnigma.yaml`
     - `field` — `"sfPackageId"`
     - `value` — the `0Ho...` Package ID
     
     This is write-once — if already set, the call succeeds silently.

4. Create the version:
   ```bash
   sf package version create --package "[Package Name]" --installation-key-bypass --wait 30 --target-dev-hub devhub --code-coverage
   ```

Do NOT proceed until package version is created.

5. Register the version: parse the output from `sf package version create` (use `--json` if needed) and call `mcp__backend__register_package_version` with:
   - `packageId` — from `<session_context>` or `appnigma.yaml`
   - `sfVersionId` — MUST be the `SubscriberPackageVersionId` which starts with `04t`. Do NOT use the `PackageVersionCreateRequestId` (starts with `08c`) or the `Package2VersionId` (starts with `05i`). If the create output doesn't include the `04t` ID directly, run `sf package version list --packages <packageName> --target-dev-hub devhub --json` and find it there.
   - `versionNumber` — the version number from the create output (e.g. `1.2.0.1`)
   - `installUrl` — construct as `https://login.salesforce.com/packaging/installPackage.apexp?p0=<04t SubscriberPackageVersionId>`
   - `status` — `"beta"` (unless you promoted it)
   - `codeCoverage` — the code coverage percentage from Step 4
   - `gitCommit` — result of `git rev-parse HEAD`
   - `gitCommitMessage` — result of `git log -1 --format=%s`
   - `source` — `"manual"`

## Step 6: Commit, Push, and Create PR

```bash
git add .
git commit -m "Deploy: [brief description]"
git push -u origin HEAD
gh pr create --base main --title "Deploy: [description]" --body "## Changes
[list]

## Test Results
- Coverage: [X]%
- All tests passing

## Package Version
- Version: [number]
- Install URL: [URL]

---
Deployed by Appnigma AI"
```

## Step 7: Report Results

Tell the user ALL of: PR link, package install URL, coverage percentage, summary of changes and fixes.
