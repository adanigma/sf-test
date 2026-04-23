---
name: salesforce-reviewing-security
description: "Audits Salesforce managed packages for AppExchange Security Review compliance: CRUD/FLS enforcement, sharing model validation, SOQL injection prevention, XSS checks, and permission set auditing. Use when preparing for Security Review, running a security scan, or checking AppExchange readiness."
---

# Salesforce Security Review Prep

Every finding must be fixed before submitting to AppExchange.

## Step 1: Run Code Analyzer

```bash
sf scanner run --target force-app/ --format json --outfile /tmp/scan-results.json
```

Zero Critical and zero High findings required.

## Step 2: CRUD/FLS Enforcement

All SOQL must use `WITH USER_MODE`. All DML must use `AccessLevel.USER_MODE` or `as user`.

Search for violations:
```bash
grep -rn "FROM.*\]" force-app/ --include="*.cls" | grep -v "USER_MODE" | grep -v "@isTest"
grep -rn "^\s*insert\s\|^\s*update\s\|^\s*delete\s" force-app/ --include="*.cls" | grep -v "as user" | grep -v "Database\."
```

## Step 3: Sharing Model

Every class must declare `with sharing`, `without sharing`, or `inherited sharing`.

```bash
grep -rn "public class\|global class" force-app/ --include="*.cls" | grep -v "sharing" | grep -v "@isTest" | grep -v "enum\|interface"
```

## Step 4: SOQL Injection

No string concatenation in SOQL. Use bind variables or `String.escapeSingleQuotes()`.

## Step 5: XSS Prevention

- Visualforce: escape all `{! }` expressions
- LWC: safe by default, avoid `lwc:dom="manual"` with user content
- Aura: use `$A.util.sanitizeHtml()`

## Step 6: API Surface

Every `global` declaration must be intentional. Review all `@AuraEnabled` and `@InvocableMethod`.

## Step 7: Sensitive Data

No credentials in code. No PII in `System.debug()`. Use Named Credentials for secrets.

## Step 8: Permission Set Audit

Verify least privilege. No `viewAllRecords`/`modifyAllRecords` unless required.

## Report

Summarize all findings. Declare "Security Review Ready" only when all critical items pass.
