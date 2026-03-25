package com.sitebook.data.local.dao

import androidx.room.*
import com.sitebook.data.local.entities.Campsite
import kotlinx.coroutines.flow.Flow

@Dao
interface CampsiteDao {
    
    @Query("SELECT * FROM campsites WHERE campgroundId = :campgroundId ORDER BY siteNumber ASC")
    fun getCampsitesByCampground(campgroundId: String): Flow<List<Campsite>>
    
    @Query("SELECT * FROM campsites WHERE isMonitored = 1")
    fun getMonitoredCampsites(): Flow<List<Campsite>>
    
    @Query("SELECT * FROM campsites WHERE id = :campsiteId")
    suspend fun getCampsiteById(campsiteId: String): Campsite?
    
    @Query("""
        SELECT * FROM campsites 
        WHERE campgroundId = :campgroundId 
          AND siteType = :siteType
          AND maxOccupancy >= :minOccupancy
        ORDER BY siteNumber ASC
    """)
    suspend fun searchCampsites(
        campgroundId: String,
        siteType: String? = null,
        minOccupancy: Int = 1
    ): List<Campsite>
    
    @Query("""
        SELECT * FROM campsites 
        WHERE campgroundId = :campgroundId 
          AND accessibility = 1
        ORDER BY siteNumber ASC
    """)
    suspend fun getAccessibleCampsites(campgroundId: String): List<Campsite>
    
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertCampsite(campsite: Campsite)
    
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertCampsites(campsites: List<Campsite>)
    
    @Update
    suspend fun updateCampsite(campsite: Campsite)
    
    @Query("UPDATE campsites SET isMonitored = :isMonitored WHERE id = :campsiteId")
    suspend fun updateMonitoringStatus(campsiteId: String, isMonitored: Boolean)
    
    @Delete
    suspend fun deleteCampsite(campsite: Campsite)
    
    @Query("DELETE FROM campsites WHERE id = :campsiteId")
    suspend fun deleteCampsiteById(campsiteId: String)
    
    @Query("DELETE FROM campsites WHERE campgroundId = :campgroundId")
    suspend fun deleteCampsitesByCampground(campgroundId: String)
}