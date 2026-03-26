# SiteBook TODO & Feature Roadmap

*Last Updated: March 26, 2026*

## 🔧 Critical Build Issues (High Priority)

### KAPT Annotation Processing Compatibility
- **Status**: ❌ Blocked
- **Issue**: KAPT annotation processing fails with Java 25.0.2 + Gradle 9.4.1
- **Impact**: Dependency injection (Hilt), Room database compilation, Glide, and other annotation processors disabled
- **Next Steps**:
  - Monitor Hilt, Room, and Glide for Java 25 compatible versions
  - Consider migration to KSP (Kotlin Symbol Processing) when supported
  - Temporary workaround: Manual dependency setup without annotation processing

### Build System Stabilization
- **Status**: ✅ Partially Complete
- **Completed**:
  - ✅ Gradle wrapper updated to 9.4.1
  - ✅ Android resources fixed (XML files, drawables, strings)
  - ✅ Manifest dependencies resolved
  - ✅ Compile SDK updated to API 35
- **Remaining**: Full KAPT restoration when libraries support Java 25

## 🚀 Core Feature Development (Medium Priority)

### Database Layer
- **Status**: 🔄 In Progress
- **Completed**: Room entity definitions, DAO interfaces
- **Pending**: 
  - Room annotation processing restoration
  - Database migrations
  - Full repository implementation

### API Integration
- **Status**: ✅ Architecture Ready
- **Completed**: Retrofit service definitions, API models
- **Pending**: 
  - Recreation.gov API testing
  - Error handling implementation
  - Rate limiting and caching

### Background Monitoring
- **Status**: 🔄 Architectural Complete
- **Completed**: WorkManager structure, service definitions
- **Pending**: 
  - Dependency injection restoration
  - Full service implementation
  - Notification system integration

### UI Components
- **Status**: ✅ Scaffold Complete
- **Completed**: 
  - Fragment architecture
  - Navigation structure
  - Material Design 3 implementation
  - View binding setup

## 📱 Feature Roadmap (Future)

### Phase 1: Core Functionality
- [ ] Basic campground browsing
- [ ] Simple reservation tracking
- [ ] Manual availability checking
- [ ] User authentication

### Phase 2: Automation
- [ ] Background availability monitoring
- [ ] Push notifications
- [ ] Automatic reservation booking
- [ ] Location-based search

### Phase 3: Advanced Features
- [ ] Offline support
- [ ] Cross-device sync
- [ ] Advanced filtering
- [ ] Reservation analytics

### Phase 4: Platform Expansion
- [ ] Kotlin Multiplatform shared logic
- [ ] iOS companion app
- [ ] Web dashboard
- [ ] Widget support

## 🔐 Security & Performance

### Security Implementation
- **Status**: ✅ Architecture Ready
- **Tasks**:
  - [ ] Implement certificate pinning
  - [ ] Set up encrypted storage
  - [ ] Add biometric authentication
  - [ ] Configure ProGuard/R8 obfuscation

### Performance Optimization
- **Status**: ⏳ Future
- **Tasks**:
  - [ ] Database indexing optimization
  - [ ] Image loading optimization
  - [ ] Memory leak prevention
  - [ ] Battery usage optimization

## 🧪 Testing Infrastructure

### Unit Testing
- **Status**: ⏳ Pending KAPT Resolution
- **Dependencies**: Hilt testing, Room testing framework

### Integration Testing
- **Status**: ⏳ Future
- **Tasks**:
  - [ ] API integration tests
  - [ ] Database migration tests
  - [ ] End-to-end user flow tests

### UI Testing
- **Status**: ⏳ Future
- **Tasks**:
  - [ ] Espresso test suite
  - [ ] Screenshot testing
  - [ ] Accessibility testing

## 📊 Technical Debt

### Code Quality
- [ ] Set up ktlint and detekt
- [ ] Add code coverage reporting
- [ ] Implement architecture decision records (ADRs)
- [ ] Set up dependency vulnerability scanning

### Documentation
- [x] Architecture documentation
- [x] Setup instructions update
- [ ] API documentation
- [ ] User guide creation

### DevOps
- [ ] CI/CD pipeline setup
- [ ] Automated testing
- [ ] Release automation
- [ ] Crash reporting integration

## 🔄 Migration Tasks

### Technology Upgrades
- [ ] **KAPT to KSP Migration**: When KSP supports all required processors
- [ ] **View Binding to Compose**: Gradual migration to Jetpack Compose
- [ ] **Modularization**: Split into feature modules for better build performance

### Dependencies
- [ ] **Regular Updates**: Keep dependencies current for security
- [ ] **Unused Dependency Cleanup**: Remove redundant libraries
- [ ] **License Compliance**: Ensure all licenses are compatible

---

## 📋 Development Notes

### Known Issues
1. **Java 25 Compatibility**: Current blocking issue for full feature development
2. **API Key Requirements**: Recreation.gov API key needed for testing
3. **Testing Infrastructure**: Requires KAPT for full test setup

### Success Criteria
- [ ] Full build without warnings or errors  
- [ ] All core features functional
- [ ] Comprehensive test coverage (>80%)
- [ ] Production-ready security implementation
- [ ] App Store submission ready

*This document is updated regularly as development progresses.*