import 'package:flutter/material.dart';
import '../../../../shared/models/campground.dart';

class ReservationSummarySection extends StatelessWidget {
  final Campground campground;
  final DateTime? checkInDate;
  final DateTime? checkOutDate;
  final int numberOfGuests;
  final String? campsiteType;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String specialRequests;

  const ReservationSummarySection({
    super.key,
    required this.campground,
    this.checkInDate,
    this.checkOutDate,
    required this.numberOfGuests,
    this.campsiteType,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.specialRequests,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Review Your Reservation',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        
        const SizedBox(height: 8),
        
        Text(
          'Please review all details before submitting your reservation.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Campground details
        _buildCampgroundDetails(theme),
        
        const SizedBox(height: 20),
        
        // Stay details
        _buildStayDetails(theme),
        
        const SizedBox(height: 20),
        
        // Guest information
        _buildGuestInformation(theme),
        
        const SizedBox(height: 20),
        
        // Pricing breakdown
        _buildPricingBreakdown(theme),
        
        const SizedBox(height: 24),
        
        // Terms and conditions
        _buildTermsAndConditions(theme),
      ],
    );
  }

  Widget _buildCampgroundDetails(ThemeData theme) {
    return _SummaryCard(
      theme: theme,
      title: 'Campground',
      icon: Icons.nature,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            campground.name,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          
          const SizedBox(height: 4),
          
          Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                campground.state,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          
          if (campground.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              campground.description,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStayDetails(ThemeData theme) {
    final nights = checkInDate != null && checkOutDate != null
        ? checkOutDate!.difference(checkInDate!).inDays
        : 0;
        
    return _SummaryCard(
      theme: theme,
      title: 'Stay Details',
      icon: Icons.calendar_month,
      child: Column(
        children: [
          _SummaryRow(
            label: 'Check-in',
            value: checkInDate != null 
                ? _formatDate(checkInDate!)
                : 'Not selected',
          ),
          
          const SizedBox(height: 8),
          
          _SummaryRow(
            label: 'Check-out',
            value: checkOutDate != null 
                ? _formatDate(checkOutDate!)
                : 'Not selected',
          ),
          
          const SizedBox(height: 8),
          
          _SummaryRow(
            label: 'Duration',
            value: '$nights night${nights != 1 ? 's' : ''}',
          ),
          
          const SizedBox(height: 8),
          
          _SummaryRow(
            label: 'Campsite Type',
            value: campsiteType ?? 'Not selected',
          ),
        ],
      ),
    );
  }

  Widget _buildGuestInformation(ThemeData theme) {
    return _SummaryCard(
      theme: theme,
      title: 'Guest Information',
      icon: Icons.group,
      child: Column(
        children: [
          _SummaryRow(
            label: 'Number of Guests',
            value: '$numberOfGuests guest${numberOfGuests != 1 ? 's' : ''}',
          ),
          
          const SizedBox(height: 8),
          
          _SummaryRow(
            label: 'Primary Contact',
            value: '$firstName $lastName',
          ),
          
          const SizedBox(height: 8),
          
          _SummaryRow(
            label: 'Email',
            value: email,
          ),
          
          const SizedBox(height: 8),
          
          _SummaryRow(
            label: 'Phone',
            value: phone,
          ),
          
          if (specialRequests.isNotEmpty) ...[
            const SizedBox(height: 8),
            _SummaryRow(
              label: 'Special Requests',
              value: specialRequests,
              isMultiline: true,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPricingBreakdown(ThemeData theme) {
    if (checkInDate == null || checkOutDate == null || campsiteType == null) {
      return const SizedBox.shrink();
    }
    
    final nights = checkOutDate!.difference(checkInDate!).inDays;
    final basePrice = _getCampsiteTypePrice(campsiteType!);
    final subtotal = basePrice * nights;
    final extraGuestFee = numberOfGuests > 4 
        ? (numberOfGuests - 4) * 5.0 * nights
        : 0.0;
    final reservationFee = 5.0;
    final taxRate = 0.08; // 8% tax
    final taxAmount = (subtotal + extraGuestFee + reservationFee) * taxRate;
    final total = subtotal + extraGuestFee + reservationFee + taxAmount;
    
    return _SummaryCard(
      theme: theme,
      title: 'Pricing Breakdown',
      icon: Icons.receipt,
      child: Column(
        children: [
          _PricingRow(
            label: '$campsiteType ($nights night${nights != 1 ? 's' : ''})',
            amount: subtotal,
            theme: theme,
          ),
          
          if (extraGuestFee > 0) ...[
            const SizedBox(height: 8),
            _PricingRow(
              label: 'Extra guest fee (${numberOfGuests - 4} guests)',
              amount: extraGuestFee,
              theme: theme,
            ),
          ],
          
          const SizedBox(height: 8),
          
          _PricingRow(
            label: 'Reservation fee',
            amount: reservationFee,
            theme: theme,
          ),
          
          const SizedBox(height: 8),
          
          _PricingRow(
            label: 'Taxes & fees',
            amount: taxAmount,
            theme: theme,
          ),
          
          const SizedBox(height: 16),
          
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withAlpha(128),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Amount',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                Text(
                  '\$${total.toStringAsFixed(2)}',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTermsAndConditions(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer.withAlpha(128),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withAlpha(77),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Important Information',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          Text(
            '• Cancellations must be made at least 48 hours before check-in\n'
            '• Check-in time is 3:00 PM, check-out is 11:00 AM\n'
            '• Pets may be allowed with additional fees (check campground policies)\n'
            '• Quiet hours are enforced from 10:00 PM to 6:00 AM\n'
            '• All reservation payments are processed securely',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          
          const SizedBox(height: 12),
          
          Text(
            'By submitting this reservation, you agree to the campground\'s terms and conditions.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  double _getCampsiteTypePrice(String type) {
    switch (type) {
      case 'Standard Site':
        return 25.0;
      case 'Electric Hookup':
        return 35.0;
      case 'Full Hookup (Water + Electric + Sewer)':
        return 45.0;
      case 'Premium Site (Waterfront)':
        return 55.0;
      case 'Group Site':
        return 75.0;
      case 'RV Site':
        return 40.0;
      case 'Tent-Only Site':
        return 20.0;
      default:
        return 25.0;
    }
  }

  String _formatDate(DateTime date) {
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    
    final weekday = weekdays[date.weekday - 1];
    final month = months[date.month - 1];
    
    return '$weekday, $month ${date.day}';
  }
}

// Helper widgets
class _SummaryCard extends StatelessWidget {
  final ThemeData theme;
  final String title;
  final IconData icon;
  final Widget child;

  const _SummaryCard({
    required this.theme,
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer.withAlpha(128),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withAlpha(77),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          child,
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isMultiline;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.isMultiline = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (isMultiline) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.bodyMedium,
          ),
        ],
      );
    }
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}

class _PricingRow extends StatelessWidget {
  final String label;
  final double amount;
  final ThemeData theme;

  const _PricingRow({
    required this.label,
    required this.amount,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium,
        ),
        Text(
          '\$${amount.toStringAsFixed(2)}',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}