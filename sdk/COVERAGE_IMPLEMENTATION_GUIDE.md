# Test Coverage Implementation Guide

**Purpose**: Step-by-step guide for implementing test coverage improvements to achieve 85% coverage
**Target**: Schillinger SDK (white_room)
**Current Coverage**: 40-50%
**Target Coverage**: 85%
**Issue**: white_room-454

## Quick Start

### Phase 1: Run Coverage Baseline (5 minutes)

```bash
cd /Users/bretbouchard/apps/schill/white_room/sdk
npm run test:coverage
```

This generates coverage reports in `sdk/coverage/` directory.

### Phase 2: Review Coverage Report (10 minutes)

Open `sdk/coverage/index.html` in a browser to see detailed coverage by file.

**Key Metrics to Review**:
- Overall coverage percentage
- Files with lowest coverage (red indicators)
- Uncovered branches (yellow indicators)
- Uncovered lines (red indicators)

### Phase 3: Implement Quick Wins (2-3 hours)

Follow the examples in `client-coverage-improvements.test.ts` to add:
1. Error handling tests
2. Edge case tests
3. Configuration validation tests
4. Network failure scenarios

### Phase 4: Add Property-Based Tests (3-4 hours)

Follow the examples in `coverage-improvements-property.test.ts` to add:
1. Invariant tests for data transformations
2. Mathematical property tests
3. Serialization round-trip tests
4. Boundary condition tests

## Implementation Strategy

### Priority 1: Critical Path Tests (Week 1)

**Files to Focus On**:
- `core/src/client.ts` - SDK client initialization and configuration
- `core/src/composition.ts` - Composition API
- `packages/shared/src/auth/` - Authentication and authorization
- `packages/gateway/src/` - Network layer

**Test Categories**:

#### 1. Authentication Error Scenarios
```typescript
// Test file: core/src/auth-coverage.test.ts

describe('Authentication Error Scenarios', () => {
  it('should handle invalid API key format', async () => {
    const client = new SchillingerSDK({
      apiKey: 'invalid-format',
      apiUrl: 'http://localhost:3000/api/v1'
    });

    await expect(client.authenticate()).rejects.toThrow(/Invalid API key format/);
  });

  it('should handle expired authentication token', async () => {
    const client = new SchillingerSDK({
      apiKey: 'test-key',
      apiUrl: 'http://localhost:3000/api/v1',
      autoRefreshToken: true
    });

    // Mock token as expired
    vi.spyOn(client['authManager'], 'isTokenExpired').mockReturnValue(true);

    await client.authenticate();

    expect(client['authManager'].refreshToken).toHaveBeenCalled();
  });

  it('should handle authentication timeout', async () => {
    const client = new SchillingerSDK({
      apiKey: 'test-key',
      apiUrl: 'http://localhost:3000/api/v1',
      timeout: 1 // 1ms to trigger timeout
    });

    await expect(client.authenticate()).rejects.toThrow(/timeout/i);
  });
});
```

#### 2. Client Configuration Validation
```typescript
// Test file: core/src/config-validation.test.ts

describe('Client Configuration Validation', () => {
  it('should reject missing apiUrl', () => {
    expect(() => {
      new SchillingerSDK({ apiKey: 'test-key' } as any);
    }).toThrow(/apiUrl is required/);
  });

  it('should reject invalid timeout value', () => {
    expect(() => {
      new SchillingerSDK({
        apiKey: 'test-key',
        apiUrl: 'http://localhost:3000/api/v1',
        timeout: -100 // Negative timeout
      });
    }).toThrow(/timeout must be positive/);
  });

  it('should enforce HTTPS in production', () => {
    expect(() => {
      new SchillingerSDK({
        apiKey: 'test-key',
        apiUrl: 'http://insecure.com/api/v1',
        environment: 'production'
      });
    }).toThrow(/HTTPS required in production/);
  });
});
```

#### 3. Network Error Recovery
```typescript
// Test file: core/src/network-error-recovery.test.ts

describe('Network Error Recovery', () => {
  it('should retry failed requests with exponential backoff', async () => {
    const client = new SchillingerSDK({
      apiKey: 'test-key',
      apiUrl: 'http://localhost:3000/api/v1',
      retries: 3
    });

    // Mock network failure then success
    vi.spyOn(client['httpClient'], 'get')
      .mockRejectedValueOnce(new Error('Network error'))
      .mockResolvedValueOnce({ data: { success: true } });

    const response = await client.makeRequest('/test');
    expect(response.data.success).toBe(true);
  });

  it('should handle rate limiting (429) with retry-after', async () => {
    const client = new SchillingerSDK({
      apiKey: 'test-key',
      apiUrl: 'http://localhost:3000/api/v1'
    });

    // Mock rate limit response
    vi.spyOn(client['httpClient'], 'get')
      .mockRejectedValueOnce({
        statusCode: 429,
        headers: { 'retry-after': '2' }
      })
      .mockResolvedValueOnce({ data: { success: true } });

    const response = await client.makeRequest('/test');
    expect(response.data.success).toBe(true);
  });
});
```

