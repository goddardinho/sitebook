package com.sitebook.ui.campgrounds

import android.view.LayoutInflater
import android.view.ViewGroup
import androidx.recyclerview.widget.DiffUtil
import androidx.recyclerview.widget.ListAdapter
import androidx.recyclerview.widget.RecyclerView
import com.bumptech.glide.Glide
import com.sitebook.R
import com.sitebook.data.local.entities.Campground
import com.sitebook.databinding.ItemCampgroundBinding

class CampgroundsAdapter(
    private val onCampgroundClick: (Campground) -> Unit
) : ListAdapter<Campground, CampgroundsAdapter.CampgroundViewHolder>(CampgroundDiffCallback()) {

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): CampgroundViewHolder {
        val binding = ItemCampgroundBinding.inflate(
            LayoutInflater.from(parent.context), 
            parent, 
            false
        )
        return CampgroundViewHolder(binding, onCampgroundClick)
    }

    override fun onBindViewHolder(holder: CampgroundViewHolder, position: Int) {
        holder.bind(getItem(position))
    }

    class CampgroundViewHolder(
        private val binding: ItemCampgroundBinding,
        private val onCampgroundClick: (Campground) -> Unit
    ) : RecyclerView.ViewHolder(binding.root) {

        fun bind(campground: Campground) {
            binding.apply {
                textCampgroundName.text = campground.name
                textCampgroundState.text = campground.state
                textCampgroundDescription.text = campground.description
                
                // Load campground image if available
                if (campground.imageUrls.isNotEmpty()) {
                    Glide.with(imageCampground.context)
                        .load(campground.imageUrls.first())
                        .placeholder(R.drawable.ic_campground_placeholder)
                        .error(R.drawable.ic_campground_placeholder)
                        .into(imageCampground)
                } else {
                    imageCampground.setImageResource(R.drawable.ic_campground_placeholder)
                }

                // Show monitoring status
                switchMonitoring.isChecked = campground.isMonitored
                switchMonitoring.setOnCheckedChangeListener { _, isChecked ->
                    // TODO: Handle monitoring toggle
                }

                root.setOnClickListener {
                    onCampgroundClick(campground)
                }
                
                // Show amenities
                if (campground.amenities.isNotEmpty()) {
                    textAmenities.text = campground.amenities.take(3).joinToString(", ")
                    textAmenities.visibility = android.view.View.VISIBLE
                } else {
                    textAmenities.visibility = android.view.View.GONE
                }
                
                // Show price if available
                if (campground.priceRange != null) {
                    textPriceRange.text = campground.priceRange
                    textPriceRange.visibility = android.view.View.VISIBLE
                } else {
                    textPriceRange.visibility = android.view.View.GONE
                }
            }
        }
    }

    private class CampgroundDiffCallback : DiffUtil.ItemCallback<Campground>() {
        override fun areItemsTheSame(oldItem: Campground, newItem: Campground): Boolean {
            return oldItem.id == newItem.id
        }

        override fun areContentsTheSame(oldItem: Campground, newItem: Campground): Boolean {
            return oldItem == newItem
        }
    }
}