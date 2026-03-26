package com.sitebook.data.local.dao

import androidx.lifecycle.LiveData
import androidx.room.*
import com.sitebook.data.local.entities.*
import kotlinx.coroutines.flow.Flow

@Dao
interface CampgroundDao {
    @Query("SELECT * FROM campgrounds ORDER BY name ASC")
    fun getAllCampgroundsFlow(): Flow<List<Campground>>

    @Query("SELECT * FROM campgrounds WHERE isMonitored = 1")
    fun getMonitoredCampgroundsFlow(): Flow<List<Campground>>

    @Query("SELECT * FROM campgrounds WHERE id = :id")
    suspend fun getCampgroundById(id: String): Campground?

    @Query("""
        SELECT * FROM campgrounds 
        WHERE (:searchQuery IS NULL OR name LIKE '%' || :searchQuery || '%' 
               OR description LIKE '%' || :searchQuery || '%')
        AND (:state IS NULL OR state = :state)
        ORDER BY name ASC
    """)
    fun searchCampgrounds(searchQuery: String?, state: String?): Flow<List<Campground>>

    @Query("""
        SELECT * FROM campgrounds 
        WHERE (latitude BETWEEN :minLat AND :maxLat) 
        AND (longitude BETWEEN :minLng AND :maxLng)
        ORDER BY name ASC
    """)
    suspend fun getCampgroundsInBounds(
        minLat: Double, maxLat: Double, 
        minLng: Double, maxLng: Double
    ): List<Campground>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertCampground(campground: Campground)

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertCampgrounds(campgrounds: List<Campground>)

    @Update
    suspend fun updateCampground(campground: Campground)

    @Query("UPDATE campgrounds SET isMonitored = :isMonitored WHERE id = :id")
    suspend fun updateMonitoringStatus(id: String, isMonitored: Boolean)

    @Delete
    suspend fun deleteCampground(campground: Campground)

    @Query("DELETE FROM campgrounds WHERE id = :id")
    suspend fun deleteCampgroundById(id: String)
}

@Dao
interface CampsiteDao {
    @Query("SELECT * FROM campsites WHERE campgroundId = :campgroundId ORDER BY siteNumber ASC")
    fun getCampsitesByCampgroundFlow(campgroundId: String): Flow<List<Campsite>>

    @Query("SELECT * FROM campsites WHERE id = :id")
    suspend fun getCampsiteById(id: String): Campsite?

    @Query("SELECT * FROM campsites WHERE isMonitored = 1")
    fun getMonitoredCampsitesFlow(): Flow<List<Campsite>>

    @Query("""
        SELECT * FROM campsites 
        WHERE campgroundId = :campgroundId 
        AND (:siteType IS NULL OR siteType = :siteType)
        AND maxOccupancy >= :minOccupancy
        AND (:accessibility IS NULL OR accessibility = :accessibility)
        ORDER BY siteNumber ASC
    """)
    suspend fun filterCampsites(
        campgroundId: String,
        siteType: String?,
        minOccupancy: Int,
        accessibility: Boolean?
    ): List<Campsite>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertCampsite(campsite: Campsite)

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertCampsites(campsites: List<Campsite>)

    @Update
    suspend fun updateCampsite(campsite: Campsite)

    @Query("UPDATE campsites SET isMonitored = :isMonitored WHERE id = :id")
    suspend fun updateMonitoringStatus(id: String, isMonitored: Boolean)

    @Delete
    suspend fun deleteCampsite(campsite: Campsite)
}

@Dao
interface ReservationDao {
    @Query("SELECT * FROM reservations WHERE userId = :userId ORDER BY checkInDate DESC")
    fun getReservationsByUserFlow(userId: String): Flow<List<Reservation>>

    @Query("SELECT * FROM reservations WHERE status = :status")
    fun getReservationsByStatusFlow(status: ReservationStatus): Flow<List<Reservation>>

    @Query("SELECT * FROM reservations WHERE autoReserve = 1 AND status = 'MONITORING'")
    suspend fun getActiveMonitoringReservations(): List<Reservation>

    @Query("SELECT * FROM reservations WHERE id = :id")
    suspend fun getReservationById(id: String): Reservation?

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertReservation(reservation: Reservation)

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertReservations(reservations: List<Reservation>)

    @Update
    suspend fun updateReservation(reservation: Reservation)

    @Query("UPDATE reservations SET status = :status, updatedAt = :updatedAt WHERE id = :id")
    suspend fun updateReservationStatus(id: String, status: ReservationStatus, updatedAt: java.util.Date)

    @Delete
    suspend fun deleteReservation(reservation: Reservation)

    @Query("DELETE FROM reservations WHERE status = 'CANCELLED' AND updatedAt < :cutoffDate")
    suspend fun deleteOldCancelledReservations(cutoffDate: java.util.Date)
}

@Dao
interface AvailabilityDao {
    @Query("""
        SELECT * FROM availability_checks 
        WHERE campsiteId = :campsiteId 
        AND checkInDate = :checkInDate 
        AND checkOutDate = :checkOutDate 
        ORDER BY checkedAt DESC 
        LIMIT 1
    """)
    suspend fun getLatestAvailability(
        campsiteId: String,
        checkInDate: java.util.Date,
        checkOutDate: java.util.Date
    ): AvailabilityCheck?

    @Query("""
        SELECT * FROM availability_checks 
        WHERE campsiteId = :campsiteId 
        AND checkedAt >= :since 
        ORDER BY checkedAt DESC
    """)
    suspend fun getRecentChecks(campsiteId: String, since: java.util.Date): List<AvailabilityCheck>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertAvailabilityCheck(check: AvailabilityCheck)

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertAvailabilityChecks(checks: List<AvailabilityCheck>)

    @Query("DELETE FROM availability_checks WHERE checkedAt < :cutoffDate")
    suspend fun deleteOldChecks(cutoffDate: java.util.Date)
}

@Dao
interface UserPreferenceDao {
    @Query("SELECT * FROM user_preferences WHERE id = 'user_prefs'")
    fun getUserPreferencesFlow(): Flow<UserPreference?>

    @Query("SELECT * FROM user_preferences WHERE id = 'user_prefs'")
    suspend fun getUserPreferences(): UserPreference?

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertUserPreference(preference: UserPreference)

    @Update
    suspend fun updateUserPreference(preference: UserPreference)
}