# Choral Ensemble Engine - Contributing Guide

**Guidelines for contributing to Choral development**

---

## Table of Contents

1. [Getting Started](#getting-started)
2. [Code Style Guide](#code-style-guide)
3. [Pull Request Process](#pull-request-process)
4. [Testing Requirements](#testing-requirements)
5. [Documentation Standards](#documentation-standards)
6. [Release Workflow](#release-workflow)

---

## Getting Started

### Development Environment

#### Required Tools

- **CMake** 3.16+
- **C++ Compiler** with C++17 support
  - Clang 10+ (recommended)
  - GCC 9+
  - MSVC 2019+
- **JUCE** 7.0.0+
- **Git** for version control
- **Python** 3.8+ (for control engine)

#### Cloning the Repository

```bash
# Clone repository
git clone https://github.com/white-room-audio/choral.git
cd choral

# Initialize submodules
git submodule update --init --recursive

# Create development branch
git checkout -b feature/my-feature
```

#### Building

```bash
# Configure build
cmake -B build -DCMAKE_BUILD_TYPE=Debug -DBUILD_TESTS=ON

# Build
cmake --build build

# Run tests
ctest --test-dir build --output-on-failure
```

### Project Structure

```
choral/
├── dsp/                    # DSP modules
│   └── plugin/
│       ├── SingerVoice.h/.cpp
│       ├── FormantFilterBank.h/.cpp
│       └── tests/
├── control_engine/         # Control engine (Python)
│   ├── harmony_router.py
│   ├── curve_interpreter.py
│   └── tests/
├── src/                    # JUCE plugin wrapper
│   ├── ChoirProcessor.h/.cpp
│   └── ChoirEditor.h/.cpp
├── shared/                 # Shared schemas
│   └── schemas/
├── docs/                   # Documentation
│   ├── user/
│   └── developer/
├── infrastructure/         # Build/CI scripts
└── testing/               # Test infrastructure
```

---

## Code Style Guide

### C++ Style

#### Naming Conventions

```cpp
// Classes: PascalCase
class SingerVoice { };

// Functions: camelCase
void processBlock();

// Variables: camelCase
float sampleRate;
int voiceCount;

// Private members: trailing underscore
class VoiceBank {
private:
    int maxVoices_;
    std::unique_ptr<SingerVoice[]> voices_;
};

// Constants: UPPER_SNAKE_CASE
constexpr int MAX_VOICES = 128;
constexpr double DEFAULT_SAMPLE_RATE = 48000.0;

// Enums: PascalCase for type, UPPER_SNAKE_CASE for values
enum class VoiceState {
    ACTIVE,
    RELEASED,
    STOLEN
};
```

#### Formatting

```cpp
// Braces: Allman style (opening brace on new line)
void processBlock(AudioBuffer<float>& buffer)
{
    // Indentation: 4 spaces
    for (int i = 0; i < numSamples; ++i)
    {
        // Spaces around operators
        float result = a + b * c;

        // Spaces after commas
        function(param1, param2, param3);
    }
}

// Line length: 120 characters max
void veryLongFunctionName(Type1 parameter1, Type2 parameter2, Type3 parameter3, Type4 parameter4);

// Templates: Space before angle brackets
template<typename T, size_t Size>
class FixedArray { };
```

#### Includes

```cpp
// 1. Corresponding header
#include "SingerVoice.h"

// 2. C standard library
#include <cmath>
#include <cstring>

// 3. C++ standard library
#include <algorithm>
#include <array>
#include <memory>

// 4. JUCE headers
#include <juce_audio_processors/juce_audio_processors.h>

// 5. Project headers
#include "FormantFilterBank.h"
#include "VoiceBank.h"
```

#### Best Practices

```cpp
// ✅ GOOD: Use const references
void processBuffer(const AudioBuffer<float>& buffer);

// ❌ BAD: Unnecessary copy
void processBuffer(AudioBuffer<float> buffer);

// ✅ GOOD: Use constexpr for constants
constexpr int MAX_VOICES = 128;

// ❌ BAD: #define for constants
#define MAX_VOICES 128

// ✅ GOOD: Use smart pointers
std::make_unique<SingerVoice>();

// ❌ BAD: Raw pointers with manual delete
SingerVoice* voice = new SingerVoice();
// ... use voice ...
delete voice;

// ✅ GOOD: Range-based for loops
for (auto& voice : voices) {
    voice.process();
}

// ❌ BAD: Index-based loops when range-based works
for (size_t i = 0; i < voices.size(); ++i) {
    voices[i].process();
}

// ✅ GOOD: auto for type deduction
auto iterator = map.find(key);

// ❌ BAD: Explicit type when auto is clearer
std::map<std::string, int>::iterator iterator = map.find(key);
```

### Python Style (Control Engine)

#### Naming Conventions

```python
# Classes: PascalCase
class HarmonyRouter:
    pass

# Functions: snake_case
def generate_satb(chord):
    pass

# Variables: snake_case
voice_count = 16
formant_scale = 1.0

# Constants: UPPER_SNAKE_CASE
MAX_VOICES = 128
DEFAULT_SAMPLE_RATE = 48000.0
```

#### Formatting

```python
# Indentation: 4 spaces
def function(param1, param2, param3):
    # Spaces around operators
    result = a + b * c

    # Spaces after commas
    function(param1, param2, param3)

# Line length: 100 characters max
# Use parentheses for implicit line continuation
result = (very_long_function_name(parameter1, parameter2) +
          another_function(parameter3))
```

---

## Pull Request Process

### Workflow

1. **Fork Repository**
   ```bash
   # Fork on GitHub
   git clone https://github.com/YOUR_USERNAME/choral.git
   ```

2. **Create Branch**
   ```bash
   git checkout -b feature/my-feature
   # or
   git checkout -b fix/bug-description
   ```

3. **Make Changes**
   - Follow code style guide
   - Add tests
   - Update documentation

4. **Commit Changes**
   ```bash
   git add .
   git commit -m "feat: Add feature description"
   ```

5. **Push to Fork**
   ```bash
   git push origin feature/my-feature
   ```

6. **Create Pull Request**
   - Go to GitHub
   - Click "New Pull Request"
   - Fill out PR template

### Commit Message Format

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>[optional scope]: <description>

[optional body]

[optional footer]
```

**Types**:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting)
- `refactor`: Code refactoring
- `perf`: Performance improvement
- `test`: Test additions/changes
- `chore`: Build process, tooling

**Examples**:

```
feat(dsp): Add abyssal mode support

Implement formant scaling below 1.0 for sub-harmonic content.
Add parameter validation to prevent extreme values.

Closes #123
```

```
fix(control): Correct voice stealing logic

Previous implementation stole oldest voice regardless of amplitude.
Now implements Oldest+Quietest strategy for better results.

Fixes #456
```

### Pull Request Template

```markdown
## Description
Brief description of changes.

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Testing
- [ ] Unit tests added/updated
- [ ] All tests passing
- [ ] Manual testing completed

## Checklist
- [ ] Code follows style guide
- [ ] Self-review completed
- [ ] Documentation updated
- [ ] No new warnings generated

## Related Issues
Closes #(issue number)
```

---

## Testing Requirements

### Unit Tests

#### DSP Tests

```cpp
// Location: dsp/plugin/tests/
// File: test_SingerVoice.cpp

class SingerVoiceTest : public UnitTest {
public:
    SingerVoiceTest() : UnitTest("SingerVoice", "DSP") {}

    void runTest() override {
        beginTest("NoteOn starts voice");
        {
            SingerVoice voice;
            voice.prepare(48000.0, 512);
            voice.noteOn(60.0f, 0.8f);
            expect(voice.isActive());
            expectEquals(voice.getCurrentPitch(), 60.0f);
        }

        beginTest("NoteOff releases voice");
        {
            SingerVoice voice;
            voice.prepare(48000.0, 512);
            voice.noteOn(60.0f, 0.8f);
            voice.noteOff(0.5f);

            // Render release
            float* outputs[2];
            float buffer[512];
            outputs[0] = buffer;
            outputs[1] = buffer;

            voice.process(outputs, 2, 512);

            // Voice should be inactive after release
            // (depending on release time)
        }
    }
};

static SingerVoiceTest singerVoiceTest;
```

#### Control Engine Tests

```python
# Location: control_engine/tests/
# File: test_harmony_router.py

import unittest
from control_engine import HarmonyRouter, Chord, ChordQuality

class TestHarmonyRouter(unittest.TestCase):
    def setUp(self):
        self.router = HarmonyRouter()

    def test_c_major_satb(self):
        """Test C major chord generates correct SATB voicing"""
        chord = Chord(
            root=60,
            quality=ChordQuality.MAJOR,
            has_7th=False,
            inversion=0
        )

        voicing = self.router.generate_satb(chord)

        # Check ranges
        self.assertGreaterEqual(voicing.soprano, 60)
        self.assertLessEqual(voicing.soprano, 84)

        self.assertGreaterEqual(voicing.alto, 55)
        self.assertLessEqual(voicing.alto, 79)

        self.assertGreaterEqual(voicing.tenor, 48)
        self.assertLessEqual(voicing.tenor, 72)

        self.assertGreaterEqual(voicing.bass, 40)
        self.assertLessEqual(voicing.bass, 64)

    def test_voice_crossing(self):
        """Test voice crossing detection"""
        from control_engine import HarmonyRouter

        # Good voicing (no crossing)
        voicing_good = SATBVoicing(
            soprano=67,
            alto=64,
            tenor=60,
            bass=48
        )
        self.assertFalse(HarmonyRouter.has_voice_crossing(voicing_good))

        # Bad voicing (crossing)
        voicing_bad = SATBVoicing(
            soprano=67,
            alto=60,  # Below tenor!
            tenor=64,
            bass=48
        )
        self.assertTrue(HarmonyRouter.has_voice_crossing(voicing_bad))

if __name__ == '__main__':
    unittest.main()
```

### Integration Tests

```cpp
// Location: testing/integration/
// File: test_full_render.cpp

class FullRenderTest : public UnitTest {
public:
    FullRenderTest() : UnitTest("FullRender", "Integration") {}

    void runTest() override {
        beginTest("Render complete control stream");
        {
            // Load control stream
            std::ifstream stream("test_streams/control_stream_abyssal.json");
            std::string json((std::istreambuf_iterator<char>(stream)),
                            std::istreambuf_iterator<char>());

            // Create processor
            ChoirProcessor processor;
            processor.prepareToPlay(48000.0, 512);

            // Load stream
            ControlStreamIngest ingest;
            ingest.loadControlStream(json);

            // Render 10 seconds
            AudioBuffer<float> buffer(2, 48000 * 10);
            processor.processBlock(buffer, MidiBuffer());

            // Verify output
            expect(buffer.getMagnitude(0, 0, buffer.getNumSamples()) > 0.0f);
        }
    }
};
```

### Test Coverage

**Minimum Requirements**:
- DSP modules: 80% coverage
- Control engine: 80% coverage
- Integration: 60% coverage

**Running Coverage**:

```bash
# Generate coverage report
cmake -B build -DCMAKE_BUILD_TYPE=Debug -DENABLE_COVERAGE=ON
cmake --build build
ctest --test-dir build
lcov --capture --directory build --output-file coverage.info
genhtml coverage.info --output-directory coverage_html
```

---

## Documentation Standards

### Code Comments

```cpp
/**
 * @brief Brief description of class/function
 *
 * Detailed description spanning multiple lines.
 * Explain purpose, usage, and important details.
 *
 * @param param1 Description of parameter 1
 * @param param2 Description of parameter 2
 * @return Description of return value
 *
 * Example:
 * @code
 * SingerVoice voice;
 * voice.prepare(48000.0, 512);
 * @endcode
 */
void prepare(double sampleRate, int samplesPerBlock);
```

### README Updates

When adding features:
1. Update feature list in main README
2. Add usage example
3. Link to relevant documentation

### API Documentation

When adding APIs:
1. Document in ARCHITECTURE.md
2. Add API reference to API_REFERENCE.md
3. Provide usage examples
4. Document parameter ranges

---

## Release Workflow

### Version Numbers

Follow [Semantic Versioning](https://semver.org/):

```
MAJOR.MINOR.PATCH

MAJOR: Breaking changes
MINOR: New features (backwards compatible)
PATCH: Bug fixes (backwards compatible)
```

### Release Checklist

- [ ] All tests passing
- [ ] Documentation updated
- [ ] CHANGELOG.md updated
- [ ] Version number updated
- [ ] Tagged in git
- [ ] Release notes written
- [ ] Binaries built
- [ ] GitHub release created

### Creating Release

```bash
# Update version
# Edit CMakeLists.txt: VERSION "1.0.0" → "1.1.0"

# Commit changes
git add .
git commit -m "chore: Release v1.1.0"

# Create tag
git tag -a v1.1.0 -m "Release v1.1.0"

# Push
git push origin main
git push origin v1.1.0

# GitHub Actions will build and release
```

---

## Getting Help

### Resources

- **Documentation**: [docs/](../docs/)
- **Issues**: [GitHub Issues](https://github.com/white-room-audio/choral/issues)
- **Discussions**: [GitHub Discussions](https://github.com/white-room-audio/choral/discussions)

### Contact

- **Email**: dev@whiteroomaudio.com
- **Discord**: [link to server]

---

Thank you for contributing to Choral!

---

**Version**: 1.0.0
**Last Updated**: January 16, 2026
**Author**: White Room Audio

---

**Generated with [Claude Code](https://claude.com/claude-code)**
