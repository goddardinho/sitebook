# Development Setup Guide

## Prerequisites

### Required Software
- **Android Studio**: Hedgehog (2023.1.1) or newer
- **JDK**: OpenJDK 17 or Oracle JDK 17
- **Android SDK**: API Level 34 (Android 14)
- **Git**: Latest version
- **Kotlin**: 1.9.20+ (handled by Gradle)

### Development Environment
- **Operating System**: Windows 10+, macOS 12+, or Ubuntu 20.04+
- **RAM**: Minimum 8GB, recommended 16GB
- **Storage**: At least 10GB free space
- **Network**: Internet connection for dependencies and API calls

## Initial Setup

### 1. Clone Repository
```bash
git clone https://github.com/your-org/sitebook.git
cd sitebook
```

### 2. Configure API Keys
Create `local.properties` file in project root:
```properties
# Recreation.gov API Key (required)
RECREATION_GOV_API_KEY=your_recreation_gov_api_key_here

# SiteBook Backend API Key (optional for local development)
SITEBOOK_API_KEY=your_sitebook_api_key_here

# Firebase Configuration (optional)
FIREBASE_PROJECT_ID=your_firebase_project_id
```

### 3. Android Studio Setup
1. Open Android Studio
2. Select "Open an Existing Project"
3. Navigate to the cloned repository
4. Wait for Gradle sync to complete
5. Configure SDK if prompted

### 4. Run Initial Build
```bash
./gradlew assembleDebug
```

## Project Structure

```
sitebook/
├── app/                          # Main application module
│   ├── src/
│   │   ├── main/
│   │   │   ├── java/com/sitebook/
│   │   │   │   ├── data/         # Data layer (repositories, DAOs, APIs)
│   │   │   │   ├── di/           # Dependency injection modules
│   │   │   │   ├── services/     # Background services
│   │   │   │   ├── ui/           # UI layer (activities, fragments, VMs)
│   │   │   │   └── utils/        # Utility classes
│   │   │   ├── res/              # Android resources
│   │   │   └── AndroidManifest.xml
│   │   ├── test/                 # Unit tests
│   │   └── androidTest/          # Instrumentation tests
│   ├── build.gradle              # App-level build configuration
│   └── proguard-rules.pro        # ProGuard configuration
├── docs/                         # Documentation
├── build.gradle                  # Project-level build configuration
├── settings.gradle               # Project settings
└── README.md                     # Main documentation
```

## Development Workflow

### 1. Branch Strategy
```bash
main                    # Production-ready code
├── develop            # Integration branch
├── feature/monitoring # New features  
├── bugfix/auth-fix   # Bug fixes
└── hotfix/critical   # Critical production fixes
```

### 2. Creating a New Feature
```bash
# Create and switch to feature branch
git checkout -b feature/new-feature-name

# Make your changes
# ...

# Commit changes
git add .
git commit -m "feat: add new feature description"

# Push to remote
git push origin feature/new-feature-name

# Create pull request on GitHub
```

