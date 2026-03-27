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
- **Monitoring system** to track availability for your favorite campgrounds
- **Sample data** from 5 major National Parks (Yellowstone, Grand Canyon, Yosemite, Olympic, Zion)

### 🔧 **Technical Highlights**
- **Flutter 3.41.6** with modern Dart 3.11.4
- **Riverpod state management** for reactive data flow
- **Material 3 theming** with automatic dark/light mode
- **Responsive design** optimized for mobile and web
- **Clean architecture** with separation of concerns
- **Type-safe development** with comprehensive null safety

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
- **State Management**: Complete Riverpod provider architecture
- **Navigation**: Bottom navigation with Material 3 styling  
- **Theming**: Responsive design with automatic theme switching

### 🚧 **In Development**
- Reservation form with date selection and booking flow
- Interactive maps with campground locations
- Recreation.gov API integration for real-time availability
- User profile and preference management

## 🏗️ Architecture

```
lib/
├── core/               # Core utilities and constants
├── features/           # Feature-based modules
│   └── campgrounds/    # Campground listing and management
│       ├── widgets/    # Reusable UI components
│       └── screens/    # Screen implementations
└── shared/             # Shared resources
    ├── data/           # Sample data and repositories
    ├── models/         # Data models with JSON serialization
    ├── providers/      # Riverpod state management
    └── widgets/        # Common UI components
```

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

**Development Status**: Active development with professional-grade campground listing interface complete. Next phase focuses on details view and reservation functionality.
