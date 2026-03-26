package com.sitebook.data

import com.sitebook.data.local.dao.*
import com.sitebook.data.local.entities.*
import com.sitebook.data.remote.api.*
import com.sitebook.data.remote.models.*
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.first
import java.util.*
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class CampgroundRepository @Inject constructor(
    private val campgroundDao: CampgroundDao,
    private val campsiteDao: CampsiteDao,
    private val recreationService: RecreationGovService,
    private val searchService: CampgroundSearchService
) {
    fun getAllCampgrounds(): Flow<List<Campground>> = campgroundDao.getAllCampgroundsFlow()
    
    fun getMonitoredCampgrounds(): Flow<List<Campground>> = campgroundDao.getMonitoredCampgroundsFlow()
    
    suspend fun getCampgroundById(id: String): Campground? = campgroundDao.getCampgroundById(id)
    
    fun searchCampgrounds(query: String?, state: String?): Flow<List<Campground>> =
        campgroundDao.searchCampgrounds(query, state)
    
    suspend fun refreshCampgroundsFromApi(
        latitude: Double? = null,
        longitude: Double? = null,
        radius: Double? = null,
        state: String? = null,
        apiKey: String
    ): Result<List<Campground>> {
        return try {
            val response = recreationService.getFacilities(
                latitude = latitude,
                longitude = longitude,
                radius = radius,
                state = state,
                apiKey = apiKey
            )
            
            if (response.isSuccessful) {
                val facilities = response.body()?.data ?: emptyList()
                val campgrounds = facilities.map { it.toCampground() }
                campgroundDao.insertCampgrounds(campgrounds)
                Result.success(campgrounds)
            } else {
                Result.failure(Exception("API Error: ${response.code()}"))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
    
    suspend fun updateMonitoringStatus(campgroundId: String, isMonitored: Boolean) {
        campgroundDao.updateMonitoringStatus(campgroundId, isMonitored)
    }
    
    suspend fun getCampsitesByCampground(campgroundId: String): Flow<List<Campsite>> =
        campsiteDao.getCampsitesByCampgroundFlow(campgroundId)
    
    suspend fun refreshCampsitesFromApi(facilityId: String, apiKey: String): Result<List<Campsite>> {
        return try {
            val response = recreationService.getCampsites(facilityId = facilityId, apiKey = apiKey)
            
            if (response.isSuccessful) {
                val campsites = response.body()?.data?.map { it.toCampsite() } ?: emptyList()
                campsiteDao.insertCampsites(campsites)
                Result.success(campsites)
            } else {
                Result.failure(Exception("API Error: ${response.code()}"))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
}

@Singleton
class ReservationRepository @Inject constructor(
    private val reservationDao: ReservationDao,
    private val availabilityDao: AvailabilityDao,
    private val apiService: SiteBookApiService,
    private val tokenManager: TokenManager
) {
    fun getUserReservations(userId: String): Flow<List<Reservation>> =
        reservationDao.getReservationsByUserFlow(userId)
    
    fun getReservationsByStatus(status: ReservationStatus): Flow<List<Reservation>> =
        reservationDao.getReservationsByStatusFlow(status)
    
    suspend fun getActiveMonitoringReservations(): List<Reservation> =
        reservationDao.getActiveMonitoringReservations()
    
    suspend fun createReservation(reservation: Reservation): Result<Reservation> {
        return try {
            // Insert locally first
            reservationDao.insertReservation(reservation)
            
            // Sync with backend if authenticated
            tokenManager.getToken()?.let { token ->
                val request = ReservationRequest(
                    campsiteId = reservation.campsiteId,
                    checkInDate = reservation.checkInDate.toIsoString(),
                    checkOutDate = reservation.checkOutDate.toIsoString(),
                    guestCount = reservation.guestCount,
                    autoReserve = reservation.autoReserve,
                    maxPrice = reservation.maxPrice,
                    specialRequests = reservation.specialRequests
                )
                
                val response = apiService.createReservation("Bearer $token", request)
                if (response.isSuccessful) {
                    // Update local reservation with server data
                    response.body()?.let { serverReservation ->
                        val updatedReservation = reservation.copy(
                            confirmationNumber = serverReservation.confirmationNumber,
                            totalCost = serverReservation.totalCost
                        )
                        reservationDao.updateReservation(updatedReservation)
                    }
                }
            }
            
            Result.success(reservation)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
    
    suspend fun updateReservationStatus(
        reservationId: String,
        status: ReservationStatus
    ): Result<Unit> {
        return try {
            reservationDao.updateReservationStatus(reservationId, status, Date())
            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
    
    suspend fun checkAvailability(
        campsiteId: String,
        checkInDate: Date,
        checkOutDate: Date
    ): Result<AvailabilityCheck> {
        return try {
            // Check if we have recent data
            val recent = availabilityDao.getLatestAvailability(campsiteId, checkInDate, checkOutDate)
            val now = Date()
            val fiveMinutesAgo = Date(now.time - 5 * 60 * 1000)
            
            if (recent != null && recent.checkedAt.after(fiveMinutesAgo)) {
                return Result.success(recent)
            }
            
            // TODO: Implement actual availability checking via API
            // For now, create a mock check
            val check = AvailabilityCheck(
                id = UUID.randomUUID().toString(),
                campsiteId = campsiteId,
                checkInDate = checkInDate,
                checkOutDate = checkOutDate,
                isAvailable = false, // Default to false until real API call
                checkedAt = now
            )
            
            availabilityDao.insertAvailabilityCheck(check)
            Result.success(check)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
}

@Singleton
class UserRepository @Inject constructor(
    private val userPreferenceDao: UserPreferenceDao,
    private val apiService: SiteBookApiService,
    private val tokenManager: TokenManager
) {
    fun getUserPreferences(): Flow<UserPreference?> = userPreferenceDao.getUserPreferencesFlow()
    
    suspend fun updateUserPreferences(preferences: UserPreference): Result<Unit> {
        return try {
            userPreferenceDao.insertUserPreference(preferences)
            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
    
    suspend fun login(email: String, password: String): Result<AuthResponse> {
        return try {
            val request = UserLoginRequest(email, password)
            val response = apiService.login(request)
            
            if (response.isSuccessful) {
                response.body()?.let { authResponse ->
                    tokenManager.saveTokens(authResponse.token, authResponse.refreshToken)
                    Result.success(authResponse)
                } ?: Result.failure(Exception("Empty response body"))
            } else {
                Result.failure(Exception("Login failed: ${response.code()}"))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
    
    suspend fun register(
        email: String,
        password: String,
        firstName: String,
        lastName: String
    ): Result<AuthResponse> {
        return try {
            val request = UserRegistrationRequest(email, password, firstName, lastName)
            val response = apiService.register(request)
            
            if (response.isSuccessful) {
                response.body()?.let { authResponse ->
                    tokenManager.saveTokens(authResponse.token, authResponse.refreshToken)
                    Result.success(authResponse)
                } ?: Result.failure(Exception("Empty response body"))
            } else {
                Result.failure(Exception("Registration failed: ${response.code()}"))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
    
    suspend fun logout(): Result<Unit> {
        return try {
            tokenManager.getToken()?.let { token ->
                apiService.logout("Bearer $token")
            }
            tokenManager.clearTokens()
            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
}

// Extension functions for data conversion
private fun FacilityResponse.toCampground(): Campground {
    return Campground(
        id = facilityId,
        name = name,
        description = description ?: "",
        latitude = latitude,
        longitude = longitude,
        state = stateCode ?: "",
        parkName = organization?.firstOrNull()?.name,
        reservationUrl = reservationUrl,
        phoneNumber = phone,
        email = email,
        amenities = emptyList(), // Would need to parse from attributes
        activities = activities?.map { it.name } ?: emptyList(),
        imageUrls = media?.filter { it.type == "Image" }?.map { it.url } ?: emptyList()
    )
}

private fun CampsiteResponse.toCampsite(): Campsite {
    return Campsite(
        id = campsiteId,
        campgroundId = facilityId,
        siteNumber = name,
        siteType = type,
        maxOccupancy = 6, // Default, would need to parse from attributes
        accessibility = accessible,
        amenities = attributes?.map { "${it.name}: ${it.value}" } ?: emptyList()
    )
}

private fun Date.toIsoString(): String {
    return java.text.SimpleDateFormat("yyyy-MM-dd", Locale.US).format(this)
}