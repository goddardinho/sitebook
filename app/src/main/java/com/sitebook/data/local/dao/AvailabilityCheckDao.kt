package com.sitebook.data.local.dao

import androidx.room.*
import com.sitebook.data.local.entities.AvailabilityCheck
import kotlinx.coroutines.flow.Flow
import java.util.Date

@Dao
interface AvailabilityCheckDao {
    
    @Query("SELECT * FROM availability_checks ORDER BY checkedAt DESC")
    fun getAllAvailabilityChecks(): Flow<List<AvailabilityCheck>>
    
    @Query("""
        SELECT * FROM availability_checks 
        WHERE campsiteId = :campsiteId 
          AND checkInDate = :checkInDate 
          AND checkOutDate = :checkOutDate
        ORDER BY checkedAt DESC
        LIMIT 1
    """)
    suspend fun getLatestAvailabilityCheck(
        campsiteId: String,
        checkInDate: Date,
        checkOutDate: Date
    ): AvailabilityCheck?
    
    @Query("""
        SELECT * FROM availability_checks 
        WHERE campsiteId = :campsiteId 
        ORDER BY checkedAt DESC
    """)
    fun getAvailabilityChecksForCampsite(campsiteId: String): Flow<List<AvailabilityCheck>>
    
    @Query("""
        SELECT * FROM availability_checks 
        WHERE isAvailable = 1 
          AND checkInDate >= :fromDate
        ORDER BY checkedAt DESC
    """)
    suspend fun getAvailableCampsites(fromDate: Date): List<AvailabilityCheck>
    
    @Query("""
        SELECT * FROM availability_checks 
        WHERE checkedAt >= :since
        ORDER BY checkedAt DESC
    """)
    suspend fun getRecentAvailabilityChecks(since: Date): List<AvailabilityCheck>
    
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertAvailabilityCheck(check: AvailabilityCheck)
    
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertAvailabilityChecks(checks: List<AvailabilityCheck>)
    
    @Update
    suspend fun updateAvailabilityCheck(check: AvailabilityCheck)
    
    @Delete
    suspend fun deleteAvailabilityCheck(check: AvailabilityCheck)
    
    @Query("DELETE FROM availability_checks WHERE campsiteId = :campsiteId")
    suspend fun deleteAvailabilityChecksForCampsite(campsiteId: String)
    
    @Query("DELETE FROM availability_checks WHERE checkedAt < :cutoffDate")
    suspend fun deleteOldAvailabilityChecks(cutoffDate: Date)
    
    @Query("DELETE FROM availability_checks")
    suspend fun deleteAllAvailabilityChecks()
}