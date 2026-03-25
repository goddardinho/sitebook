package com.sitebook.ui.reservations

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.fragment.app.Fragment
import androidx.fragment.app.viewModels
import androidx.navigation.fragment.findNavController
import androidx.recyclerview.widget.LinearLayoutManager
import com.sitebook.databinding.FragmentReservationsBinding
import dagger.hilt.android.AndroidEntryPoint

@AndroidEntryPoint
class ReservationsFragment : Fragment() {

    private var _binding: FragmentReservationsBinding? = null
    private val binding get() = _binding!!
    private val viewModel: ReservationsViewModel by viewModels()
    private lateinit var adapter: ReservationsAdapter

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View {
        _binding = FragmentReservationsBinding.inflate(inflater, container, false)
        return binding.root
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
        setupRecyclerView()
        setupObservers()
        setupClickListeners()
    }

    private fun setupRecyclerView() {
        adapter = ReservationsAdapter { reservation ->
            // Navigate to reservation details
            val action = ReservationsFragmentDirections
                .actionReservationsToReservationDetail(reservation.id)
            findNavController().navigate(action)
        }
        
        binding.recyclerViewReservations.apply {
            layoutManager = LinearLayoutManager(context)
            adapter = this@ReservationsFragment.adapter
        }
    }

    private fun setupObservers() {
        viewModel.reservations.observe(viewLifecycleOwner) { reservations ->
            adapter.submitList(reservations)
            binding.emptyStateGroup.visibility = 
                if (reservations.isEmpty()) View.VISIBLE else View.GONE
        }

        viewModel.isLoading.observe(viewLifecycleOwner) { isLoading ->
            binding.progressBar.visibility = if (isLoading) View.VISIBLE else View.GONE
        }
    }

    private fun setupClickListeners() {
        binding.fabAddReservation.setOnClickListener {
            findNavController().navigate(
                ReservationsFragmentDirections.actionReservationsToCampgrounds()
            )
        }
    }

    override fun onDestroyView() {
        super.onDestroyView()
        _binding = null
    }
}