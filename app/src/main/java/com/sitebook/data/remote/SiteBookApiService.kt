package com.sitebook.data.remote

import com.sitebook.data.remote.models.*
import retrofit2.Response
import retrofit2.http.*

/**
 * SiteBook API service for custom backend operations
 */
interface SiteBookApiService {
    
    @GET("campgrounds")
    suspend fun getCampgrounds(
        @Query("latitude") latitude: Double? = null,
        @Query("longitude") longitude: Double? = null,
        @Query("radius") radius: Double? = null,
        @Query("state") state: String? = null,
        @Query("limit") limit: Int? = null
    ): Response<ApiResponse<List<CampgroundDto>>>
    
    @GET("campgrounds/{id}")
    suspend fun getCampgroundById(
        @Path("id") campgroundId: String
    ): Response<ApiResponse<CampgroundDto>>
    
    @GET("campgrounds/{id}/campsites")
    suspend fun getCampsitesByCampground(
        @Path("id") campgroundId: String
    ): Response<ApiResponse<List<CampsiteDto>>>
    
    @POST("availability/check")
    suspend fun checkAvailability(
        @Body request: AvailabilityCheckRequest
    ): Response<ApiResponse<AvailabilityCheckDto>>
    
    @POST("reservations")
    suspend fun createReservation(
        @Body request: ReservationRequest
    ): Response<ApiResponse<ReservationDto>>
    
    @GET("reservations")
    suspend fun getUserReservations(): Response<ApiResponse<List<ReservationDto>>>
    
    @GET("reservations/{id}")
    suspend fun getReservationById(
        @Path("id") reservationId: String
    ): Response<ApiResponse<ReservationDto>>
    
    @PUT("reservations/{id}/cancel")
    suspend fun cancelReservation(
        @Path("id") reservationId: String
    ): Response<ApiResponse<ReservationDto>>
    
    @POST("monitoring/start")
    suspend fun startMonitoring(
        @Body request: MonitoringRequest
    ): Response<ApiResponse<MonitoringResponseDto>>
    
    @POST("monitoring/stop")
    suspend fun stopMonitoring(
        @Body request: StopMonitoringRequest
    ): Response<ApiResponse<Unit>>
    
    @GET("user/preferences")
    suspend fun getUserPreferences(): Response<ApiResponse<UserPreferenceDto>>
    
    @PUT("user/preferences")
    suspend fun updateUserPreferences(
        @Body preferences: UserPreferenceDto
    ): Response<ApiResponse<UserPreferenceDto>>
}