package com.sitebook.utils

import android.content.Context
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKeys
import dagger.hilt.android.qualifiers.ApplicationContext
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class TokenManager @Inject constructor(
    @ApplicationContext private val context: Context
) {
    private val masterKeyAlias = MasterKeys.getOrCreate(MasterKeys.AES256_GCM_SPEC)
    
    private val encryptedPrefs = EncryptedSharedPreferences.create(
        "secure_prefs",
        masterKeyAlias,
        context,
        EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
        EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
    )
    
    fun saveTokens(accessToken: String, refreshToken: String) {
        encryptedPrefs.edit()
            .putString(ACCESS_TOKEN_KEY, accessToken)
            .putString(REFRESH_TOKEN_KEY, refreshToken)
            .putLong(TOKEN_SAVED_TIME_KEY, System.currentTimeMillis())
            .apply()
    }
    
    fun getToken(): String? {
        return encryptedPrefs.getString(ACCESS_TOKEN_KEY, null)
    }
    
    fun getRefreshToken(): String? {
        return encryptedPrefs.getString(REFRESH_TOKEN_KEY, null)
    }
    
    fun clearTokens() {
        encryptedPrefs.edit()
            .remove(ACCESS_TOKEN_KEY)
            .remove(REFRESH_TOKEN_KEY)
            .remove(TOKEN_SAVED_TIME_KEY)
            .apply()
    }
    
    fun isLoggedIn(): Boolean {
        return getToken() != null
    }
    
    fun getTokenSavedTime(): Long {
        return encryptedPrefs.getLong(TOKEN_SAVED_TIME_KEY, 0)
    }
    
    companion object {
        private const val ACCESS_TOKEN_KEY = "access_token"
        private const val REFRESH_TOKEN_KEY = "refresh_token"
        private const val TOKEN_SAVED_TIME_KEY = "token_saved_time"
    }
}