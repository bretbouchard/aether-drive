# Test Secret Patterns - GitHub Secret Scanning

This document tracks test/placeholder secret patterns used in the codebase that have been explicitly allowed through GitHub's secret scanning.

## Overview

The White Room codebase includes security scanning tools that test for hardcoded secrets. To properly test these tools, we need example secret patterns. These are intentionally fake/test values that GitHub's secret scanning may flag.

## Allowed Test Patterns

The following patterns have been explicitly unblocked in GitHub secret scanning:

### Stripe API Keys
- **Pattern**: `sk_live_EXAMPLE_EXAMPLE_EXAMPLE_EXAMPLE`
- **Pattern**: `sk_test_EXAMPLE_EXAMPLE_EXAMPLE_EXAMPLE`
- **Location**: `swift_frontend/WhiteRoomiOS/Infrastructure/ComplianceScanner/SecretScanner.swift`
- **Purpose**: Test patterns for Stripe secret detection in SecretScanner
- **Unblock URLs**:
  - https://github.com/bretbouchard/aether-drive/security/secret-scanning/unblock-secret/38NFSv93uJidfbN6h6FvSV3HLG6

### Twilio Account Strings
- **Pattern**: `AC_EXAMPLE_EXAMPLE_EXAMPLE_EXAMPLE_EXAMPLE_`
- **Pattern**: `EXAMPLE_EXAMPLE_EXAMPLE_EXAMPLE_EXAMPLE_`
- **Location**: `swift_frontend/WhiteRoomiOS/Infrastructure/ComplianceScanner/SecretScanner.swift`
- **Purpose**: Test patterns for Twilio credential detection in SecretScanner
- **Unblock URLs**:
  - https://github.com/bretbouchard/aether-drive/security/secret-scanning/unblock-secret/38NFSrVZqjoRqhZfCTz5eCeWu1E

### Test Values in OWASPScannerTests
- **Pattern**: `sk_live_EXAMPLE_EXAMPLE_EXAMPLE_EXAMPLE`
- **Location**: `swift_frontend/WhiteRoomiOS/Infrastructure/ComplianceScannerTests/OWASPScannerTests.swift`
- **Purpose**: Unit test for API key detection
- **Unblock URLs**:
  - https://github.com/bretbouchard/aether-drive/security/secret-scanning/unblock-secret/38NFSqonw2LzAS6QmWimJMDjvo5

## Guidelines for Adding Test Patterns

When adding new test secret patterns:

1. **Use Obviously Fake Patterns**
   - Repeat "EXAMPLE" or "TEST" multiple times
   - Avoid patterns that look like real secrets
   - Use sequential patterns like `1234567890` or `abcdefghijk`

2. **Add False Positives**
   - Include the test pattern in the `falsePositives` array
   - This helps the scanner distinguish between tests and real secrets

3. **Add Clear Comments**
   ```swift
   // PLACEHOLDER - NOT REAL
   // These are test patterns for security scanner testing
   ```

4. **Document Here**
   - Add the pattern to this document
   - Include the GitHub unblock URL if secret scanning blocks the push

## Why These Patterns Are Safe

These test patterns are safe because:

1. **Obvious Fakes**: They contain repeated "EXAMPLE" strings that no real API key would have
2. **Documented**: They're clearly marked as test values in code
3. **Short Length**: Real API keys are typically longer and more random
4. **No Actual Access**: These patterns won't work with any real service
5. **GitHub Allowed**: They've been explicitly allowed through GitHub's secret scanning

## Related Documentation

- [SECURITY_FIXES.md](../../../SECURITY_FIXES.md) - Initial GitHub security alert investigation
- [DOCUMENTATION_GOVERNANCE.md](../../DOCUMENTATION_GOVERNANCE.md) - Documentation organization standards
- [SecretScanner.swift](../../../swift_frontend/WhiteRoomiOS/Infrastructure/ComplianceScanner/SecretScanner.swift) - Implementation

## History

- **2025-01-17**: Initial documentation of test patterns after GitHub secret scanning unblock
- **Commits**: a86790de, ab3a2509, 423629aa - Fixed test patterns to use obvious placeholders
