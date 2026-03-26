package com.sitebook.ui.profile

import androidx.lifecycle.LiveData
import androidx.lifecycle.MutableLiveData
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.sitebook.data.Repository
import com.sitebook.data.local.entities.UserPreference
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class ProfileViewModel @Inject constructor(
    private val repository: Repository
) : ViewModel() {

    private val _userPreferences = MutableLiveData<UserPreference>()
    val userPreferences: LiveData<UserPreference> = _userPreferences

    private val _isLoading = MutableLiveData<Boolean>()
    val isLoading: LiveData<Boolean> = _isLoading

    init {
        loadUserPreferences()
    }

    private fun loadUserPreferences() {
        viewModelScope.launch {
            _isLoading.value = true
            try {
                repository.getUserPreferences().collect { preferences ->
                    _userPreferences.value = preferences
                }
            } catch (e: Exception) {
                // Handle error - maybe set default preferences
                _userPreferences.value = UserPreference()
            } finally {
                _isLoading.value = false
            }
        }
    }

    fun updateNotificationSettings(enabled: Boolean) {
        viewModelScope.launch {
            val current = _userPreferences.value ?: UserPreference()
            val updated = current.copy(notificationsEnabled = enabled)
            repository.updateUserPreferences(updated)
            _userPreferences.value = updated
        }
    }

    fun updateAutoReserveSettings(enabled: Boolean) {
        viewModelScope.launch {
            val current = _userPreferences.value ?: UserPreference()
            val updated = current.copy(autoReserveEnabled = enabled)
            repository.updateUserPreferences(updated)
            _userPreferences.value = updated
        }
    }

    fun updateBiometricSettings(enabled: Boolean) {
        viewModelScope.launch {
            val current = _userPreferences.value ?: UserPreference()
            val updated = current.copy(biometricAuthEnabled = enabled)
            repository.updateUserPreferences(updated)
            _userPreferences.value = updated
        }
    }

    fun updatePreferredRadius(radius: Double) {
        viewModelScope.launch {
            val current = _userPreferences.value ?: UserPreference()
            val updated = current.copy(preferredRadius = radius)
            repository.updateUserPreferences(updated)
            _userPreferences.value = updated
        }
    }

    fun updateMaxPrice(maxPrice: Double?) {
        viewModelScope.launch {
            val current = _userPreferences.value ?: UserPreference()
            val updated = current.copy(maxAutoReservePrice = maxPrice)
            repository.updateUserPreferences(updated)
            _userPreferences.value = updated
        }
    }

    fun signOut() {
        viewModelScope.launch {
            repository.signOut()
        }
    }
}