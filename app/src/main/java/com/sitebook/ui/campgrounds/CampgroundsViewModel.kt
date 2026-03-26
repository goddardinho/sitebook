package com.sitebook.ui.campgrounds

import androidx.lifecycle.LiveData
import androidx.lifecycle.MutableLiveData
import androidx.lifecycle.ViewModel
import androidx.lifecycle.asLiveData
import androidx.lifecycle.viewModelScope
import com.sitebook.data.CampgroundRepository
import com.sitebook.data.local.entities.Campground
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.flatMapLatest
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class CampgroundsViewModel @Inject constructor(
    private val campgroundRepository: CampgroundRepository
) : ViewModel() {

    private val _isLoading = MutableLiveData<Boolean>()
    val isLoading: LiveData<Boolean> = _isLoading

    private val _errorMessage = MutableLiveData<String?>()
    val errorMessage: LiveData<String?> = _errorMessage

    private val searchQuery = MutableStateFlow<String?>(null)
    private val selectedState = MutableStateFlow<String?>(null)

    val campgrounds: LiveData<List<Campground>> = searchQuery.flatMapLatest { query ->
        campgroundRepository.searchCampgrounds(query, selectedState.value)
    }.asLiveData()

    fun loadCampgrounds() {
        searchQuery.value = null
        refreshCampgroundsFromApi()
    }

    fun searchCampgrounds(query: String) {
        searchQuery.value = query
    }

    fun filterByState(state: String?) {
        selectedState.value = state
    }

    fun refreshCampgroundsFromApi() {
        viewModelScope.launch {
            _isLoading.value = true
            try {
                // TODO: Add API key management
                val apiKey = "YOUR_RECREATION_GOV_API_KEY"
                campgroundRepository.refreshCampgroundsFromApi(apiKey = apiKey)
            } catch (e: Exception) {
                _errorMessage.value = e.message
            } finally {
                _isLoading.value = false
            }
        }
    }

    fun toggleMonitoring(campgroundId: String, isMonitored: Boolean) {
        viewModelScope.launch {
            try {
                campgroundRepository.updateMonitoringStatus(campgroundId, isMonitored)
            } catch (e: Exception) {
                _errorMessage.value = "Failed to update monitoring status"
            }
        }
    }

    fun clearError() {
        _errorMessage.value = null
    }
}