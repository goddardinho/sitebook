package com.sitebook.utils

import androidx.test.core.app.ApplicationProvider
import androidx.test.ext.junit.runners.AndroidJUnit4
import dagger.hilt.android.testing.HiltAndroidRule
import dagger.hilt.android.testing.HiltAndroidTest
import org.junit.Before
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import javax.inject.Inject
import kotlin.test.*

/**
 * Integration tests for TokenManager to validate secure token storage and authentication lifecycle.
 * 
 * Tests include:
 * - Encrypted storage of access and refresh tokens
 * - Token retrieval and validation
 * - Authentication state management
 * - Token cleanup and security
 * - EncryptedSharedPreferences integration
 * 
 * Uses real Android keystore and encryption for authentic security testing.
 */
@HiltAndroidTest
@RunWith(AndroidJUnit4::class)
class TokenManagerTest {

    @get:Rule
    var hiltRule = HiltAndroidRule(this)

    @Inject
    lateinit var tokenManager: TokenManager

    @Before
    fun init() {
        hiltRule.inject()
        // Clean state before each test
        tokenManager.clearTokens()
    }

    @Test
    fun whenTokensAreSaved_theyCanBeRetrievedCorrectly() {
        // Given
        val accessToken = "test-access-token-12345"
        val refreshToken = "test-refresh-token-67890"

        // When
        tokenManager.saveTokens(accessToken, refreshToken)
        val retrievedAccessToken = tokenManager.getToken()
        val retrievedRefreshToken = tokenManager.getRefreshToken()

        // Then
        assertEquals(accessToken, retrievedAccessToken, "Access token should be retrievable")
        assertEquals(refreshToken, retrievedRefreshToken, "Refresh token should be retrievable")
    }

    @Test
    fun whenNoTokensAreSaved_getTokenReturnsNull() {
        // Given - clean state (from @Before)
        
        // When
        val accessToken = tokenManager.getToken()
        val refreshToken = tokenManager.getRefreshToken()

        // Then  
        assertNull(accessToken, "Access token should be null when not saved")
        assertNull(refreshToken, "Refresh token should be null when not saved")
    }

    @Test
    fun whenTokensAreSaved_isLoggedInReturnsTrue() {
        // Given
        val accessToken = "valid-access-token"
        val refreshToken = "valid-refresh-token"

        // When
        tokenManager.saveTokens(accessToken, refreshToken)
        val isLoggedIn = tokenManager.isLoggedIn()

        // Then
        assertTrue(isLoggedIn, "Should be logged in when tokens are present")
    }

    @Test
    fun whenNoTokensPresent_isLoggedInReturnsFalse() {
        // Given - clean state

        // When
        val isLoggedIn = tokenManager.isLoggedIn()

        // Then
        assertFalse(isLoggedIn, "Should not be logged in when no tokens present")
    }

    @Test
    fun whenTokensAreCleared_allTokensAreRemoved() {
        // Given
        tokenManager.saveTokens("access-token", "refresh-token")
        assertTrue(tokenManager.isLoggedIn(), "Precondition: should be logged in")

        // When
        tokenManager.clearTokens()

        // Then
        assertNull(tokenManager.getToken(), "Access token should be null after clear")
        assertNull(tokenManager.getRefreshToken(), "Refresh token should be null after clear")
        assertFalse(tokenManager.isLoggedIn(), "Should not be logged in after clear")
    }

    @Test  
    fun whenTokensAreOverwritten_newValuesAreRetrieved() {
        // Given
        val originalAccess = "original-access-token"
        val originalRefresh = "original-refresh-token"
        val newAccess = "new-access-token"
        val newRefresh = "new-refresh-token"

        // When
        tokenManager.saveTokens(originalAccess, originalRefresh)
        tokenManager.saveTokens(newAccess, newRefresh)  // Overwrite

        // Then
        assertEquals(newAccess, tokenManager.getToken(), "Should retrieve new access token")
        assertEquals(newRefresh, tokenManager.getRefreshToken(), "Should retrieve new refresh token")
    }

    @Test
    fun whenLongTokensAreSaved_theyAreStoredAndRetrievedCorrectly() {
        // Given - simulate realistic JWT tokens (which can be quite long)
        val longAccessToken = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c"
        val longRefreshToken = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyLCJleHAiOjE1MTYyNDAwMDB9.different-signature-for-refresh-token"

        // When
        tokenManager.saveTokens(longAccessToken, longRefreshToken)
        val retrievedAccess = tokenManager.getToken()
        val retrievedRefresh = tokenManager.getRefreshToken()

        // Then
        assertEquals(longAccessToken, retrievedAccess, "Long access token should be preserved")
        assertEquals(longRefreshToken, retrievedRefresh, "Long refresh token should be preserved")
    }

    @Test
    fun whenSpecialCharactersInTokens_theyAreHandledCorrectly() {
        // Given - tokens with special characters that might cause encoding issues
        val specialAccessToken = "token-with-special!@#\$%^&*()_+-={}[]|\\:;\"'<>?,./chars"
        val specialRefreshToken = "refresh~`!@#\$%^&*()_+-={}[]|\\:;\"'<>?,./"

        // When
        tokenManager.saveTokens(specialAccessToken, specialRefreshToken)
        val retrievedAccess = tokenManager.getToken()
        val retrievedRefresh = tokenManager.getRefreshToken()

        // Then
        assertEquals(specialAccessToken, retrievedAccess, "Special characters in access token should be preserved")
        assertEquals(specialRefreshToken, retrievedRefresh, "Special characters in refresh token should be preserved")
    }

    @Test
    fun whenTokenManagerIsUsedMultipleTimes_consistentBehavior() {
        // Given
        val testCycles = 5
        val baseToken = "test-token-cycle"

        // When & Then - multiple save/retrieve/clear cycles
        repeat(testCycles) { cycle ->
            val accessToken = "${baseToken}-access-$cycle"
            val refreshToken = "${baseToken}-refresh-$cycle"

            // Save
            tokenManager.saveTokens(accessToken, refreshToken)
            assertTrue(tokenManager.isLoggedIn(), "Cycle $cycle: Should be logged in after save")

            // Retrieve
            assertEquals(accessToken, tokenManager.getToken(), "Cycle $cycle: Access token should match")
            assertEquals(refreshToken, tokenManager.getRefreshToken(), "Cycle $cycle: Refresh token should match")

            // Clear
            tokenManager.clearTokens()
            assertFalse(tokenManager.isLoggedIn(), "Cycle $cycle: Should not be logged in after clear")
        }
    }
}