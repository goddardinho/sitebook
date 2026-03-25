package com.sitebook.data.remote.models

import com.google.gson.annotations.SerializedName

// Recreation.gov API Models
data class RecreationApiResponse<T>(
    @SerializedName("RECDATA") val data: List<T>,
    @SerializedName("METADATA") val metadata: ApiMetadata
)

data class ApiMetadata(
    @SerializedName("RESULTS") val results: ResultsMetadata
)

data class ResultsMetadata(
    @SerializedName("TOTAL_COUNT") val totalCount: Int,
    @SerializedName("CURRENT_COUNT") val currentCount: Int
)

data class FacilityResponse(
    @SerializedName("FacilityID") val facilityId: String,
    @SerializedName("FacilityName") val name: String,
    @SerializedName("FacilityDescription") val description: String?,
    @SerializedName("FacilityLatitude") val latitude: Double,
    @SerializedName("FacilityLongitude") val longitude: Double,
    @SerializedName("FacilityPhone") val phone: String?,
    @SerializedName("FacilityEmail") val email: String?,
    @SerializedName("FacilityReservationURL") val reservationUrl: String?,
    @SerializedName("FacilityMapURL") val mapUrl: String?,
    @SerializedName("FacilityAdaAccess") val adaAccess: String?,
    @SerializedName("AddressStateCode") val stateCode: String?,
    @SerializedName("AddressCountryCode") val countryCode: String?,
    @SerializedName("ORGANIZATION") val organization: List<OrganizationResponse>?,
    @SerializedName("ACTIVITY") val activities: List<ActivityResponse>?,
    @SerializedName("FACILITYADDRESS") val addresses: List<AddressResponse>?,
    @SerializedName("MEDIA") val media: List<MediaResponse>?
)

data class CampsiteResponse(
    @SerializedName("CampsiteID") val campsiteId: String,
    @SerializedName("FacilityID") val facilityId: String,
    @SerializedName("CampsiteName") val name: String,
    @SerializedName("CampsiteType") val type: String,
    @SerializedName("CampsiteAccessible") val accessible: Boolean,
    @SerializedName("CampsiteReservable") val reservable: String,
    @SerializedName("Loop") val loop: String?,
    @SerializedName("TypeOfUse") val typeOfUse: String?,
    @SerializedName("ATTRIBUTES") val attributes: List<AttributeResponse>?
)

data class OrganizationResponse(
    @SerializedName("OrgID") val orgId: String,
    @SerializedName("OrgName") val name: String
)

data class ActivityResponse(
    @SerializedName("ActivityID") val activityId: String,
    @SerializedName("ActivityName") val name: String
)

data class AddressResponse(
    @SerializedName("FacilityAddressID") val addressId: String,
    @SerializedName("AddressStateCode") val stateCode: String,
    @SerializedName("AddressCountryCode") val countryCode: String,
    @SerializedName("City") val city: String?,
    @SerializedName("PostalCode") val postalCode: String?
)

data class MediaResponse(
    @SerializedName("MediaID") val mediaId: String,
    @SerializedName("MediaType") val type: String,
    @SerializedName("URL") val url: String,
    @SerializedName("Title") val title: String?,
    @SerializedName("Description") val description: String?
)

data class AttributeResponse(
    @SerializedName("AttributeID") val attributeId: String,
    @SerializedName("AttributeName") val name: String,
    @SerializedName("AttributeValue") val value: String?
)

// Recreation.gov Availability API Models
data class AvailabilityResponse(
    @SerializedName("campsites") val campsites: Map<String, Map<String, AvailabilityDay>>
)

data class AvailabilityDay(
    @SerializedName("status") val status: String, // Available, Reserved, etc.
    @SerializedName("reservation_date") val reservationDate: String?,
    @SerializedName("min_stay") val minStay: Int?,
    @SerializedName("max_stay") val maxStay: Int?
)

// Internal API Models (for SiteBook backend)
data class UserRegistrationRequest(
    val email: String,
    val password: String,
    val firstName: String,
    val lastName: String
)

data class UserLoginRequest(
    val email: String,
    val password: String
)

data class AuthResponse(
    val token: String,
    val refreshToken: String,
    val user: UserResponse,
    val expiresIn: Long
)

