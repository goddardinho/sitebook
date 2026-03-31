# SiteBook - Campground Monitor & Reservation App

*Modern Flutter application for discovering, monitoring, and booking campgrounds across National Parks and recreational areas*

[![Flutter](https://img.shields.io/badge/Flutter-3.41.6-blue.svg)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Dart-3.11.4-blue.svg)](https://dart.dev/)
[![Material 3](https://img.shields.io/badge/Material%203-Design-green.svg)](https://m3.material.io/)

## 🏕️ Features

### ✅ **Campground Discovery**
- **Professional listing interface** with Material 3 design
- **Rich campground cards** with image carousels and detailed information
- **Real-time search & filtering** by name, park, state, amenities, and activities
- **Comprehensive details view** with image gallery and complete campground information
- **Smart monitoring system** with notification integration for availability tracking
- **Sample data** from 5 major National Parks (Yellowstone, Grand Canyon, Yosemite, Olympic, Zion)

### ✅ **Reservation System**
- **Multi-step reservation form** with guided user experience
- **Smart date selection** with validation and availability constraints
- **Guest count and campsite type selection** with real-time pricing
- **Contact information form** with validation and professional formatting
- **Comprehensive pricing calculator** with taxes, fees, and detailed breakdown
- **Reservation summary and confirmation** with complete booking details

### ✅ **Maps & Location Features**
- **Interactive Google Maps integration** with campground markers and location display
- **"View on Map" functionality** - Navigate from campground details to focused map view
- **"Directions" integration** - One-tap launch to Google Maps with driving directions
- **Current location support** with permissions handling for iOS and Android
- **Map controls** - Map type selector (Normal/Satellite/Terrain/Hybrid) and marker clustering
- **Cross-platform navigation** - Automatic detection of available maps applications

### ✅ **Notifications & Background Tasks**
- **Firebase Cloud Messaging integration** with cross-platform push notification support
- **Smart notification system** integrated with campground monitoring toggles
- **Welcome notifications** for new users starting their first campground monitoring
- **Availability alerts** with demo simulation (30% chance of finding availability)
- **Development mode** - Full functionality without requiring Firebase project setup
- **Cross-platform permissions** - Proper iOS and Android notification permission handling
- **Local notification channels** - Organized notification categories for better user experience

### 🔧 **Technical Highlights**
- **Flutter 3.41.6** with modern Dart 3.11.4
- **Riverpod state management** for reactive data flow
- **Material 3 theming** with automatic dark/light mode
- **Responsive design** optimized for mobile and web
- **Clean architecture** with separation of concerns
- **Type-safe development** with comprehensive null safety
- **Comprehensive test suite** with unit, integration, and smoke tests
- **Professional form validation** and error handling

## 🚀 Getting Started

### Prerequisites
- Flutter 3.41.6 or higher
- Dart 3.11.4 or higher
- Chrome (for web development)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/goddardinho/sitebook.git
   cd sitebook
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Generate required code**
   ```bash
   flutter packages pub run build_runner build
   ```

4. **Set up environment variables**
   ```bash
   cp .env.example .env
   # Edit .env with your Google Maps and Recreation.gov API keys
   ```

5. **Run the application**
   ```bash
   # Secure script with API key management (recommended)
   ./scripts/run_secure.sh
   
   # Or specify a device
   ./scripts/run_secure.sh ios          # iOS Simulator
   ./scripts/run_secure.sh emulator-5554  # Android Emulator
   
   # Or run directly (requires API keys in .env)
   flutter run -d chrome    # Web
   flutter run -d ios       # iOS Simulator  
   flutter run -d android   # Android Emulator
   ```

## 📱 Current Status

### ✅ **Completed Features**
- **Complete Campground Discovery Experience**:
  - **Professional Listing Screen**: Advanced search, filtering, and monitoring
  - **Comprehensive Details View**: Image carousel, full information, action buttons
  - **Smooth Navigation**: Hero animations and intuitive user flow
- **Complete Reservation System**:
  - **Multi-Step Form**: Date selection, guest details, contact info, confirmation
  - **Smart Validation**: Form validation, date constraints, pricing calculations
  - **Professional UX**: Progress indicators, error handling, responsive design
- **Complete Notifications & Background Tasks**:
  - **Firebase Integration**: FCM, Analytics, and notification services
  - **Smart Notification System**: Integrated with campground monitoring
  - **Cross-Platform Support**: iOS and Android notification permissions and channels
  - **Development Mode**: Full testing without Firebase project requirement
  - **Demo Availability Alerts**: Simulated availability notifications for testing
- **Comprehensive Testing Infrastructure**:
  - **Unit Tests**: Form validation, business logic, component testing
  - **Integration Tests**: End-to-end user flows and navigation
  - **Test Coverage**: 15+ tests covering all major functionality
- **State Management**: Complete Riverpod provider architecture
- **Navigation**: Bottom navigation with Material 3 styling  
- **Theming**: Responsive design with automatic theme switching

### 🚧 **In Development**
- Recreation.gov API integration for real-time availability (service layer complete)
- Background task worker for periodic availability monitoring
- User profile and preference management
- Payment processing integration
- Notification preferences and settings UI

## 🏗️ Architecture

```
lib/
├── core/               # Core utilities and constants
├── features/           # Feature-based modules
│   ├── campgrounds/    # Campground discovery and management
│   │   ├── details/    # Campground details view
│   │   └── widgets/    # Reusable UI components
│   └── reservations/   # Complete reservation system
│       └── widgets/    # Form components and UI
└── shared/             # Shared resources
    ├── data/           # Sample data and repositories
    ├── models/         # Data models with JSON serialization
    ├── providers/      # Riverpod state management
    └── widgets/        # Common UI components

test/                   # Comprehensive test suite
├── helpers/            # Test utilities and mock data
├── integration_test/   # End-to-end testing framework
└── *.dart              # Unit and smoke tests
```

## � Testing

Run the comprehensive test suite:

```bash
# Run all tests
flutter test

# Run specific test files
flutter test test/smoke_test.dart
flutter test test/reservation_form_test.dart

# Run integration tests (requires device/emulator)
flutter test integration_test/reservation_flow_test.dart
```

## �🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🧪 Testing

Run the comprehensive test suite:

```bash
# Run all tests
flutter test

# Run specific test files
flutter test test/smoke_test.dart
flutter test test/reservation_form_test.dart

# Run integration tests (requires device/emulator)
flutter test integration_test/reservation_flow_test.dart
```

---

**Development Status**: Active development with complete campground discovery and reservation system. Professional-grade UI with comprehensive testing. Next phase focuses on API integration and real-time availability.
