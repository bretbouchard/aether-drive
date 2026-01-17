# White Room CI/CD & QA Dashboard Infrastructure

Complete automated testing infrastructure with quality gates, reporting, and notifications.

## 📁 Structure

```
.github/workflows/
├── test-suite-complete.yml    # Complete test suite workflow
└── notify.yml                   # Notification workflows

Scripts/
├── aggregate-test-results.sh   # Test result aggregation
├── run-all-tests.sh            # Run complete test suite locally
├── generate-coverage-report.sh # Coverage report generation
└── compare-snapshots.sh        # Visual regression testing

Infrastructure/QADashboard/
├── TestSummary.swift           # Test result data model
├── QualityGate.swift           # Quality gate enforcement
├── DashboardMetrics.swift      # Dashboard metrics provider
├── DailyTestReport.swift       # Daily report generator
└── README.md                   # This file

TestReports/
├── aggregate-report.json       # Aggregated test results
└── Coverage/                   # Coverage reports
```

## 🚀 Quick Start

### Run Complete Test Suite Locally

```bash
# Run all tests
./Scripts/run-all-tests.sh

# Run with options
./Scripts/run-all-tests.sh --skip-build
./Scripts/run-all-tests.sh --coverage-only

# View results
cat TestReports/aggregate-report.json
```

### Generate Coverage Report

```bash
./Scripts/generate-coverage-report.sh

# View report
cat TestReports/Coverage/coverage-summary.md
```

### Run Visual Regression Tests

```bash
# Ensure ImageMagick is installed
brew install imagemagick

# Run comparison
./Scripts/compare-snapshots.sh
```

## 🔧 GitHub Actions Workflows

### Complete Test Suite

Triggered on:
- Push to `main` or `develop`
- Pull requests
- Daily at 2 AM UTC
- Manual workflow dispatch

Jobs:
1. **SDK Tests** - TypeScript unit tests, coverage, linting
2. **iOS Tests** - iOS unit tests, Swift SDK tests
3. **tvOS Tests** - tvOS tests
4. **Snapshot Tests** - Visual regression detection
5. **Accessibility Tests** - Accessibility validation
6. **Performance Tests** - Performance regression detection
7. **Security Scan** - Snyk, npm audit, CodeQL
8. **Telemetry Check** - Telemetry and crash reporting validation
9. **Aggregate Results** - Combine all test results
10. **Quality Gate** - Enforce quality thresholds

### Notifications

- **Slack** - Real-time notifications for test failures
- **Email** - Email alerts for critical failures
- **GitHub Summary** - Test results in PR/commit summaries

## 📊 Quality Scoring

### Overall Quality Score Calculation

```
Total Score = 100 points

- SDK Coverage:        30 points (coverage% × 0.3)
- iOS Tests:           25 points (pass rate × 0.25)
- tvOS Tests:           5 points (pass rate × 0.05)
- Accessibility:       15 points (minus 2 per error)
- Performance:         10 points (minus 2 per regression)
- Visual:              10 points (minus 2 per regression)
- Security:             5 points (minus 1 per vulnerability)
```

### Grade Scale

- **A+** (95-100): Excellent
- **A** (90-94): Very Good
- **B+** (85-89): Good
- **B** (80-84): Acceptable
- **C** (75-79): Needs Improvement
- **F** (<75): Fail

## 🚦 Quality Gates

### Pre-Merge Gates

- ✅ All iOS tests passing (0 failures)
- ✅ SDK coverage ≥ 80%
- ✅ No accessibility errors
- ✅ No performance regressions
- ✅ No visual regressions
- ✅ Overall score ≥ 75%

### Pre-Release Gates

All pre-merge requirements PLUS:

- ✅ SDK coverage ≥ 85%
- ✅ Crash-free users ≥ 99%
- ✅ No security vulnerabilities
- ✅ Overall score ≥ 85%

## 📈 Dashboard Metrics

### Tracked Metrics

**Coverage:**
- SDK code coverage
- Swift SDK coverage
- iOS test coverage

**Tests:**
- iOS test pass rate
- tvOS test pass rate
- Total test count
- Failure breakdown

**Quality:**
- Accessibility errors/warnings
- Performance regressions
- Visual regressions
- Security vulnerabilities

**Telemetry:**
- Crash-free user percentage
- Active sessions
- Error rates

**Trends:**
- Coverage trajectory
- Test pass rate changes
- Quality issue trends
- Score progression

### Alerts

Dashboard generates alerts for:

- 🚨 **Critical**: Security vulnerabilities
- ❌ **Error**: Test failures, performance regressions
- ⚠️ **Warning**: Low coverage, accessibility issues, visual regressions

## 📝 Daily Test Reports

### Generate Report

```swift
import Foundation

let report = DailyTestReport()
let markdown = report.generate()
print(markdown)

// Save to file
try report.save(to: URL(fileURLWithPath: "/path/to/report.md"))
```

### Report Contents

- Overall score and grade
- Coverage breakdown
- Test results
- Quality metrics
- Telemetry data
- Quality gate status
- Trends (if historical data available)
- Actionable recommendations

## 🔐 Secrets Configuration

### Required Secrets

```bash
# Slack notifications
SLACK_WEBHOOK=https://hooks.slack.com/services/YOUR/WEBHOOK/URL

# Email notifications
EMAIL_USERNAME=your-email@gmail.com
EMAIL_PASSWORD=your-app-password
NOTIFICATION_EMAIL=team@example.com

# Codecov (optional)
CODECOV_TOKEN=your-codecov-token

# Snyk (optional)
SNYK_TOKEN=your-snyk-token
```

