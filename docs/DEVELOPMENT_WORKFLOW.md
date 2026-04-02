# Development Workflow & Quality Assurance

## Quick Start

```bash
# One-time setup
./scripts/setup_dev.sh

# Before each commit
./scripts/quality_check.sh

# Build with quality checks
./scripts/build_secure.sh ios debug
```

## Automated Quality Checks

### 🔍 Static Analysis
- **Stricter lint rules** catch unused variables, dead code, always-true conditions
- **Import organization** enforcement
- **Code formatting** validation
- **Error-level warnings** for critical issues

### 🧪 Testing
- **Unit tests** run automatically
- **Coverage tracking** and reporting
- **Provider integration** validation
- **Widget test** verification

### 🚫 Pre-commit Hooks
Automatically run before each commit:
- Code formatting check
- Static analysis
- Print statement detection (lib/ directory)
- YAML/JSON validation

### 🤖 Continuous Integration
GitHub Actions automatically run:
- Static analysis with fail-on-warnings
- Unit tests with coverage
- Integration tests on Android emulator
- Security audit checks
- Quality gate enforcement

## Tools & Commands

### Local Development
```bash
# Run all quality checks
./scripts/quality_check.sh

# Check formatting only
dart format --set-exit-if-changed .

# Run analysis only
flutter analyze --fatal-warnings

# Run tests only
flutter test --coverage

# Install/update pre-commit hooks
pre-commit install
pre-commit run --all-files
```

### CI/CD Pipeline
- **Trigger**: Push to main/develop branches or pull requests
- **Quality Gate**: All checks must pass before merge
- **Coverage**: Uploaded to Codecov for tracking
- **Security**: Basic dependency and script validation

## Error Prevention Strategy

### What We Catch Now ✅
1. **Provider access errors** - Wrong `.notifier.state` usage
2. **Missing class references** - Undefined widgets/classes
3. **Dead code** - Unreachable else blocks, unused methods
4. **Always-true conditions** - Unnecessary null checks
5. **Unused imports/variables** - Code cleanup
6. **Formatting inconsistencies** - Automatic enforcement
7. **Print statements** in production code

### New Analysis Rules 📋
- `unused_import: error` - Fails build on unused imports
- `unused_local_variable: error` - Catches forgotten variables  
- `dead_code: error` - Prevents unreachable code
- `avoid_print: true` - Warns about print statements
- Enhanced Flutter-specific lints

## Integration with IDEs

### VS Code
- Analysis runs automatically with stricter rules
- Refactor suggestions now caught as errors
- Real-time feedback on code quality

### Other IDEs
- IntelliJ/Android Studio work with same `analysis_options.yaml`
- Continuous feedback during development

## Coverage & Metrics

- **Test Coverage**: Generated with each test run
- **Analysis Coverage**: All Dart files scanned except generated code
- **Quality Metrics**: Track improvements over time

## Troubleshooting

### Common Issues
1. **Pre-commit failing**: Run `./scripts/quality_check.sh` to see specific issues
2. **Analysis errors**: Check `analysis_options.yaml` for rule explanations
3. **Test failures**: Run `flutter test --reporter=expanded` for detailed output
4. **Coverage issues**: Ensure `lcov` is installed for HTML reports

### Disabling Rules (Use Sparingly)
```dart
// ignore: unused_import
import 'package:unused_package/unused.dart';

// ignore_for_file: avoid_print
```

---

This workflow ensures the issues found in the recent refactor preview **cannot happen again** through automated prevention at multiple layers.