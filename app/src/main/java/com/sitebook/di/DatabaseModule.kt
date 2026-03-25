package com.sitebook.di

import android.content.Context
import androidx.room.Room
import com.sitebook.data.local.SiteBookDatabase
import com.sitebook.data.local.dao.*
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.android.qualifiers.ApplicationContext
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
object DatabaseModule {

    @Provides
    @Singleton
    fun provideDatabase(@ApplicationContext context: Context): SiteBookDatabase {
        return Room.databaseBuilder(
            context.applicationContext,
            SiteBookDatabase::class.java,
            SiteBookDatabase.DATABASE_NAME
        )
        .fallbackToDestructiveMigration()
        .build()
    }

    @Provides
    fun provideCampgroundDao(database: SiteBookDatabase): CampgroundDao {
        return database.campgroundDao()
    }

    @Provides
    fun provideCampsiteDao(database: SiteBookDatabase): CampsiteDao {
        return database.campsiteDao()
    }

    @Provides
    fun provideReservationDao(database: SiteBookDatabase): ReservationDao {
        return database.reservationDao()
    }

    @Provides
    fun provideAvailabilityDao(database: SiteBookDatabase): AvailabilityDao {
        return database.availabilityDao()
    }

    @Provides
    fun provideUserPreferenceDao(database: SiteBookDatabase): UserPreferenceDao {
        return database.userPreferenceDao()
    }
}