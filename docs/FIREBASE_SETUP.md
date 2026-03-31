# Firebase Setup Guide for SiteBook

This guide explains how to set up Firebase for SiteBook's notification and background task functionality.

## Development Mode

During development, SiteBook runs in **development mode** without requiring actual Firebase configuration. The app will:

- ✅ Initialize successfully with placeholder Firebase configuration
- ✅ Show local notifications for testing
- ✅ Handle notification permissions gracefully
- ⚠️ Skip actual push notifications (FCM will not work)
- ⚠️ Firebase Analytics will not collect data

This allows for full development and testing of the notification UI and local notification functionality.

## Production Setup

For production deployment with full Firebase functionality, follow these steps:

### 1. Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Create a project" 
3. Enter project name (e.g., "sitebook-prod")
4. Enable Google Analytics (recommended)
5. Complete project creation

### 2. Add Android App

1. In Firebase Console → Project Overview → Add app → Android
2. Register app with package name: `com.sitebook.sitebook_flutter`
3. Download `google-services.json`
4. Place the file in `android/app/google-services.json`
5. Follow Firebase setup instructions for Android

### 3. Add iOS App  

1. In Firebase Console → Project Overview → Add app → iOS
2. Register app with bundle ID: `com.sitebook.sitebookFlutter`
3. Download `GoogleService-Info.plist`
4. Place the file in `ios/Runner/GoogleService-Info.plist`
5. Follow Firebase setup instructions for iOS

### 4. Enable Firebase Services

In Firebase Console, enable:
- **Cloud Messaging (FCM)**: For push notifications
- **Analytics**: For user behavior tracking
- **Crashlytics** (optional): For crash reporting

### 5. Update Configuration

Replace the placeholder configuration in `lib/core/firebase/firebase_config.dart`:

```dart
static FirebaseOptions _getFirebaseOptions() {
  return const FirebaseOptions(
    apiKey: 'YOUR_ACTUAL_API_KEY',
    appId: 'YOUR_ACTUAL_APP_ID', 
    messagingSenderId: 'YOUR_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    storageBucket: 'YOUR_STORAGE_BUCKET',
  );
}
```

Or use environment variables:

```dart
static FirebaseOptions _getFirebaseOptions() {
  return FirebaseOptions(
    apiKey: const String.fromEnvironment('FIREBASE_API_KEY', defaultValue: 'dev-key'),
    appId: const String.fromEnvironment('FIREBASE_APP_ID', defaultValue: 'dev-app'),
    messagingSenderId: const String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID', defaultValue: '123456789'),
    projectId: const String.fromEnvironment('FIREBASE_PROJECT_ID', defaultValue: 'dev-project'),
    storageBucket: const String.fromEnvironment('FIREBASE_STORAGE_BUCKET', defaultValue: 'dev-bucket'),
  );
}
```

### 6. Update .env File

Copy your Firebase configuration to `.env`:

```bash
FIREBASE_API_KEY=your_actual_api_key
FIREBASE_APP_ID=your_actual_app_id  
FIREBASE_MESSAGING_SENDER_ID=your_sender_id
FIREBASE_PROJECT_ID=your_project_id
FIREBASE_STORAGE_BUCKET=your_storage_bucket
```

## Testing

### Local Notifications
- Work in both development and production
- Test with: `NotificationService.showAvailabilityNotification()`
- Verify Android notification channels work correctly
- Check iOS notification permissions

### Push Notifications (Production Only)
- Send test messages from Firebase Console
- Verify background message handling  
- Test notification tap navigation
- Confirm FCM token generation and refresh

## Architecture

```
Firebase Services Used:
├── 🔥 Firebase Core - Foundation service
├── 📱 Firebase Messaging (FCM) - Push notifications  
├── 📊 Firebase Analytics - User behavior tracking
└── 🔔 Local Notifications - Offline notification support

Integration Points:
├── 📱 NotificationService - Unified notification handling
├── 🔧 FirebaseConfig - Initialization and configuration  
├── 🎯 Background Tasks - Availability monitoring
└── 🚀 App Navigation - Notification tap handling
```

## Security Notes

- Never commit actual Firebase configuration files to version control
- Use environment variables for production secrets
- Firebase Security Rules should restrict access appropriately  
- FCM tokens should be handled securely on your backend
- Consider using Firebase App Check for additional security

## Development Tips

1. **Test notification permissions early** - iOS is strict about permission requests
2. **Use Firebase Console** for sending test push notifications
3. **Monitor Firebase Analytics** to understand user engagement
4. **Set up proper notification channels** for Android 8.0+
5. **Handle all notification states** - foreground, background, terminated

## Troubleshooting

### Common Issues:
- **No notifications on iOS**: Check notification permissions and certificates
- **Android notifications not showing**: Verify notification channels are created
- **FCM token null**: Check Firebase initialization and network connectivity  
- **Background messages not working**: Verify background processing permissions

### Debug Commands:
```bash
# Check Firebase initialization
flutter logs | grep "Firebase"

# Test notification permissions  
flutter logs | grep "notification"

# Verify FCM token generation
flutter logs | grep "FCM Token"
```

With this setup, SiteBook can provide robust notification functionality for campground availability alerts while maintaining a clean development experience.