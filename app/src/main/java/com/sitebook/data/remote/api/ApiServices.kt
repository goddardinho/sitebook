package com.sitebook.data.remote.api

import com.sitebook.data.remote.models.*
import retrofit2.Response
import retrofit2.http.*

interface RecreationGovService {
    @GET("facilities")
    suspend fun getFacilities(
        @Query("latitude") latitude: Double? = null,
        @Query("longitude") longitude: Double? = null,
        @Query("radius") radius: Double? = null,
        @Query("state") state: String? = null,
        @Query("activity") activity: String? = null,
        @Query("limit") limit: Int = 50,
        @Query("offset") offset: Int = 0,
        @Query("apikey") apiKey: String
    ): Response<RecreationApiResponse<FacilityResponse>>

    @GET("facilities/{facilityId}")
    suspend fun getFacilityById(
        @Path("facilityId") facilityId: String,
        @Query("apikey") apiKey: String
    ): Response<RecreationApiResponse<FacilityResponse>>

    @GET("campsites")
    suspend fun getCampsites(
        @Query("facilityId") facilityId: String,
        @Query("limit") limit: Int = 50,
        @Query("offset") offset: Int = 0,
        @Query("apikey") apiKey: String
    ): Response<RecreationApiResponse<CampsiteResponse>>

    @GET("campsites/{campsiteId}")
    suspend fun getCampsiteById(
        @Path("campsiteId") campsiteId: String,
        @Query("apikey") apiKey: String
    ): Response<RecreationApiResponse<CampsiteResponse>>

    @GET("availability/facility/{facilityId}/{year}/{month}")
    suspend fun getAvailability(
        @Path("facilityId") facilityId: String,
        @Path("year") year: String,
        @Path("month") month: String,
        @Query("apikey") apiKey: String
    ): Response<AvailabilityResponse>
}

interface SiteBookApiService {
    // Authentication endpoints
    @POST("auth/register")
    suspend fun register(
        @Body request: UserRegistrationRequest
    ): Response<AuthResponse>

    @POST("auth/login")
    suspend fun login(
        @Body request: UserLoginRequest
    ): Response<AuthResponse>

    @POST("auth/refresh")
    suspend fun refreshToken(
        @Header("Authorization") refreshToken: String
    ): Response<AuthResponse>

    @POST("auth/logout")
    suspend fun logout(
        @Header("Authorization") token: String
    ): Response<Unit>

    // User profile endpoints
    @GET("user/profile")
    suspend fun getUserProfile(
        @Header("Authorization") token: String
    ): Response<UserResponse>

    @PUT("user/profile")
    suspend fun updateUserProfile(
        @Header("Authorization") token: String,
        @Body user: UserResponse
    ): Response<UserResponse>

    // Reservation endpoints
    @GET("reservations")
    suspend fun getReservations(
        @Header("Authorization") token: String,
        @Query("status") status: String? = null,
        @Query("limit") limit: Int = 50,
        @Query("offset") offset: Int = 0
    ): Response<List<ReservationResponse>>

    @POST("reservations")
    suspend fun createReservation(
        @Header("Authorization") token: String,
        @Body request: ReservationRequest
    ): Response<ReservationResponse>

    @GET("reservations/{reservationId}")
    suspend fun getReservationById(
        @Header("Authorization") token: String,
        @Path("reservationId") reservationId: String
    ): Response<ReservationResponse>

    @PUT("reservations/{reservationId}")
    suspend fun updateReservation(
        @Header("Authorization") token: String,
        @Path("reservationId") reservationId: String,
        @Body request: ReservationRequest
    ): Response<ReservationResponse>

    @DELETE("reservations/{reservationId}")
    suspend fun cancelReservation(
        @Header("Authorization") token: String,
        @Path("reservationId") reservationId: String
    ): Response<Unit>

    // Monitoring endpoints
    @POST("monitoring/start")
    suspend fun startMonitoring(
        @Header("Authorization") token: String,
        @Body request: ReservationRequest
    ): Response<ReservationResponse>

    @POST("monitoring/{reservationId}/stop")
    suspend fun stopMonitoring(
        @Header("Authorization") token: String,
        @Path("reservationId") reservationId: String
    ): Response<Unit>

    @GET("monitoring/status")
    suspend fun getMonitoringStatus(
        @Header("Authorization") token: String
    ): Response<List<ReservationResponse>>

    // Notification endpoints
    @POST("notifications/register-device")
    suspend fun registerDevice(
        @Header("Authorization") token: String,
        @Body deviceToken: String
    ): Response<Unit>

    @POST("notifications/send")
    suspend fun sendNotification(
        @Header("Authorization") token: String,
        @Body request: NotificationRequest
    ): Response<Unit>
}

interface CampgroundSearchService {
    @GET("search/campgrounds")
    suspend fun searchCampgrounds(
        @Query("q") query: String,
        @Query("latitude") latitude: Double? = null,
        @Query("longitude") longitude: Double? = null,
        @Query("radius") radius: Double? = null,
        @Query("state") state: String? = null,
        @Query("amenities") amenities: String? = null,
        @Query("limit") limit: Int = 50,
        @Query("offset") offset: Int = 0
    ): Response<List<FacilityResponse>>

    @GET("campgrounds/{campgroundId}/availability")
    suspend fun checkCampgroundAvailability(
        @Path("campgroundId") campgroundId: String,
        @Query("start_date") startDate: String,
        @Query("end_date") endDate: String,
        @Query("site_type") siteType: String? = null
    ): Response<AvailabilityResponse>

    @GET("campsites/{campsiteId}/availability")
    suspend fun checkCampsiteAvailability(
        @Path("campsiteId") campsiteId: String,
        @Query("start_date") startDate: String,
        @Query("end_date") endDate: String
    ): Response<Map<String, AvailabilityDay>>
}