### 3. Commit Convention
Follow [Conventional Commits](https://www.conventionalcommits.org/):
```
feat: add new feature
fix: resolve bug in availability checking  
docs: update API documentation
style: format code according to guidelines
refactor: restructure repository pattern
test: add unit tests for campground service
chore: update dependencies
```

## Code Style and Quality

### Kotlin Style Guide
Follow [Kotlin Coding Conventions](https://kotlinlang.org/docs/coding-conventions.html):

```kotlin
// Good: descriptive names, proper formatting
class CampgroundRepository @Inject constructor(
    private val localDataSource: CampgroundDao,
    private val remoteDataSource: RecreationGovService
) {
    suspend fun refreshCampgrounds(): Result<List<Campground>> {
        return try {
            val response = remoteDataSource.getFacilities()
            if (response.isSuccessful) {
                val campgrounds = response.body()?.toCampgroundList()
                localDataSource.insertAll(campgrounds)
                Result.success(campgrounds)
            } else {
                Result.failure(ApiException(response.code()))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
}
```

### Code Formatting
Run ktlint before committing:
```bash
./gradlew ktlintCheck     # Check formatting
./gradlew ktlintFormat    # Auto-format code
```

### Static Analysis
```bash
./gradlew lint            # Android lint
./gradlew detekt          # Kotlin static analysis
```

## Testing

### Unit Tests
Located in `src/test/java/`
```bash
./gradlew test                    # Run all unit tests
./gradlew testDebugUnitTest       # Run debug unit tests
```

### Instrumentation Tests
Located in `src/androidTest/java/`
```bash
./gradlew connectedAndroidTest    # Run on connected device
./gradlew connectedDebugAndroidTest # Run debug instrumentation tests
```

### Test Coverage
```bash
./gradlew jacocoTestReport        # Generate coverage report
# View report at: app/build/reports/jacoco/test/html/index.html
```

### Writing Tests

#### Unit Test Example
```kotlin
@ExtendWith(MockitoExtension::class)
class CampgroundRepositoryTest {

    @Mock
    private lateinit var dao: CampgroundDao
    
    @Mock
    private lateinit var apiService: RecreationGovService

    private lateinit var repository: CampgroundRepository

    @BeforeEach
    fun setup() {
        repository = CampgroundRepository(dao, apiService)
    }

    @Test
    fun `refreshCampgrounds returns success when API call succeeds`() = runTest {
        // Given
        val mockResponse = mockSuccessfulApiResponse()
        `when`(apiService.getFacilities(any())).thenReturn(mockResponse)

        // When
        val result = repository.refreshCampgrounds()

        // Then
        assertThat(result.isSuccess).isTrue()
        verify(dao).insertAll(any())
    }
}
```

#### Integration Test Example
```kotlin
@HiltAndroidTest
class CampgroundsFragmentTest {

    @get:Rule
    val hiltRule = HiltAndroidRule(this)

    @Test
    fun displaysCampgroundsWhenLoaded() {
        launchFragmentInHiltContainer<CampgroundsFragment> {
            // Test fragment behavior
        }
        
        onView(withId(R.id.recycler_view_campgrounds))
            .check(matches(isDisplayed()))
    }
}
```

## Database Development

### Room Database
- Located in `data/local/`
- Auto-generates database schema in `app/schemas/`
- Use type-safe queries with `@Query` annotations

### Schema Changes
1. Update entity classes
2. Increment database version in `SiteBookDatabase`
3. Add migration if needed:
```kotlin
val MIGRATION_1_2 = object : Migration(1, 2) {
    override fun migrate(database: SupportSQLiteDatabase) {
        database.execSQL("ALTER TABLE campgrounds ADD COLUMN isMonitored INTEGER NOT NULL DEFAULT 0")
    }
}
```

### Database Testing
```bash
./gradlew connectedAndroidTest -Pandroid.testInstrumentationRunnerArguments.class=com.sitebook.data.local.DatabaseTest
```

## API Development

### Adding New Endpoints
1. Define API interface in `data/remote/api/`
2. Add response models in `data/remote/models/`
3. Update repository to use new endpoint
4. Add unit tests for API integration

### Mock API for Testing
Use `MockWebServer` for testing:
```kotlin
@Before
fun setup() {
    mockWebServer = MockWebServer()
    mockWebServer.start()
    
    val retrofit = Retrofit.Builder()
        .baseUrl(mockWebServer.url("/"))
        .build()
        
    apiService = retrofit.create(RecreationGovService::class.java)
}
```

## Debugging

### Android Studio Debugging
1. Set breakpoints in code
2. Run app in debug mode (Shift+F9)
3. Use debug console to inspect variables
4. Step through code execution

### Logging
Use structured logging:
```kotlin
class NetworkLogger {
    companion object {
        private const val TAG = "SiteBook_Network"
        
        fun logApiCall(endpoint: String, responseTime: Long) {
            Log.d(TAG, "API Call: $endpoint took ${responseTime}ms")
        }
        
        fun logError(error: Exception) {
            Log.e(TAG, "Network error", error)
        }
    }
}
```

### Database Inspection
1. Open Device File Explorer in Android Studio
2. Navigate to `/data/data/com.sitebook/databases/`
3. Download `sitebook_database` file
4. Open with SQLite browser

## Performance

### Profiling
1. **CPU Profiler**: Analyze method execution time
2. **Memory Profiler**: Track memory usage and leaks
3. **Network Profiler**: Monitor API call performance
4. **Energy Profiler**: Optimize battery usage

### Common Optimizations
```kotlin
// Use coroutines for async operations
suspend fun loadCampgrounds() = withContext(Dispatchers.IO) {
    campgroundDao.getAll()
}

// Implement pagination for large lists
@Query("SELECT * FROM campgrounds LIMIT :limit OFFSET :offset")
suspend fun getCampgroundsPage(limit: Int, offset: Int): List<Campground>

// Use view binding for efficient view access
private var _binding: FragmentCampgroundsBinding? = null
private val binding get() = _binding!!
```

## Deployment

### Debug Builds
```bash
./gradlew assembleDebug
# APK location: app/build/outputs/apk/debug/app-debug.apk
```

### Release Builds
```bash
./gradlew assembleRelease
# APK location: app/build/outputs/apk/release/app-release.apk
```

### Signing Configuration
Add to `app/build.gradle`:
```gradle
android {
    signingConfigs {
        release {
            storeFile file('../keystore/release.jks')
            storePassword System.getenv('KEYSTORE_PASSWORD')
            keyAlias System.getenv('KEY_ALIAS')
            keyPassword System.getenv('KEY_PASSWORD')
        }
    }
}
```

## Troubleshooting

### Common Issues

#### Gradle Sync Failed
```bash
# Clean and rebuild
./gradlew clean
./gradlew build

# Clear Gradle cache
rm -rf ~/.gradle/caches/
```

#### Database Schema Conflicts
```bash
# Delete app data and reinstall
adb uninstall com.sitebook.debug
./gradlew installDebug
```

#### API Rate Limiting
- Check API key quotas
- Implement exponential backoff
- Use local caching to reduce API calls

#### Memory Leaks
- Use LeakCanary for detection
- Properly cancel coroutines in ViewModels
- Avoid static references to Context

### Getting Help
1. Check existing [GitHub Issues](https://github.com/your-org/sitebook/issues)
2. Create new issue with:
   - Device information
   - Android version
   - Steps to reproduce
   - Relevant logs
3. Join team Slack for real-time help

## Contributing

### Pull Request Process
1. Create feature branch from `develop`
2. Make changes with proper tests
3. Update documentation if needed
4. Ensure all tests pass
5. Create pull request with detailed description
6. Address code review feedback
7. Wait for approval and merge

### Code Review Checklist
- [ ] Code follows style guidelines
- [ ] All tests pass
- [ ] Documentation updated
- [ ] No security vulnerabilities
- [ ] Performance considerations addressed
- [ ] Accessibility guidelines followed

---

Welcome to SiteBook development! This guide should get you up and running quickly. Don't hesitate to ask questions or suggest improvements to this documentation.