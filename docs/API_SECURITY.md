# 🔐 API Key Security Guide

## Quick Setup

1. **Copy environment template:**
   ```bash
   cp .env.example .env
   ```

2. **Add your API keys to `.env`:**
   ```bash
   # Edit .env file with your actual keys
   GOOGLE_MAPS_ANDROID_API_KEY=your_android_key
   GOOGLE_MAPS_IOS_API_KEY=your_ios_key  
   RECREATION_GOV_API_KEY=your_recreation_key
   ```

3. **Run securely:**
   ```bash
   # Method 1: Use provided script
   ./scripts/run_secure.sh
   
   # Method 2: Manual command
   flutter run --dart-define=GOOGLE_MAPS_API_KEY=your_key
   ```

## 🛡️ Security Methods

### ✅ **Method 1: Environment Variables (Recommended)**
```bash
# Load from .env and run
export $(cat .env | xargs)
flutter run --dart-define=GOOGLE_MAPS_API_KEY="$GOOGLE_MAPS_IOS_API_KEY"
```

### ✅ **Method 2: Direct dart-define** 
```bash
flutter run --dart-define=GOOGLE_MAPS_API_KEY=your_actual_key_here
```

### ✅ **Method 3: VS Code Launch Config**
- Use **F5** in VS Code with "Launch SiteBook (Secure)" configuration
- Automatically loads environment variables

### ✅ **Method 4: CI/CD Integration**
```yaml
# GitHub Actions example
env:
  GOOGLE_MAPS_API_KEY: ${{ secrets.GOOGLE_MAPS_API_KEY }}
  
script: |
  flutter build ios --dart-define=GOOGLE_MAPS_API_KEY="$GOOGLE_MAPS_API_KEY"
```

## 📱 Platform-Specific Keys

**iOS:** Configured in `ios/Runner/Info.plist` via `$(GOOGLE_MAPS_API_KEY)`
**Android:** Configured in `android/.../AndroidManifest.xml` via `${GOOGLE_MAPS_API_KEY}`

Both read from `--dart-define` at build time.

## 🔒 Security Checklist

- ✅ `.env` file is in `.gitignore`  
- ✅ No hardcoded keys in source code
- ✅ API keys restricted by app bundle ID
- ✅ Different keys for Android/iOS if needed
- ✅ Secure CI/CD variable storage

## 🚨 Never Commit:
- `.env` files
- API keys in source code  
- Secrets in git history