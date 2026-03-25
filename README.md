# SiteBook - Campground Reservation Monitor

A modern Android application that monitors campground and campsite availability and can automatically make reservations when desired sites become available.

## Features

### 🏕️ Core Features
- **Campground Discovery**: Browse and search campgrounds across the United States
- **Real-time Monitoring**: Monitor specific campsites for availability 
- **Automatic Reservations**: Automatically book campsites when they become available
- **Push Notifications**: Get instant alerts when monitored sites open up
- **Offline Support**: Access previously viewed campgrounds without internet
- **Location-based Search**: Find campgrounds near your current location

### 🔧 Technical Features
- **Modern Architecture**: MVVM + Repository pattern with Hilt dependency injection
- **Background Processing**: Uses WorkManager for reliable background monitoring
- **Secure Storage**: Encrypted storage for user credentials and sensitive data
- **Material Design 3**: Modern, accessible UI following latest design guidelines
- **Real-time Sync**: Seamless synchronization across devices

## Architecture

### Tech Stack
- **Language**: Kotlin 100%
- **Architecture**: MVVM + Repository Pattern
- **Dependency Injection**: Hilt (Dagger)
- **Database**: Room with SQLite
- **Networking**: Retrofit + OkHttp
- **Background Tasks**: WorkManager + Foreground Services
- **Navigation**: Navigation Component
- **UI**: View Binding + Material Design 3
- **Image Loading**: Glide
- **Security**: EncryptedSharedPreferences, Biometric Authentication

### Project Structure
```
app/
├── src/main/java/com/sitebook/
│   ├── data/                    # Data layer
│   │   ├── local/              # Room database, DAOs, entities
│   │   ├── remote/             # API services and models
│   │   └── Repository.kt       # Repository implementations
│   ├── di/                     # Dependency injection modules
│   ├── services/               # Background services
│   ├── ui/                     # UI layer (Activities, Fragments, ViewModels)
│   │   ├── campgrounds/        # Campground browsing and details
│   │   ├── reservations/       # Reservation management
│   │   └── profile/            # User profile and settings
│   ├── utils/                  # Utility classes
│   └── SiteBookApplication.kt  # Application class
└── docs/                       # Documentation
```

## API Integration

### Recreation.gov Integration
SiteBook integrates with the official Recreation.gov API to access:
- Federal campground data
- Real-time availability information
- Campsite details and amenities
- Reservation systems

### Custom Backend
- User authentication and management
- Reservation monitoring and automation
- Push notification delivery
- Cross-device synchronization

## Getting Started

### Prerequisites
- Android Studio Hedgehog or newer
- Android SDK 24+ (Android 7.0)
- Kotlin 1.9.20+
- Git

### Setup Instructions

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/sitebook.git
   cd sitebook
   ```

2. **API Keys Configuration**
   Create a `local.properties` file in the project root:
   ```properties
   RECREATION_GOV_API_KEY=your_recreation_gov_api_key_here
   SITEBOOK_API_KEY=your_sitebook_api_key_here
   ```

3. **Build and Run**
   ```bash
   ./gradlew assembleDebug
   # or open in Android Studio and run
   ```

### Development Setup

1. **Enable Developer Options** on your Android device
2. **Enable USB Debugging**
3. **Configure emulator** or connect physical device
4. **Run the app** from Android Studio

## Configuration

### Required Permissions
- `INTERNET` - Network access for API calls
- `ACCESS_FINE_LOCATION` - Location-based campground discovery
- `RECEIVE_BOOT_COMPLETED` - Restart monitoring after device reboot
- `POST_NOTIFICATIONS` - Push notifications for availability alerts
- `WAKE_LOCK` - Background processing

### API Keys Required

#### Recreation.gov API Key
1. Visit [Recreation.gov API](https://ridb.recreation.gov/) 
2. Register for a free API key
3. Add to `local.properties`: `RECREATION_GOV_API_KEY=your_key_here`

#### Firebase (for push notifications)
1. Create Firebase project
2. Add Android app with package name: `com.sitebook`
3. Download `google-services.json` to `app/` directory
4. Configure FCM for push notifications

## Usage

### Monitoring Campgrounds
1. **Browse Campgrounds**: Use the search and filter features
2. **Enable Monitoring**: Toggle monitoring switch on desired campgrounds
3. **Set Preferences**: Configure check intervals and notification settings
4. **Automatic Alerts**: Receive notifications when sites become available

### Making Reservations
1. **Manual Booking**: Tap "Book Now" when sites are available
2. **Auto-Reserve**: Enable automatic reservation with price limits
3. **Manage Reservations**: View and manage all your reservations in one place

### Background Monitoring
The app uses Android's WorkManager to periodically check availability:
- Respects battery optimization settings
- Works reliably across device restarts
- Configurable check intervals (15 minutes default)
- Foreground service for critical monitoring

## Security

### Data Protection
- **Encrypted Storage**: All sensitive data encrypted at rest
- **Secure Network**: TLS 1.3 for all API communications
- **Biometric Auth**: Optional biometric authentication for app access
- **Token Management**: Secure JWT token handling with refresh logic

### Privacy
- **Minimal Data Collection**: Only essential data is collected
- **Local Storage**: Most data stored locally on device
- **No Tracking**: No user activity tracking or analytics
- **GDPR Compliant**: Full user control over personal data

## Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

### Development Guidelines
- Follow Kotlin coding conventions
- Use ktlint for code formatting
- Write unit tests for new features
- Update documentation for API changes
- Use conventional commits for commit messages

### Reporting Issues
- Use GitHub Issues for bug reports
- Include device information and Android version
- Provide steps to reproduce issues
- Include relevant logs when possible

## Testing

### Unit Tests
```bash
./gradlew test
```

### Instrumentation Tests  
```bash
./gradlew connectedAndroidTest
```

### Test Coverage
```bash
./gradlew jacocoTestReport
```

## Building

### Debug Build
```bash
./gradlew assembleDebug
```

### Release Build
```bash
./gradlew assembleRelease
```

### APK Location
Built APKs are located in `app/build/outputs/apk/`

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

- **Documentation**: [GitHub Wiki](https://github.com/yourusername/sitebook/wiki)
- **Issues**: [GitHub Issues](https://github.com/yourusername/sitebook/issues)
- **Discussions**: [GitHub Discussions](https://github.com/yourusername/sitebook/discussions)

## Roadmap

### v2.0 - Planned Features
- [ ] iOS version
- [ ] Widget support for quick status
- [ ] Advanced filtering and search
- [ ] Social features (share favorites)
- [ ] Offline maps integration
- [ ] Weather integration
- [ ] Multiple reservation systems support

### v1.1 - Next Release
- [ ] Dark theme support
- [ ] Enhanced accessibility
- [ ] Performance optimizations
- [ ] Additional notification settings
- [ ] Backup and restore functionality

---

*SiteBook is not affiliated with Recreation.gov or any government agency. This is an independent application designed to help users monitor campground availability.*