package com.sitebook.ui

import android.os.Bundle
import androidx.activity.viewModels
import androidx.appcompat.app.AppCompatActivity
import androidx.navigation.fragment.NavHostFragment
import androidx.navigation.ui.AppBarConfiguration
import androidx.navigation.ui.navigateUp
import androidx.navigation.ui.setupActionBarWithNavController
import androidx.navigation.ui.setupWithNavController
import com.google.android.material.bottomnavigation.BottomNavigationView
import com.sitebook.R
import com.sitebook.databinding.ActivityMainBinding
import com.sitebook.services.AvailabilityCheckWorker
import dagger.hilt.android.AndroidEntryPoint

@AndroidEntryPoint
class MainActivity : AppCompatActivity() {

    private lateinit var binding: ActivityMainBinding
    private lateinit var appBarConfiguration: AppBarConfiguration
    private val viewModel: MainViewModel by viewModels()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        binding = ActivityMainBinding.inflate(layoutInflater)
        setContentView(binding.root)

        setupNavigation()
        setupBottomNavigation()
        observeViewModel()
        
        // Schedule background availability checking
        AvailabilityCheckWorker.schedulePeriodicCheck(this)
        
        // Handle notification launches
        handleNotificationIntent(intent)
    }

    private fun setupNavigation() {
        val navHostFragment = supportFragmentManager
            .findFragmentById(R.id.nav_host_fragment) as NavHostFragment
        val navController = navHostFragment.navController

        // Setup top-level destinations
        appBarConfiguration = AppBarConfiguration(
            setOf(
                R.id.navigation_campgrounds,
                R.id.navigation_reservations,
                R.id.navigation_profile
            )
        )

        setupActionBarWithNavController(navController, appBarConfiguration)
    }

    private fun setupBottomNavigation() {
        val navView: BottomNavigationView = binding.bottomNavigation
        val navHostFragment = supportFragmentManager
            .findFragmentById(R.id.nav_host_fragment) as NavHostFragment
        val navController = navHostFragment.navController

        navView.setupWithNavController(navController)
    }

    private fun observeViewModel() {
        viewModel.isLoading.observe(this) { isLoading ->
            // Handle loading state UI updates
        }

        viewModel.errorMessage.observe(this) { errorMessage ->
            if (errorMessage != null) {
                // Show error message to user
                // TODO: Implement proper error handling UI
            }
        }
    }

    private fun handleNotificationIntent(intent: android.content.Intent?) {
        when (intent?.getStringExtra("action")) {
            "book_now" -> {
                val reservationId = intent.getStringExtra("reservation_id")
                // Navigate to booking flow
                // TODO: Implement booking navigation
            }
        }
    }

    override fun onSupportNavigateUp(): Boolean {
        val navHostFragment = supportFragmentManager
            .findFragmentById(R.id.nav_host_fragment) as NavHostFragment
        val navController = navHostFragment.navController
        return navController.navigateUp(appBarConfiguration) || super.onSupportNavigateUp()
    }
}