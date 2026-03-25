package com.sitebook.data.local.entities

import androidx.room.Entity
import androidx.room.PrimaryKey
import android.os.Parcelable
import kotlinx.parcelize.Parcelize
import java.util.Date

@Parcelize
@Entity(tableName = "campgrounds")
data class Campground(
    @PrimaryKey val id: String,
    val name: String,
    val description: String,
    val latitude: Double,
    val longitude: Double,
    val state: String,
    val country: String = "US",
    val parkName: String? = null,
    val reservationUrl: String? = null,
    val phoneNumber: String? = null,
    val email: String? = null,
    val amenities: List<String> = emptyList(),
    val activities: List<String> = emptyList(),
    val imageUrls: List<String> = emptyList(),
    val priceRange: String? = null,
    val accessibility: Boolean = false,
    val isMonitored: Boolean = false,
    val lastUpdated: Date = Date(),
    val createdAt: Date = Date()
) : Parcelable

@Parcelize
@Entity(tableName = "campsites")
data class Campsite(
    @PrimaryKey val id: String,
    val campgroundId: String,
    val siteNumber: String,
    val siteType: String, // RV, Tent, Cabin, etc.
    val maxOccupancy: Int,
    val accessibility: Boolean = false,
    val amenities: List<String> = emptyList(),
    val pricePerNight: Double? = null,
    val hookups: List<String> = emptyList(), // Electric, Water, Sewer
    val dimensions: String? = null, // Site dimensions
    val isMonitored: Boolean = false,
    val lastChecked: Date = Date(),
    val createdAt: Date = Date()
) : Parcelable

@Parcelize
@Entity(tableName = "reservations")
data class Reservation(
    @PrimaryKey val id: String,
    val campsiteId: String,
    val campgroundId: String,
    val userId: String,
    val checkInDate: Date,
    val checkOutDate: Date,
    val status: ReservationStatus,
    val totalCost: Double? = null,
    val confirmationNumber: String? = null,
    val guestCount: Int,
    val specialRequests: String? = null,
    val autoReserve: Boolean = false,
    val maxPrice: Double? = null,
    val createdAt: Date = Date(),
    val updatedAt: Date = Date()
) : Parcelable

enum class ReservationStatus {
    PENDING,
    CONFIRMED,
    CANCELLED,
    MONITORING,
    FAILED,
    EXPIRED
}

@Parcelize
@Entity(tableName = "availability_checks")
data class AvailabilityCheck(
    @PrimaryKey val id: String,
    val campsiteId: String,
    val checkInDate: Date,
    val checkOutDate: Date,
    val isAvailable: Boolean,
    val price: Double? = null,
    val checkedAt: Date = Date()
) : Parcelable

@Parcelize
@Entity(tableName = "user_preferences")
data class UserPreference(
    @PrimaryKey val id: String = "user_prefs",
    val notificationsEnabled: Boolean = true,
    val autoReserveEnabled: Boolean = false,
    val maxAutoReservePrice: Double? = null,
    val preferredRadius: Double = 50.0, // miles
    val biometricAuthEnabled: Boolean = false,
    val checkIntervalMinutes: Int = 15,
    val updatedAt: Date = Date()
) : Parcelable