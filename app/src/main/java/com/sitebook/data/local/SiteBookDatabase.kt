package com.sitebook.data.local

import androidx.room.Database
import androidx.room.Room
import androidx.room.RoomDatabase
import androidx.room.TypeConverter
import androidx.room.TypeConverters
import android.content.Context
import com.google.gson.Gson
import com.google.gson.reflect.TypeToken
import com.sitebook.data.local.dao.*
import com.sitebook.data.local.entities.*
import java.util.Date

@TypeConverters(Converters::class)
@Database(
    entities = [
        Campground::class,
        Campsite::class,
        Reservation::class,
        AvailabilityCheck::class,
        UserPreference::class
    ],
    version = 1,
    exportSchema = true
)
abstract class SiteBookDatabase : RoomDatabase() {
    abstract fun campgroundDao(): CampgroundDao
    abstract fun campsiteDao(): CampsiteDao
    abstract fun reservationDao(): ReservationDao
    abstract fun availabilityDao(): AvailabilityDao
    abstract fun userPreferenceDao(): UserPreferenceDao

    companion object {
        const val DATABASE_NAME = "sitebook_database"
        
        @Volatile
        private var INSTANCE: SiteBookDatabase? = null

        fun getDatabase(context: Context): SiteBookDatabase {
            return INSTANCE ?: synchronized(this) {
                val instance = Room.databaseBuilder(
                    context.applicationContext,
                    SiteBookDatabase::class.java,
                    DATABASE_NAME
                )
                .fallbackToDestructiveMigration() // For development only
                .build()
                INSTANCE = instance
                instance
            }
        }
    }
}

class Converters {
    private val gson = Gson()
    
    @TypeConverter
    fun fromTimestamp(value: Long?): Date? {
        return value?.let { Date(it) }
    }

    @TypeConverter
    fun dateToTimestamp(date: Date?): Long? {
        return date?.time
    }

    @TypeConverter
    fun fromStringList(value: String?): List<String> {
        return if (value.isNullOrEmpty()) {
            emptyList()
        } else {
            gson.fromJson(value, object : TypeToken<List<String>>() {}.type) ?: emptyList()
        }
    }

    @TypeConverter
    fun fromListString(list: List<String>?): String {
        return gson.toJson(list ?: emptyList())
    }

    @TypeConverter
    fun fromReservationStatus(status: ReservationStatus): String {
        return status.name
    }

    @TypeConverter
    fun toReservationStatus(status: String): ReservationStatus {
        return ReservationStatus.valueOf(status)
    }
}