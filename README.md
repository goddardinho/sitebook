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
- **Monitoring system** to track availability for your favorite campgrounds
- **Sample data** from 5 major National Parks (Yellowstone, Grand Canyon, Yosemite, Olympic, Zion)

### ✅ **Reservation System**
- **Multi-step reservation form** with guided user experience
- **Smart date selection** with validation and availability constraints
- **Guest count and campsite type selection** with real-time pricing
- **Contact information form** with validation and professional formatting
- **Comprehensive pricing calculator** with taxes, fees, and detailed breakdown
- **Reservation summary and confirmation** with complete booking details

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

4. **Run the application**
   ```bash
   # Web (Chrome)
   flutter run -d chrome
   
   # iOS Simulator
   flutter run -d ios
   
   # Android Emulator
   flutter run -d android
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
- **Comprehensive Testing Infrastructure**:
  - **Unit Tests**: Form validation, business logic, component testing
  - **Integration Tests**: End-to-end user flows and navigation
  - **Test Coverage**: 15+ tests covering all major functionality
- **State Management**: Complete Riverpod provider architecture
- **Navigation**: Bottom navigation with Material 3 styling  
- **Theming**: Responsive design with automatic theme switching

### 🚧 **In Development**
- Interactive maps with campground locations
- Recreation.gov API integration for real-time availability
- User profile and preference management
- Payment processing integration

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