data class UserResponse(
    val id: String,
    val email: String,
    val firstName: String,
    val lastName: String,
    val createdAt: String,
    val isVerified: Boolean
)

data class ReservationRequest(
    val campsiteId: String,
    val checkInDate: String, // ISO date format
    val checkOutDate: String,
    val guestCount: Int,
    val autoReserve: Boolean = false,
    val maxPrice: Double? = null,
    val specialRequests: String? = null
)

data class ReservationResponse(
    val id: String,
    val campsiteId: String,
    val checkInDate: String,
    val checkOutDate: String,
    val status: String,
    val confirmationNumber: String?,
    val totalCost: Double?,
    val createdAt: String
)

data class NotificationRequest(
    val userId: String,
    val type: String,
    val title: String,
    val message: String,
    val data: Map<String, String>? = null
)

// Additional Models for complete API support
data class CampgroundDto(
    val id: String,
    val name: String,
    val description: String,
    val latitude: Double,
    val longitude: Double,
    val state: String,
    val country: String = "US",
    @SerializedName("park_name") val parkName: String?,
    @SerializedName("reservation_url") val reservationUrl: String?,
    @SerializedName("phone_number") val phoneNumber: String?,
    val email: String?,
    val amenities: List<String>,
    val activities: List<String>,
    @SerializedName("image_urls") val imageUrls: List<String>,
    @SerializedName("price_range") val priceRange: String?,
    val accessibility: Boolean = false
)

data class CampsiteDto(
    val id: String,
    @SerializedName("campground_id") val campgroundId: String,
    @SerializedName("site_number") val siteNumber: String,
    @SerializedName("site_type") val siteType: String,
    @SerializedName("max_occupancy") val maxOccupancy: Int,
    val accessibility: Boolean = false,
    val amenities: List<String>,
    @SerializedName("price_per_night") val pricePerNight: Double?,
    val hookups: List<String>,
    val dimensions: String?
)

data class AvailabilityCheckDto(
    val id: String,
    @SerializedName("campsite_id") val campsiteId: String,
    @SerializedName("check_in_date") val checkInDate: String,
    @SerializedName("check_out_date") val checkOutDate: String,
    @SerializedName("is_available") val isAvailable: Boolean,
    val price: Double?
)

data class MonitoringResponseDto(
    val id: String,
    @SerializedName("monitoring_started") val monitoringStarted: Boolean,
    val message: String
)

data class UserPreferenceDto(
    val id: String,
    @SerializedName("notifications_enabled") val notificationsEnabled: Boolean,
    @SerializedName("auto_reserve_enabled") val autoReserveEnabled: Boolean,
    @SerializedName("max_auto_reserve_price") val maxAutoReservePrice: Double?,
    @SerializedName("preferred_radius") val preferredRadius: Double,
    @SerializedName("biometric_auth_enabled") val biometricAuthEnabled: Boolean
)

data class MonitoringRequest(
    @SerializedName("campsite_id") val campsiteId: String,
    @SerializedName("check_in_date") val checkInDate: String,
    @SerializedName("check_out_date") val checkOutDate: String,
    @SerializedName("auto_reserve") val autoReserve: Boolean = false,
    @SerializedName("max_price") val maxPrice: Double?
)

data class StopMonitoringRequest(
    @SerializedName("campsite_id") val campsiteId: String
)

data class AvailabilityCheckRequest(
    @SerializedName("campsite_id") val campsiteId: String,
    @SerializedName("check_in_date") val checkInDate: String,
    @SerializedName("check_out_date") val checkOutDate: String
)

data class ApiResponse<T>(
    val success: Boolean,
    val data: T?,
    val message: String?,
    val error: String?
)

// Aliases for compatibility with existing names
typealias RecreationGovResponse<T> = RecreationApiResponse<T>
typealias RecreationGovMetadata = ApiMetadata
typealias RecreationGovResults = ResultsMetadata
typealias FacilityDto = FacilityResponse
typealias ActivityDto = ActivityResponse
typealias AddressDto = AddressResponse
typealias OrganizationDto = OrganizationResponse
typealias ReservationDto = ReservationResponse
typealias RecreationGovAvailabilityResponse = AvailabilityResponse
)

data class ErrorResponse(
    val error: String,
    val message: String,
    val timestamp: String,
    val path: String
)