package com.sitebook.data.local.dao

import androidx.room.*
import com.sitebook.data.local.entities.UserPreference
import kotlinx.coroutines.flow.Flow

@Dao
interface UserPreferenceDao {
    
    @Query("SELECT * FROM user_preferences WHERE id = 'user_prefs' LIMIT 1")
    fun getUserPreferences(): Flow<UserPreference?>
    
    @Query("SELECT * FROM user_preferences WHERE id = 'user_prefs' LIMIT 1")
    suspend fun getUserPreferencesSync(): UserPreference?
    
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertUserPreferences(preferences: UserPreference)
    
    @Update
    suspend fun updateUserPreferences(preferences: UserPreference)
    
    @Query("UPDATE user_preferences SET notificationsEnabled = :enabled WHERE id = 'user_prefs'")
    suspend fun updateNotificationSettings(enabled: Boolean)
    
    @Query("UPDATE user_preferences SET autoReserveEnabled = :enabled WHERE id = 'user_prefs'")
    suspend fun updateAutoReserveSettings(enabled: Boolean)
    
    @Query("UPDATE user_preferences SET biometricAuthEnabled = :enabled WHERE id = 'user_prefs'")
    suspend fun updateBiometricSettings(enabled: Boolean)
    
    @Query("UPDATE user_preferences SET preferredRadius = :radius WHERE id = 'user_prefs'")
    suspend fun updatePreferredRadius(radius: Double)
    
    @Query("UPDATE user_preferences SET maxAutoReservePrice = :maxPrice WHERE id = 'user_prefs'")
    suspend fun updateMaxAutoReservePrice(maxPrice: Double?)
    
    @Delete
    suspend fun deleteUserPreferences(preferences: UserPreference)
    
    @Query("DELETE FROM user_preferences")
    suspend fun deleteAllPreferences()
}