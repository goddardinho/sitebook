package com.sitebook

import androidx.test.ext.junit.runners.AndroidJUnit4
import com.sitebook.data.CampgroundRepository
import com.sitebook.data.ReservationRepository
import com.sitebook.data.UserRepository
import com.sitebook.data.local.SiteBookDatabase
import com.sitebook.data.local.dao.*
import com.sitebook.data.remote.api.*
import com.sitebook.utils.TokenManager
import dagger.hilt.android.testing.HiltAndroidRule
import dagger.hilt.android.testing.HiltAndroidTest
import org.junit.Before
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import javax.inject.Inject
import kotlin.test.assertNotNull

/**
 * Integration test to verify that Hilt dependency injection is working correctly
 * across all major components in the SiteBook application.
 * 
 * This test validates that all critical dependencies can be injected successfully:
 * - Database and DAO layer
 * - Repository layer with proper dependency resolution
 * - API services with authentication
 * - Utility classes (TokenManager)
 * 
 * Success indicates the complete dependency graph is properly configured.
 */
@HiltAndroidTest
@RunWith(AndroidJUnit4::class)
class HiltDependencyInjectionTest {

    @get:Rule
    var hiltRule = HiltAndroidRule(this)

    // Database layer
    @Inject lateinit var database: SiteBookDatabase
    @Inject lateinit var campgroundDao: CampgroundDao
    @Inject lateinit var campsiteDao: CampsiteDao  
    @Inject lateinit var reservationDao: ReservationDao
    @Inject lateinit var availabilityDao: AvailabilityDao
    @Inject lateinit var userPreferenceDao: UserPreferenceDao

    // Repository layer
    @Inject lateinit var campgroundRepository: CampgroundRepository
    @Inject lateinit var reservationRepository: ReservationRepository
    @Inject lateinit var userRepository: UserRepository

    // API services
    @Inject lateinit var siteBookApiService: SiteBookApiService
    @Inject lateinit var recreationGovService: RecreationGovService
    @Inject lateinit var campgroundSearchService: CampgroundSearchService

    // Utilities
    @Inject lateinit var tokenManager: TokenManager

    @Before
    fun init() {
        hiltRule.inject()
    }

    @Test
    fun whenApplicationStarts_allDatabaseDependenciesAreInjected() {
        assertNotNull(database, "SiteBookDatabase should be injected")
        assertNotNull(campgroundDao, "CampgroundDao should be injected")
        assertNotNull(campsiteDao, "CampsiteDao should be injected")
        assertNotNull(reservationDao, "ReservationDao should be injected")
        assertNotNull(availabilityDao, "AvailabilityDao should be injected")
        assertNotNull(userPreferenceDao, "UserPreferenceDao should be injected")
    }

    @Test
    fun whenApplicationStarts_allRepositoryDependenciesAreInjected() {
        assertNotNull(campgroundRepository, "CampgroundRepository should be injected")
        assertNotNull(reservationRepository, "ReservationRepository should be injected")
        assertNotNull(userRepository, "UserRepository should be injected")
    }

    @Test
    fun whenApplicationStarts_allApiServiceDependenciesAreInjected() {
        assertNotNull(siteBookApiService, "SiteBookApiService should be injected")
        assertNotNull(recreationGovService, "RecreationGovService should be injected")
        assertNotNull(campgroundSearchService, "CampgroundSearchService should be injected")
    }

    @Test
    fun whenApplicationStarts_utilityDependenciesAreInjected() {
        assertNotNull(tokenManager, "TokenManager should be injected")
    }

    @Test
    fun whenRepositoriesAreInjected_theirDependenciesAreProperlyResolved() {
        // This test verifies that repositories can access their injected dependencies
        // without causing runtime errors during dependency resolution
        
        // These calls should not throw exceptions if dependency injection is working
        val campgroundFlow = campgroundRepository.getAllCampgrounds()
        assertNotNull(campgroundFlow, "CampgroundRepository methods should be callable")
        
        val userPreferencesFlow = userRepository.getUserPreferences()
        assertNotNull(userPreferencesFlow, "UserRepository methods should be callable")
        
        // ReservationRepository makes calls to TokenManager - test compatibility
        val isLoggedIn = tokenManager.isLoggedIn()
        // Should return boolean (false initially) without errors
        assertNotNull(isLoggedIn, "TokenManager should respond without errors")
    }
}