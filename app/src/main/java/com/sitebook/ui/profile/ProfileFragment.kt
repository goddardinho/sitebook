package com.sitebook.ui.profile

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.fragment.app.Fragment
import androidx.fragment.app.viewModels
import com.sitebook.databinding.FragmentProfileBinding
import dagger.hilt.android.AndroidEntryPoint

@AndroidEntryPoint
class ProfileFragment : Fragment() {

    private var _binding: FragmentProfileBinding? = null
    private val binding get() = _binding!!
    private val viewModel: ProfileViewModel by viewModels()

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View {
        _binding = FragmentProfileBinding.inflate(inflater, container, false)
        return binding.root
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
        setupClickListeners()
        setupObservers()
    }

    private fun setupClickListeners() {
        binding.apply {
            switchNotifications.setOnCheckedChangeListener { _, isChecked ->
                viewModel.updateNotificationSettings(isChecked)
            }
            
            switchAutoReserve.setOnCheckedChangeListener { _, isChecked ->
                viewModel.updateAutoReserveSettings(isChecked)
            }
            
            switchBiometric.setOnCheckedChangeListener { _, isChecked ->
                viewModel.updateBiometricSettings(isChecked)
            }
            
            seekbarRadius.setOnSeekBarChangeListener(object : android.widget.SeekBar.OnSeekBarChangeListener {
                override fun onProgressChanged(seekBar: android.widget.SeekBar?, progress: Int, fromUser: Boolean) {
                    if (fromUser) {
                        val radius = progress + 10 // Min 10 miles
                        textViewRadiusValue.text = "$radius miles"
                    }
                }
                
                override fun onStartTrackingTouch(seekBar: android.widget.SeekBar?) {}
                
                override fun onStopTrackingTouch(seekBar: android.widget.SeekBar?) {
                    val radius = (seekBar?.progress ?: 0) + 10
                    viewModel.updatePreferredRadius(radius.toDouble())
                }
            })
            
            buttonSignOut.setOnClickListener {
                viewModel.signOut()
            }
        }
    }

    private fun setupObservers() {
        viewModel.userPreferences.observe(viewLifecycleOwner) { preferences ->
            binding.apply {
                switchNotifications.isChecked = preferences.notificationsEnabled
                switchAutoReserve.isChecked = preferences.autoReserveEnabled
                switchBiometric.isChecked = preferences.biometricAuthEnabled
                
                val radiusValue = preferences.preferredRadius.toInt()
                seekbarRadius.progress = radiusValue - 10 // Adjust for min value
                textViewRadiusValue.text = "$radiusValue miles"
                
                preferences.maxAutoReservePrice?.let { price ->
                    editTextMaxPrice.setText(String.format("%.2f", price))
                }
            }
        }
    }

    override fun onDestroyView() {
        super.onDestroyView()
        _binding = null
    }
}