#### 4. Cache Failure Scenarios
```typescript
// Test file: core/src/cache-failures.test.ts

describe('Cache Failure Scenarios', () => {
  it('should handle cache write failures gracefully', async () => {
    const client = new SchillingerSDK({
      apiKey: 'test-key',
      apiUrl: 'http://localhost:3000/api/v1',
      cacheEnabled: true
    });

    // Mock cache write failure
    vi.spyOn(client['cacheManager'], 'set').mockRejectedValue(
      new Error('Cache write failed')
    );

    // Should still succeed despite cache failure
    await client.authenticate();
    expect(client.isAuthenticated).toBe(true);
  });

  it('should handle cache corruption (clear and rebuild)', async () => {
    const client = new SchillingerSDK({
      apiKey: 'test-key',
      apiUrl: 'http://localhost:3000/api/v1',
      cacheEnabled: true
    });

    // Mock corrupted cache data
    vi.spyOn(client['cacheManager'], 'get').mockResolvedValue(
      'corrupted-data{not-valid-json}'
    );

    // Should handle corruption and fallback to network
    const result = await client.makeRequest('/test');
    expect(result).toBeDefined();
  });
});
```

### Priority 2: Property-Based Tests (Week 2)

**Files to Focus On**:
- `packages/shared/src/math.ts` - Mathematical operations
- `packages/analysis/src/` - Music analysis algorithms
- `packages/generation/src/` - Music generation algorithms

**Installation**:
```bash
npm install --save-dev fast-check
```

#### Example: Rhythm Transformation Properties
```typescript
// Test file: packages/shared/src/__tests__/rhythm-properties.test.ts

import fc from 'fast-check';
import { augmentRhythm, diminishRhythm, retrogradeRhythm } from '../rhythm';

describe('Rhythm Transformation Properties', () => {
  it('should preserve total duration when augmenting rhythm', () => {
    fc.property(
      fc.array(fc.integer({ min: 1, max: 100 }), { min: 1, max: 20 }),
      fc.integer({ min: 2, max: 8 }),
      (rhythm, factor) => {
        const originalDuration = rhythm.reduce((sum, val) => sum + val, 0);
        const augmented = augmentRhythm(rhythm, factor);
        const augmentedDuration = augmented.reduce((sum, val) => sum + val, 0);

        return Math.abs(augmentedDuration - originalDuration * factor) < 0.01;
      }
    ).check();
  });

  it('should be idempotent for retrograde operation', () => {
    fc.property(
      fc.array(fc.integer({ min: 1, max: 100 }), { min: 1, max: 20 }),
      (rhythm) => {
        const once = retrogradeRhythm(rhythm);
        const twice = retrogradeRhythm(once);

        expect(twice).toEqual(rhythm);
        return true;
      }
    ).check();
  });
});
```

#### Example: Serialization Properties
```typescript
// Test file: packages/shared/src/__tests__/serialization-properties.test.ts

import fc from 'fast-check';
import { serializeSongIR, deserializeSongIR } from '../ir-serialization';

describe('Serialization Properties', () => {
  it('should round-trip SongIR serialization', () => {
    fc.property(
      fc.record({
        id: fc.uuid(),
        seed: fc.integer({ min: 1, max: 1000000 }),
        title: fc.string(),
        tempo: fc.integer({ min: 60, max: 200 }),
        timeSignature: fc.constantFrom(
          { numerator: 4, denominator: 4 },
          { numerator: 3, denominator: 4 }
        )
      }),
      (songIR) => {
        const serialized = serializeSongIR(songIR);
        const deserialized = deserializeSongIR(serialized);

        expect(deserialized).toEqual(songIR);
        return true;
      }
    ).check();
  });
});
```

### Priority 3: Edge Cases and Boundary Conditions (Week 3)

**Files to Focus On**:
- All core SDK files
- Analysis algorithms
- Generation algorithms

#### Test Categories:

1. **Empty Inputs**
```typescript
it('should handle empty arrays', () => {
  expect(() => processRhythm([])).not.toThrow();
  expect(() => analyzeMelody([])).not.toThrow();
});
```

2. **Extreme Values**
```typescript
it('should handle very large inputs', () => {
  const largeArray = Array(100000).fill(100);
  expect(() => processRhythm(largeArray)).not.toThrow();
});

it('should handle boundary values', () => {
  expect(() => setTempo(40)).not.toThrow(); // Minimum
  expect(() => setTempo(220)).not.toThrow(); // Maximum
});
```

3. **Type Coercion**
```typescript
it('should handle type coercion', () => {
  expect(processRhythm(['1', '2', '3'])).toEqual([1, 2, 3]);
});
```

### Priority 4: Integration Tests (Week 4)

**Files to Focus On**:
- `tests/integration/` directory
- Cross-module workflows

