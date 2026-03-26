package com.sitebook.ui.campgrounds

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.fragment.app.Fragment
import androidx.fragment.app.viewModels
import androidx.navigation.fragment.findNavController
import androidx.recyclerview.widget.LinearLayoutManager
import com.sitebook.databinding.FragmentCampgroundsBinding
import dagger.hilt.android.AndroidEntryPoint

@AndroidEntryPoint
class CampgroundsFragment : Fragment() {

    private var _binding: FragmentCampgroundsBinding? = null
    private val binding get() = _binding!!
    private val viewModel: CampgroundsViewModel by viewModels()
    private lateinit var campgroundsAdapter: CampgroundsAdapter

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View {
        _binding = FragmentCampgroundsBinding.inflate(inflater, container, false)
        return binding.root
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
        
        setupRecyclerView()
        setupSearchView()
        observeViewModel()
        
        // Load campgrounds
        viewModel.loadCampgrounds()
    }

    private fun setupRecyclerView() {
        campgroundsAdapter = CampgroundsAdapter { campground ->
            // Navigate to campground details
            val action = CampgroundsFragmentDirections
                .actionNavigationCampgroundsToCampgroundDetail(campground.id)
            findNavController().navigate(action)
        }

        binding.recyclerViewCampgrounds.apply {
            adapter = campgroundsAdapter
            layoutManager = LinearLayoutManager(requireContext())
        }
    }

    private fun setupSearchView() {
        binding.searchView.setOnQueryTextListener(object : androidx.appcompat.widget.SearchView.OnQueryTextListener {
            override fun onQueryTextSubmit(query: String?): Boolean {
                query?.let { viewModel.searchCampgrounds(it) }
                return true
            }

            override fun onQueryTextChange(newText: String?): Boolean {
                if (newText.isNullOrEmpty()) {
                    viewModel.loadCampgrounds()
                }
                return true
            }
        })
    }

    private fun observeViewModel() {
        viewModel.campgrounds.observe(viewLifecycleOwner) { campgrounds ->
            campgroundsAdapter.submitList(campgrounds)
        }

        viewModel.isLoading.observe(viewLifecycleOwner) { isLoading ->
            binding.progressBar.visibility = if (isLoading) View.VISIBLE else View.GONE
        }

        viewModel.errorMessage.observe(viewLifecycleOwner) { errorMessage ->
            if (errorMessage != null) {
                // TODO: Show error message
                viewModel.clearError()
            }
        }
    }

    override fun onDestroyView() {
        super.onDestroyView()
        _binding = null
    }
}