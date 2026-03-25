package com.sitebook.ui.reservations

import androidx.lifecycle.LiveData
import androidx.lifecycle.MutableLiveData
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.sitebook.data.Repository
import com.sitebook.data.local.entities.Reservation
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class ReservationsViewModel @Inject constructor(
    private val repository: Repository
) : ViewModel() {

    private val _reservations = MutableLiveData<List<Reservation>>()
    val reservations: LiveData<List<Reservation>> = _reservations

    private val _isLoading = MutableLiveData<Boolean>()
    val isLoading: LiveData<Boolean> = _isLoading

    private val _error = MutableLiveData<String?>()
    val error: LiveData<String?> = _error

    init {
        loadReservations()
    }

    fun loadReservations() {
        viewModelScope.launch {
            _isLoading.value = true
            try {
                repository.getAllReservations().collect { reservationList ->
                    _reservations.value = reservationList
                }
            } catch (e: Exception) {
                _error.value = "Failed to load reservations: ${e.message}"
            } finally {
                _isLoading.value = false
            }
        }
    }

    fun cancelReservation(reservationId: String) {
        viewModelScope.launch {
            try {
                repository.cancelReservation(reservationId)
                loadReservations() // Refresh the list
            } catch (e: Exception) {
                _error.value = "Failed to cancel reservation: ${e.message}"
            }
        }
    }

    fun clearError() {
        _error.value = null
    }
}