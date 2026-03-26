package com.sitebook.data.remote

import com.sitebook.data.remote.models.*
import retrofit2.Response
import retrofit2.http.*

/**
 * Recreation.gov API service for federal campground data
 */
interface RecreationGovApiService {
    
    @GET("facilities")
    suspend fun getFacilities(
        @Query("activity") activity: String = "CAMPING",
        @Query("latitude") latitude: Double? = null,
        @Query("longitude") longitude: Double? = null,
        @Query("radius") radius: Double? = null,
        @Query("state") state: String? = null,
        @Query("limit") limit: Int = 50,
        @Query("offset") offset: Int = 0
    ): Response<RecreationGovResponse<List<FacilityDto>>>
    
    @GET("facilities/{facilityId}")
    suspend fun getFacilityById(
        @Path("facilityId") facilityId: String
    ): Response<RecreationGovResponse<FacilityDto>>
    
    @GET("facilities/{facilityId}/campsites")
    suspend fun getCampsites(
        @Path("facilityId") facilityId: String,
        @Query("limit") limit: Int = 50,
        @Query("offset") offset: Int = 0
    ): Response<RecreationGovResponse<List<CampsiteDto>>>
    
    @GET("facilities/{facilityId}/availability")
    suspend fun getAvailability(
        @Path("facilityId") facilityId: String,
        @Query("start_date") startDate: String, // YYYY-MM-DD format
        @Query("end_date") endDate: String // YYYY-MM-DD format
    ): Response<RecreationGovAvailabilityResponse>
    
    @GET("facilities/{facilityId}/activities")
    suspend fun getFacilityActivities(
        @Path("facilityId") facilityId: String
    ): Response<RecreationGovResponse<List<ActivityDto>>>
    
    @GET("organizations")
    suspend fun getOrganizations(
        @Query("limit") limit: Int = 50,
        @Query("offset") offset: Int = 0
    ): Response<RecreationGovResponse<List<OrganizationDto>>>
    
    @GET("organizations/{organizationId}")
    suspend fun getOrganizationById(
        @Path("organizationId") organizationId: String
    ): Response<RecreationGovResponse<OrganizationDto>>
}