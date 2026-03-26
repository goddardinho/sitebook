package com.sitebook.data.local.dao

import androidx.room.*
import com.sitebook.data.local.entities.Campground
import kotlinx.coroutines.flow.Flow

@Dao
interface CampgroundDao {
    
    @Query("SELECT * FROM campgrounds ORDER BY name ASC")
    fun getAllCampgrounds(): Flow<List<Campground>>
    
    @Query("SELECT * FROM campgrounds WHERE isMonitored = 1")
    fun getMonitoredCampgrounds(): Flow<List<Campground>>
    
    @Query("SELECT * FROM campgrounds WHERE id = :campgroundId")
    suspend fun getCampgroundById(campgroundId: String): Campground?
    
    @Query("""
        SELECT * FROM campgrounds 
        WHERE (:latitude - latitude) * (:latitude - latitude) + 
              (:longitude - longitude) * (:longitude - longitude) < :radiusSquared
        ORDER BY 
              (:latitude - latitude) * (:latitude - latitude) + 
              (:longitude - longitude) * (:longitude - longitude) ASC
    """)
    suspend fun getCampgroundsNearby(
        latitude: Double, 
        longitude: Double, 
        radiusSquared: Double
    ): List<Campground>
    
    @Query("""
        SELECT * FROM campgrounds 
        WHERE name LIKE '%' || :searchQuery || '%' 
           OR description LIKE '%' || :searchQuery || '%'
           OR state LIKE '%' || :searchQuery || '%'
        ORDER BY name ASC
    """)
    suspend fun searchCampgrounds(searchQuery: String): List<Campground>
    
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertCampground(campground: Campground)
    
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertCampgrounds(campgrounds: List<Campground>)
    
    @Update
    suspend fun updateCampground(campground: Campground)
    
    @Query("UPDATE campgrounds SET isMonitored = :isMonitored WHERE id = :campgroundId")
    suspend fun updateMonitoringStatus(campgroundId: String, isMonitored: Boolean)
    
    @Delete
    suspend fun deleteCampground(campground: Campground)
    
    @Query("DELETE FROM campgrounds WHERE id = :campgroundId")
    suspend fun deleteCampgroundById(campgroundId: String)
    
    @Query("DELETE FROM campgrounds")
    suspend fun deleteAllCampgrounds()
}