### Setup Instructions

```bash
# Install GitHub CLI
brew install gh

# Authenticate
gh auth login

# Add secrets
gh secret set SLACK_WEBHOOK
gh secret set EMAIL_USERNAME
gh secret set EMAIL_PASSWORD
gh secret set NOTIFICATION_EMAIL
```

## 🛠️ Development

### Adding New Test Types

1. Add test job to `test-suite-complete.yml`
2. Add result aggregation to `aggregate-test-results.sh`
3. Update scoring weights if needed
4. Add quality gate criteria

### Modifying Quality Gates

Edit `QualityGate.swift`:

```swift
public func validatePreMerge(summary: TestSummary) -> GateResult {
    var failures: [String] = []

    // Add your custom checks here
    if summary.customMetric < threshold {
        failures.append("Custom metric below threshold")
    }

    return failures.isEmpty ? .pass : .fail(reasons: failures)
}
```

### Custom Dashboard Metrics

Extend `DashboardMetrics.swift`:

```swift
public func generateCustomMetrics() -> CustomMetrics {
    // Add your custom metrics calculation
    return CustomMetrics(...)
}
```

## 📦 Dependencies

### Required

- **Node.js** 20+ (SDK tests)
- **Xcode** 15.0+ (iOS/tvOS tests)
- **ImageMagick** (Visual regression tests)
- **jq** (JSON parsing in scripts)

### Optional

- **Snyk** (Security scanning)
- **Codecov** (Coverage reporting)
- **Homebrew** (Package management)

### Installation

```bash
# Install dependencies
brew install imagemagick jq

# Install Node.js dependencies
cd sdk && npm install

# Resolve Swift packages
cd juce_backend/sdk/packages/swift
swift package resolve
```

## 🔄 CI/CD Pipeline Flow

```
1. Push/PR Trigger
   ↓
2. Run Test Suite (parallel)
   ├── SDK Tests (lint, type-check, unit tests, coverage)
   ├── iOS Tests (unit, UI)
   ├── tvOS Tests
   ├── Snapshot Tests
   ├── Accessibility Tests
   ├── Performance Tests
   ├── Security Scan
   └── Telemetry Check
   ↓
3. Aggregate Results
   └── Combine all test results
   ↓
4. Calculate Score
   └── Apply scoring weights
   ↓
5. Quality Gate Check
   ├── Pre-Merge validation
   └── Pre-Release validation
   ↓
6. Generate Reports
   ├── Aggregate report (JSON)
   ├── Daily report (Markdown)
   └── Dashboard metrics
   ↓
7. Send Notifications
   ├── Slack (failure/success)
   ├── Email (failure)
   └── GitHub Summary
   ↓
8. Enforce Gates
   ├── Block merge if failed
   └── Block release if failed
```

## 📚 Documentation

- [Test Coverage Guide](#test-coverage-guide)
- [Quality Gate Reference](#quality-gate-reference)
- [Dashboard API](#dashboard-api)
- [Troubleshooting](#troubleshooting)

### Test Coverage Guide

**SDK Coverage:**
- Uses `istanbul`/`nyc` for JavaScript/TypeScript
- Reports in `lcov` format
- Target: 80% (pre-merge), 85% (pre-release)

**Swift Coverage:**
- Uses `llvm-cov` for Swift
- Exports to JSON and lcov formats
- Integrated with Xcode test results

**iOS Coverage:**
- Uses `xccov` for Xcode test results
- Generates coverage from `.xcresult` bundles

### Quality Gate Reference

**Pre-Merge Criteria:**
- All tests must pass
- SDK coverage ≥ 80%
- No accessibility errors
- No performance regressions
- No visual regressions
- Overall score ≥ 75%

**Pre-Release Criteria:**
- All pre-merge criteria
- SDK coverage ≥ 85%
- Crash-free users ≥ 99%
- No security vulnerabilities
- Overall score ≥ 85%

### Dashboard API

**Load Latest Summary:**
```swift
let summary = TestSummary.load(from: url)
print(summary.overallScore)
print(summary.grade)
```

**Check Quality Gates:**
```swift
let gate = QualityGate.shared
if gate.enforce(summary: summary, level: .preMerge) {
    print("Ready to merge!")
} else {
    print("Fix issues first")
}
```

**Generate Dashboard:**
```swift
let metrics = DashboardMetrics.shared
let dashboard = metrics.generateDashboard()
print(dashboard.markdown)
```

### Troubleshooting

**Tests failing locally but passing in CI:**
- Check for environment differences
- Verify all dependencies installed
- Check for platform-specific tests

**Coverage not generating:**
- Ensure test framework configured for coverage
- Check for conflicting coverage settings
- Verify output paths exist

**Quality gates failing unexpectedly:**
- Check `TestReports/aggregate-report.json` for details
- Verify scoring weights are correct
- Review individual test results

**Notifications not sending:**
- Verify secrets are configured
- Check webhook URLs are valid
- Test webhook with sample payload

## 🤝 Contributing

When adding new tests or metrics:

1. Update `test-suite-complete.yml`
2. Modify `aggregate-test-results.sh`
3. Update scoring weights if needed
4. Add quality gate criteria
5. Update this README

## 📞 Support

For issues or questions:

1. Check existing issues in repository
2. Review test logs in GitHub Actions
3. Check `TestReports/` for detailed results
4. Contact DevOps team

## 📄 License

Part of the White Room project. See main repository LICENSE.
