import 'package:flutter/material.dart';

class GuestSelectionSection extends StatefulWidget {
  final int numberOfGuests;
  final String? selectedCampsiteType;
  final ValueChanged<int> onGuestCountChanged;
  final ValueChanged<String?> onCampsiteTypeChanged;

  const GuestSelectionSection({
    super.key,
    required this.numberOfGuests,
    this.selectedCampsiteType,
    required this.onGuestCountChanged,
    required this.onCampsiteTypeChanged,
  });

  @override
  State<GuestSelectionSection> createState() => _GuestSelectionSectionState();
}

class _GuestSelectionSectionState extends State<GuestSelectionSection> {
  static const List<String> campsiteTypes = [
    'Standard Site',
    'Electric Hookup',
    'Full Hookup (Water + Electric + Sewer)',
    'Premium Site (Waterfront)',
    'Group Site',
    'RV Site',
    'Tent-Only Site',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tell us about your group',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 8),

        Text(
          'How many people will be staying and what type of campsite do you need?',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),

        const SizedBox(height: 24),

        // Guest count selection
        _buildGuestCountSection(theme),

        const SizedBox(height: 32),

        // Campsite type selection
        _buildCampsiteTypeSection(theme),

        const SizedBox(height: 24),

        // Pricing estimate (if type is selected)
        if (widget.selectedCampsiteType != null) _buildPricingEstimate(theme),
      ],
    );
  }

  Widget _buildGuestCountSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Number of Guests',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 12),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: theme.colorScheme.outline.withAlpha(128)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.group, color: theme.colorScheme.primary),

              const SizedBox(width: 16),

              Expanded(
                child: Text(
                  'Guests',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              // Guest count controls
              Row(
                children: [
                  IconButton(
                    onPressed: widget.numberOfGuests > 1
                        ? () => widget.onGuestCountChanged(
                            widget.numberOfGuests - 1,
                          )
                        : null,
                    icon: const Icon(Icons.remove_circle_outline),
                    visualDensity: VisualDensity.compact,
                  ),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withAlpha(128),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${widget.numberOfGuests}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),

                  IconButton(
                    onPressed: widget.numberOfGuests < 20
                        ? () => widget.onGuestCountChanged(
                            widget.numberOfGuests + 1,
                          )
                        : null,
                    icon: const Icon(Icons.add_circle_outline),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ],
          ),
        ),

        if (widget.numberOfGuests > 8)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Large groups may require special arrangements',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCampsiteTypeSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Campsite Type',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 12),

        // Campsite type options
        Column(
          children: campsiteTypes.map((type) {
            final isSelected = widget.selectedCampsiteType == type;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () => widget.onCampsiteTypeChanged(type),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outline.withAlpha(128),
                    ),
                    borderRadius: BorderRadius.circular(12),
                    color: isSelected
                        ? theme.colorScheme.primaryContainer.withAlpha(77)
                        : theme.colorScheme.surface,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurfaceVariant,
                            width: 2,
                          ),
                          color: isSelected
                              ? theme.colorScheme.primary
                              : Colors.transparent,
                        ),
                        child: isSelected
                            ? Icon(
                                Icons.check,
                                size: 14,
                                color: theme.colorScheme.onPrimary,
                              )
                            : null,
                      ),

                      const SizedBox(width: 16),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              type,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w500,
                                color: isSelected
                                    ? theme.colorScheme.onSurface
                                    : theme.colorScheme.onSurface,
                              ),
                            ),

                            const SizedBox(height: 4),

                            Text(
                              _getCampsiteTypeDescription(type),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Pricing info
                      Text(
                        _getCampsiteTypePrice(type),
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPricingEstimate(ThemeData theme) {
    final basePrice = _getCampsiteTypePriceValue(widget.selectedCampsiteType!);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withAlpha(128),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.primary.withAlpha(128)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.attach_money, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Pricing Estimate',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Base rate per night:', style: theme.textTheme.bodyMedium),
              Text(
                '\$${basePrice.toStringAsFixed(2)}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          if (widget.numberOfGuests > 4)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Extra guest fee (${widget.numberOfGuests - 4} guests):',
                    style: theme.textTheme.bodyMedium,
                  ),
                  Text(
                    '\$${((widget.numberOfGuests - 4) * 5.0).toStringAsFixed(2)}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

          const Divider(height: 24),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Estimated per night:',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '\$${_calculateTotalPerNight().toStringAsFixed(2)}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Text(
            'Final pricing may include additional fees and taxes',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  String _getCampsiteTypeDescription(String type) {
    switch (type) {
      case 'Standard Site':
        return 'Basic campsite with fire pit and picnic table';
      case 'Electric Hookup':
        return '30/50 amp electrical hookup available';
      case 'Full Hookup (Water + Electric + Sewer)':
        return 'Complete RV hookups for extended stays';
      case 'Premium Site (Waterfront)':
        return 'Prime location with lake or river views';
      case 'Group Site':
        return 'Large site suitable for multiple families';
      case 'RV Site':
        return 'Dedicated site with RV parking pad';
      case 'Tent-Only Site':
        return 'Quieter area reserved for tent camping';
      default:
        return 'Campsite with basic amenities';
    }
  }

  String _getCampsiteTypePrice(String type) {
    final price = _getCampsiteTypePriceValue(type);
    return '\$${price.toStringAsFixed(0)}+';
  }

  double _getCampsiteTypePriceValue(String type) {
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

  double _calculateTotalPerNight() {
    final basePrice = _getCampsiteTypePriceValue(widget.selectedCampsiteType!);
    final extraGuestFee = widget.numberOfGuests > 4
        ? (widget.numberOfGuests - 4) * 5.0
        : 0.0;
    return basePrice + extraGuestFee;
  }
}
