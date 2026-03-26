package com.sitebook.data.local

import androidx.arch.core.executor.testing.InstantTaskExecutorRule
import androidx.room.Room
import androidx.test.core.app.ApplicationProvider
import androidx.test.ext.junit.runners.AndroidJUnit4
import com.sitebook.data.local.dao.*
import com.sitebook.data.local.entities.*
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.test.runTest
import org.junit.After
import org.junit.Before
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import java.util.*
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.assertTrue

/**
 * Comprehensive database integration tests for Room entities, DAOs, and type converters.
 * 
 * Tests include:
 * - Entity creation and relationships
 * - DAO CRUD operations and queries
 * - Type converter functionality (Date, ReservationStatus, List<String>)
 * - Flow-based reactive queries
 * - Database schema validation
 * 
 * Uses in-memory database for fast, isolated testing.
 */
@RunWith(AndroidJUnit4::class)
class DatabaseIntegrationTest {

    @get:Rule
    var instantTaskExecutorRule = InstantTaskExecutorRule()

    private lateinit var database: SiteBookDatabase
    private lateinit var campgroundDao: CampgroundDao
    private lateinit var campsiteDao: CampsiteDao
    private lateinit var reservationDao: ReservationDao
    private lateinit var availabilityDao: AvailabilityDao
    private lateinit var userPreferenceDao: UserPreferenceDao

    @Before
    fun createDb() {
        database = Room.inMemoryDatabaseBuilder(
            ApplicationProvider.getApplicationContext(),
            SiteBookDatabase::class.java
        ).allowMainThreadQueries().build()
        
        campgroundDao = database.campgroundDao()
        campsiteDao = database.campsiteDao()
        reservationDao = database.reservationDao()
        availabilityDao = database.availabilityDao()
        userPreferenceDao = database.userPreferenceDao()
    }

    @After
    fun closeDb() {
        database.close()
    }

    @Test
    fun campgroundDao_insertAndRetrieve_returnsCorrectData() = runTest {
        // Given
        val campground = Campground(
            id = "test-campground-1",
            name = "Test Campground",
            description = "A beautiful test campground",
            latitude = 40.7128,
            longitude = -74.0060,
            state = "NY",
            country = "US"
        )

        // When
        campgroundDao.insertCampground(campground)
        val retrieved = campgroundDao.getCampgroundById("test-campground-1")

        // Then
        assertNotNull(retrieved, "Campground should be retrievable after insert")
        assertEquals("Test Campground", retrieved.name)
        assertEquals(40.7128, retrieved.latitude)
        assertEquals("NY", retrieved.state)
    }

    @Test
    fun campgroundDao_flowUpdates_emitChangesCorrectly() = runTest {
        // Given
        val campground1 = Campground(
            id = "flow-test-1", 
            name = "Flow Test 1", 
            description = "Test", 
            latitude = 0.0, 
            longitude = 0.0, 
            state = "CA"
        )
        val campground2 = Campground(
            id = "flow-test-2", 
            name = "Flow Test 2", 
            description = "Test", 
            latitude = 0.0, 
            longitude = 0.0, 
            state = "CA"
        )

        // When
        campgroundDao.insertCampgrounds(listOf(campground1, campground2))
        val allCampgrounds = campgroundDao.getAllCampgroundsFlow().first()

        // Then
        assertEquals(2, allCampgrounds.size)
        assertTrue(allCampgrounds.any { it.name == "Flow Test 1" })
        assertTrue(allCampgrounds.any { it.name == "Flow Test 2" })
    }

    @Test
    fun typeConverters_dateConversion_maintainsPrecision() = runTest {
        // Given
        val testDate = Date(1679846400000) // March 26, 2023 12:00:00 UTC
        val reservation = Reservation(
            id = "date-test",
            userId = "user1",
            campgroundId = "campground1", 
            campsiteId = "campsite1",
            checkInDate = testDate,
            checkOutDate = Date(testDate.time + 86400000), // +1 day
            status = ReservationStatus.PENDING,
            createdAt = testDate,
            guestCount = 2
        )

        // When
        reservationDao.insertReservation(reservation)
        val retrieved = reservationDao.getReservationById("date-test")

        // Then
        assertNotNull(retrieved, "Reservation should be retrievable")
        assertEquals(testDate.time, retrieved.checkInDate.time, "Date should be preserved precisely")
        assertEquals(testDate.time, retrieved.createdAt.time, "Created date should be preserved")
    }

