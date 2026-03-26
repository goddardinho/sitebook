package com.sitebook.data.local.dao

import androidx.room.*
import com.sitebook.data.local.entities.Reservation
import com.sitebook.data.local.entities.ReservationStatus
import kotlinx.coroutines.flow.Flow
import java.util.Date

@Dao
interface ReservationDao {
    
    @Query("SELECT * FROM reservations ORDER BY checkInDate DESC")
    fun getAllReservations(): Flow<List<Reservation>>
    
    @Query("SELECT * FROM reservations WHERE status = :status ORDER BY checkInDate ASC")
    fun getReservationsByStatus(status: ReservationStatus): Flow<List<Reservation>>
    
    @Query("SELECT * FROM reservations WHERE autoReserve = 1 AND status = :status")
    fun getAutoReserveReservations(status: ReservationStatus = ReservationStatus.MONITORING): Flow<List<Reservation>>
    
    @Query("SELECT * FROM reservations WHERE id = :reservationId")
    suspend fun getReservationById(reservationId: String): Reservation?
    
    @Query("""
        SELECT * FROM reservations 
        WHERE campsiteId = :campsiteId 
          AND checkInDate >= :fromDate 
          AND checkOutDate <= :toDate
        ORDER BY checkInDate ASC
    """)
    suspend fun getReservationsForCampsite(
        campsiteId: String,
        fromDate: Date,
        toDate: Date
    ): List<Reservation>
    
    @Query("""
        SELECT * FROM reservations 
        WHERE checkInDate >= :startDate 
          AND checkInDate <= :endDate
        ORDER BY checkInDate ASC
    """)
    suspend fun getReservationsInDateRange(
        startDate: Date,
        endDate: Date
    ): List<Reservation>
    
    @Query("""
        SELECT COUNT(*) FROM reservations 
        WHERE campsiteId = :campsiteId 
          AND status = :status
          AND (checkInDate BETWEEN :checkIn AND :checkOut 
               OR checkOutDate BETWEEN :checkIn AND :checkOut
               OR (checkInDate <= :checkIn AND checkOutDate >= :checkOut))
    """)
    suspend fun hasConflictingReservation(
        campsiteId: String,
        checkIn: Date,
        checkOut: Date,
        status: ReservationStatus = ReservationStatus.CONFIRMED
    ): Int
    
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertReservation(reservation: Reservation)
    
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertReservations(reservations: List<Reservation>)
    
    @Update
    suspend fun updateReservation(reservation: Reservation)
    
    @Query("UPDATE reservations SET status = :status WHERE id = :reservationId")
    suspend fun updateReservationStatus(reservationId: String, status: ReservationStatus)
    
    @Query("UPDATE reservations SET confirmationNumber = :confirmationNumber, status = :status WHERE id = :reservationId")
    suspend fun confirmReservation(
        reservationId: String, 
        confirmationNumber: String, 
        status: ReservationStatus = ReservationStatus.CONFIRMED
    )
    
    @Delete
    suspend fun deleteReservation(reservation: Reservation)
    
    @Query("DELETE FROM reservations WHERE id = :reservationId")
    suspend fun deleteReservationById(reservationId: String)
    
    @Query("DELETE FROM reservations WHERE status = :status")
    suspend fun deleteReservationsByStatus(status: ReservationStatus)
}