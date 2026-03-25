package com.sitebook.ui.reservations

import android.view.LayoutInflater
import android.view.ViewGroup
import androidx.core.content.ContextCompat
import androidx.recyclerview.widget.DiffUtil
import androidx.recyclerview.widget.ListAdapter
import androidx.recyclerview.widget.RecyclerView
import com.sitebook.R
import com.sitebook.data.local.entities.Reservation
import com.sitebook.data.local.entities.ReservationStatus
import com.sitebook.databinding.ItemReservationBinding
import java.text.SimpleDateFormat
import java.util.*

class ReservationsAdapter(
    private val onReservationClick: (Reservation) -> Unit
) : ListAdapter<Reservation, ReservationsAdapter.ReservationViewHolder>(
    ReservationDiffCallback()
) {

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): ReservationViewHolder {
        val binding = ItemReservationBinding.inflate(
            LayoutInflater.from(parent.context),
            parent,
            false
        )
        return ReservationViewHolder(binding, onReservationClick)
    }

    override fun onBindViewHolder(holder: ReservationViewHolder, position: Int) {
        holder.bind(getItem(position))
    }

    class ReservationViewHolder(
        private val binding: ItemReservationBinding,
        private val onReservationClick: (Reservation) -> Unit
    ) : RecyclerView.ViewHolder(binding.root) {

        private val dateFormat = SimpleDateFormat("MMM dd, yyyy", Locale.getDefault())

        fun bind(reservation: Reservation) {
            binding.apply {
                textViewDates.text = "${dateFormat.format(reservation.checkInDate)} - ${dateFormat.format(reservation.checkOutDate)}"
                textViewConfirmation.text = reservation.confirmationNumber ?: "Pending"
                textViewGuestCount.text = "${reservation.guestCount} guests"
                
                if (reservation.totalCost != null) {
                    textViewCost.text = "$${String.format("%.2f", reservation.totalCost)}"
                } else {
                    textViewCost.text = "TBD"
                }

                // Status styling
                val (statusText, statusColor) = when (reservation.status) {
                    ReservationStatus.CONFIRMED -> "Confirmed" to R.color.status_confirmed
                    ReservationStatus.PENDING -> "Pending" to R.color.status_pending
                    ReservationStatus.MONITORING -> "Monitoring" to R.color.status_monitoring
                    ReservationStatus.CANCELLED -> "Cancelled" to R.color.status_cancelled
                    ReservationStatus.FAILED -> "Failed" to R.color.status_failed
                    ReservationStatus.EXPIRED -> "Expired" to R.color.status_expired
                }
                
                textViewStatus.text = statusText
                textViewStatus.setTextColor(
                    ContextCompat.getColor(binding.root.context, statusColor)
                )

                root.setOnClickListener {
                    onReservationClick(reservation)
                }
            }
        }
    }

    private class ReservationDiffCallback : DiffUtil.ItemCallback<Reservation>() {
        override fun areItemsTheSame(oldItem: Reservation, newItem: Reservation): Boolean {
            return oldItem.id == newItem.id
        }

        override fun areContentsTheSame(oldItem: Reservation, newItem: Reservation): Boolean {
            return oldItem == newItem
        }
    }
}