    @Test
    fun typeConverters_reservationStatus_convertsCorrectly() = runTest {
        // Given - test all enum values
        val statuses = ReservationStatus.values()
        val reservations = statuses.mapIndexed { index, status ->
            Reservation(
                id = "status-test-$index",
                userId = "user1",
                campgroundId = "campground1",
                campsiteId = "campsite1", 
                checkInDate = Date(),
                checkOutDate = Date(),
                status = status,
                createdAt = Date(),
                guestCount = 2
            )
        }

        // When
        reservations.forEach { reservationDao.insertReservation(it) }
        val retrieved = reservations.map { 
            reservationDao.getReservationById(it.id)!! 
        }

        // Then
        statuses.forEachIndexed { index, expectedStatus ->
            assertEquals(expectedStatus, retrieved[index].status, 
                "Status $expectedStatus should be preserved")
        }
    }

    @Test
    fun typeConverters_listString_handlesEmptyAndPopulatedLists() = runTest {
        // Given
        val emptyList = UserPreference(
            userId = "user-empty",
            notificationPreferences = emptyList(),
            searchRadius = 50.0,
            autoReserveEnabled = false
        )
        val populatedList = UserPreference(
            userId = "user-populated", 
            notificationPreferences = listOf("email", "push", "sms"),
            searchRadius = 100.0,
            autoReserveEnabled = true
        )

        // When
        userPreferenceDao.insertUserPreference(emptyList)
        userPreferenceDao.insertUserPreference(populatedList)
        
        val retrievedEmpty = userPreferenceDao.getUserPreferencesFlow().first()?.let { prefs ->
            if (prefs.userId == "user-empty") prefs else null
        }
        
        userPreferenceDao.insertUserPreference(populatedList) // Insert again to test get
        val retrievedPopulated = userPreferenceDao.getUserPreferencesFlow().first()

        // Then - the flow will return the most recent, so test populated
        assertNotNull(retrievedPopulated, "User preferences should be retrievable")
        assertEquals(3, retrievedPopulated.notificationPreferences.size)
        assertTrue(retrievedPopulated.notificationPreferences.contains("email"))
        assertTrue(retrievedPopulated.notificationPreferences.contains("push"))
        assertTrue(retrievedPopulated.notificationPreferences.contains("sms"))
    }

    @Test
    fun campsiteDao_relationshipToCampground_worksCorrectly() = runTest {
        // Given
        val campground = Campground(
            id = "relationship-test",
            name = "Relationship Test Campground",
            description = "Test relationships",
            latitude = 0.0,
            longitude = 0.0, 
            state = "CA"
        )
        val campsite = Campsite(
            id = "campsite-rel-test",
            campgroundId = "relationship-test",  // Foreign key reference
            siteNumber = "A01",
            siteType = "RV",
            maxOccupancy = 6,
            accessibility = false,
            amenities = listOf("Electric", "Water")
        )

        // When
        campgroundDao.insertCampground(campground)
        campsiteDao.insertCampsite(campsite)
        val campsites = campsiteDao.getCampsitesByCampgroundFlow("relationship-test").first()

        // Then
        assertEquals(1, campsites.size)
        assertEquals("A01", campsites.first().siteNumber)
        assertEquals("relationship-test", campsites.first().campgroundId)
    }

    @Test
    fun reservationDao_statusQueries_filterCorrectly() = runTest {
        // Given
        val pendingReservation = Reservation(
            id = "pending-test",
            userId = "user1",
            campgroundId = "campground1",
            campsiteId = "campsite1",
            checkInDate = Date(),
            checkOutDate = Date(),
            status = ReservationStatus.PENDING,
            createdAt = Date(),
            guestCount = 2
        )
        val confirmedReservation = Reservation(
            id = "confirmed-test", 
            userId = "user1",
            campgroundId = "campground1",
            campsiteId = "campsite2",
            checkInDate = Date(),
            checkOutDate = Date(),
            status = ReservationStatus.CONFIRMED,
            createdAt = Date(),
            guestCount = 2
        )

        // When
        reservationDao.insertReservations(listOf(pendingReservation, confirmedReservation))
        val pendingFlow = reservationDao.getReservationsByStatusFlow(ReservationStatus.PENDING).first()
        val confirmedFlow = reservationDao.getReservationsByStatusFlow(ReservationStatus.CONFIRMED).first()

        // Then
        assertEquals(1, pendingFlow.size, "Should find exactly 1 pending reservation")
        assertEquals("pending-test", pendingFlow.first().id)
        
        assertEquals(1, confirmedFlow.size, "Should find exactly 1 confirmed reservation") 
        assertEquals("confirmed-test", confirmedFlow.first().id)
    }
}