#### Example: End-to-End Integration Test
```typescript
// Test file: tests/integration/composition-workflow.test.ts

describe('Composition Generation Workflow', () => {
  it('should generate composition from seed to audio', async () => {
    const client = new SchillingerSDK({
      apiKey: 'test-key',
      apiUrl: 'http://localhost:3000/api/v1'
    });

    await client.authenticate();

    // Generate composition
    const composition = await client.generateComposition({
      seed: 12345,
      tempo: 120,
      bars: 32
    });

    expect(composition).toBeDefined();
    expect(composition.events.length).toBeGreaterThan(0);

    // Render to audio
    const audioBuffer = await client.renderToAudio(composition);

    expect(audioBuffer).toBeDefined();
    expect(audioBuffer.duration).toBeGreaterThan(0);
  });

  it('should handle authentication failure in workflow', async () => {
    const client = new SchillingerSDK({
      apiKey: 'invalid-key',
      apiUrl: 'http://localhost:3000/api/v1'
    });

    await expect(client.generateComposition({
      seed: 12345,
      tempo: 120,
      bars: 32
    })).rejects.toThrow(/authentication/i);
  });
});
```

## Best Practices

### 1. Test Organization
```
core/src/
├── client.ts
├── client.test.ts                    # Happy path tests
├── client-coverage-improvements.test.ts  # Coverage improvements
├── auth/
│   ├── auth-manager.ts
│   └── auth-manager.test.ts
└── cache/
    ├── cache-manager.ts
    └── cache-manager.test.ts
```

### 2. Test Naming
```typescript
// Good: Descriptive and specific
it('should handle expired authentication token with automatic refresh', async () => {
  // ...
});

// Bad: Vague
it('should work', async () => {
  // ...
});
```

### 3. Test Structure
```typescript
// Arrange-Act-Assert pattern
it('should validate configuration parameters', () => {
  // Arrange
  const invalidConfig = { apiKey: '', apiUrl: '' };

  // Act
  const createClient = () => new SchillingerSDK(invalidConfig);

  // Assert
  expect(createClient).toThrow();
});
```

### 4. Mocking Strategy
```typescript
// Prefer real implementations over mocks when possible
it('should handle cache failures', async () => {
  // Good: Mock only the failure, use real cache manager
  vi.spyOn(cacheManager, 'set').mockRejectedValue(new Error('Failed'));

  // Bad: Mock entire cache manager
  const mockCacheManager = {
    set: vi.fn(),
    get: vi.fn()
  };
});
```

### 5. Async Testing
```typescript
// Always await async operations
it('should authenticate asynchronously', async () => {
  const client = new SchillingerSDK(config);

  // Good: Await the promise
  await client.authenticate();
  expect(client.isAuthenticated).toBe(true);

  // Bad: Don't await
  client.authenticate();
  expect(client.isAuthenticated).toBe(true); // Race condition!
});
```

## Coverage Threshold Enforcement

### Pre-commit Hook Setup
```bash
# .husky/pre-commit
#!/bin/sh
npm run test:coverage

# Check if coverage meets threshold
if [ $? -ne 0 ]; then
  echo "❌ Coverage threshold not met"
  exit 1
fi
```

### Vitest Configuration
```typescript
// vitest.config.ts
coverage: {
  provider: 'v8',
  reporter: ['text', 'json', 'html', 'lcov'],
  thresholds: {
    lines: 85,
    functions: 85,
    branches: 85,
    statements: 85,
    // Allow per-file thresholds
    perFile: true
  }
}
```

## Continuous Improvement

### Weekly Coverage Reviews
1. Run coverage report: `npm run test:coverage`
2. Open `coverage/index.html`
3. Identify top 10 files with lowest coverage
4. Create tests for uncovered paths
5. Verify improvement in next report

### Coverage Tracking
```bash
# Generate coverage badge
npx coverage-badges

# Track coverage over time
npx vitest --coverage --reporter=json > coverage-reports/$(date +%Y%m%d).json
```

## Troubleshooting

### Issue: Coverage Not Improving
**Solution**:
1. Verify tests are actually running: `npm test -- --listTests`
2. Check test file is included in vitest.config.ts
3. Ensure test file pattern matches: `**/*.test.ts`
4. Run specific test: `npm test -- path/to/test.file.ts`

### Issue: Flaky Tests
**Solution**:
1. Increase timeout: `test.setTimeout(30000)`
2. Use proper async/await: `await asyncOperation()`
3. Clean up mocks: `vi.restoreAllMocks()`
4. Isolate tests: `isolate: true` in vitest.config.ts

### Issue: Slow Test Execution
**Solution**:
1. Run tests in parallel: `vitest --threads`
2. Use test.only to debug specific tests
3. Split test suites by package
4. Use `vi.mock()` for expensive operations

## Success Criteria

- [ ] Overall coverage ≥85%
- [ ] All critical paths covered
- [ ] No flaky tests (pass rate ≥98%)
- [ ] Test execution time <5 minutes
- [ ] Coverage report generated and verified
- [ ] Documentation updated

## Additional Resources

- **Vitest Documentation**: https://vitest.dev/
- **fast-check Documentation**: https://github.com/dubzzd/fast-check
- **Coverage Report**: `sdk/coverage/index.html`
- **Issue**: white_room-454

---

**Next Steps**:
1. Review coverage report
2. Implement Priority 1 tests (Week 1)
3. Add property-based tests (Week 2)
4. Verify 85% coverage achieved
5. Update bd issue white_room-454

**Last Updated**: January 16, 2026
