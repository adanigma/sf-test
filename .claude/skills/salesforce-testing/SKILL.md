---
name: salesforce-testing
description: "Writes and improves Apex test classes to meet 75%+ code coverage with proper test patterns for 2GP managed packages. Use when writing tests, improving coverage, fixing test failures, or preparing for package version creation."
---

# Salesforce Apex Testing

## Coverage Requirements

- Package version creation: 75% minimum
- Target per class: 85%+ (buffer above threshold)
- Zero test failures before packaging

## Running Tests

```bash
sf apex run test --target-org scratch-org --code-coverage --result-format human --wait 15
```

## Test Class Structure

```apex
@isTest
private class MyHandlerTest {
    @TestSetup
    static void makeData() {
        // Shared test data — use TestDataFactory when available
    }

    @isTest
    static void testPositiveScenario() {
        Test.startTest();
        // Call method under test
        Test.stopTest();
        System.assertEquals(expected, actual, 'Description of what failed');
    }

    @isTest
    static void testNegativeScenario() {
        // Error handling, invalid inputs, edge cases
    }

    @isTest
    static void testBulkScenario() {
        // 200+ records to verify bulkification
    }
}
```

## Key Rules

- Never use `SeeAllData=true`
- Always wrap with `Test.startTest()` / `Test.stopTest()`
- No hardcoded IDs — create data dynamically
- Test all code paths: if/else, catch blocks, validation rules
- Use `System.assertEquals` with descriptive messages

## Improving Coverage

1. Identify uncovered lines via `--result-format json`
2. Prioritize: 0% classes first, then close-to-75% classes, then large classes
3. Cover: trigger handlers (insert/update/delete), service classes, batch/schedulable, REST endpoints
4. Hard-to-test: `HttpCalloutMock` for callouts, `Test.setMock()` for mocks, async executes after `Test.stopTest()`
