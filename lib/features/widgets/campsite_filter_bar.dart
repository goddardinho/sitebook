import 'package:flutter/material.dart';

/// Filter and search bar for campsite selection
class CampsiteFilterBar extends StatefulWidget {
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final Set<String> selectedSiteTypes;
  final ValueChanged<Set<String>> onSiteTypesChanged;
  final bool accessibilityFilter;
  final ValueChanged<bool> onAccessibilityChanged;
  final double? maxPrice;
  final ValueChanged<double?> onMaxPriceChanged;
  final bool availableOnly;
  final ValueChanged<bool> onAvailableOnlyChanged;

  const CampsiteFilterBar({
    super.key,
    required this.searchController,
    required this.onSearchChanged,
    required this.selectedSiteTypes,
    required this.onSiteTypesChanged,
    required this.accessibilityFilter,
    required this.onAccessibilityChanged,
    required this.maxPrice,
    required this.onMaxPriceChanged,
    required this.availableOnly,
    required this.onAvailableOnlyChanged,
  });

  @override
  State<CampsiteFilterBar> createState() => _CampsiteFilterBarState();
}

class _CampsiteFilterBarState extends State<CampsiteFilterBar> {
  bool _showFilters = false;
  final TextEditingController _priceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.maxPrice != null) {
      _priceController.text = widget.maxPrice!.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        children: [
          _buildSearchBar(context),
          if (_showFilters) _buildFilterOptions(context),
        ],
      ),
    );
  }

  /// Search bar with filter toggle
  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Search field
          Expanded(
            child: TextField(
              controller: widget.searchController,
              onChanged: widget.onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search by site number or type...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: widget.searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          widget.searchController.clear();
                          widget.onSearchChanged('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Theme.of(
                  context,
                ).colorScheme.surfaceVariant.withOpacity(0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Filter toggle button
          Container(
            decoration: BoxDecoration(
              color: _showFilters
                  ? Theme.of(context).colorScheme.primaryContainer
                  : Theme.of(
                      context,
                    ).colorScheme.surfaceVariant.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: () => setState(() => _showFilters = !_showFilters),
              icon: Icon(
                Icons.tune,
                color: _showFilters
                    ? Theme.of(context).colorScheme.onPrimaryContainer
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              tooltip: 'Filters',
            ),
          ),
        ],
      ),
    );
  }

  /// Expanded filter options
  Widget _buildFilterOptions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick filters row
          _buildQuickFilters(context),

          const SizedBox(height: 16),

          // Site type filters
          _buildSiteTypeFilters(context),

          const SizedBox(height: 16),

          // Price filter
          _buildPriceFilter(context),

          const SizedBox(height: 16),

          // Action buttons
          _buildFilterActions(context),
        ],
      ),
    );
  }

  /// Quick filter switches
  Widget _buildQuickFilters(BuildContext context) {
    return Row(
      children: [
        // Available only filter
        Expanded(
          child: FilterChip(
            label: const Text('Available only'),
            selected: widget.availableOnly,
            onSelected: widget.onAvailableOnlyChanged,
            avatar: Icon(
              widget.availableOnly ? Icons.check_circle : Icons.circle_outlined,
              size: 18,
            ),
          ),
        ),

        const SizedBox(width: 12),

        // Accessibility filter
        Expanded(
          child: FilterChip(
            label: const Text('Accessible'),
            selected: widget.accessibilityFilter,
            onSelected: widget.onAccessibilityChanged,
            avatar: Icon(
              widget.accessibilityFilter
                  ? Icons.accessible
                  : Icons.accessible_outlined,
              size: 18,
            ),
          ),
        ),
      ],
    );
  }

  /// Site type filter chips
  Widget _buildSiteTypeFilters(BuildContext context) {
    final siteTypes = ['Tent', 'RV', 'Group', 'Cabin', 'Standard'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Site Types',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: siteTypes.map((type) {
            final isSelected = widget.selectedSiteTypes.contains(type);
            return FilterChip(
              label: Text(type),
              selected: isSelected,
              onSelected: (selected) {
                final newTypes = Set<String>.from(widget.selectedSiteTypes);
                if (selected) {
                  newTypes.add(type);
                } else {
                  newTypes.remove(type);
                }
                widget.onSiteTypesChanged(newTypes);
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  /// Price filter section
  Widget _buildPriceFilter(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Maximum Price per Night',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            // Price input
            SizedBox(
              width: 120,
              child: TextField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Any',
                  prefixText: '\$ ',
                  filled: true,
                  fillColor: Theme.of(
                    context,
                  ).colorScheme.surfaceVariant.withOpacity(0.5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                onChanged: (value) {
                  final price = double.tryParse(value);
                  widget.onMaxPriceChanged(price);
                },
              ),
            ),

            const SizedBox(width: 12),

            // Clear price filter
            if (widget.maxPrice != null)
              TextButton.icon(
                onPressed: () {
                  _priceController.clear();
                  widget.onMaxPriceChanged(null);
                },
                icon: const Icon(Icons.clear, size: 16),
                label: const Text('Clear'),
              ),
          ],
        ),

        // Price range suggestions
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [25.0, 50.0, 75.0, 100.0].map((price) {
            return ActionChip(
              label: Text('\$${price.toInt()}'),
              onPressed: () {
                _priceController.text = price.toStringAsFixed(0);
                widget.onMaxPriceChanged(price);
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  /// Filter action buttons
  Widget _buildFilterActions(BuildContext context) {
    final hasActiveFilters =
        widget.selectedSiteTypes.isNotEmpty ||
        widget.accessibilityFilter ||
        widget.maxPrice != null ||
        !widget.availableOnly ||
        widget.searchController.text.isNotEmpty;

    return Row(
      children: [
        // Active filter count
        if (hasActiveFilters) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '${_countActiveFilters()} active',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],

        // Clear all button
        if (hasActiveFilters)
          TextButton.icon(
            onPressed: _clearAllFilters,
            icon: const Icon(Icons.clear_all, size: 16),
            label: const Text('Clear All'),
          ),

        const Spacer(),

        // Done button
        ElevatedButton(
          onPressed: () => setState(() => _showFilters = false),
          child: const Text('Done'),
        ),
      ],
    );
  }

  /// Count active filters
  int _countActiveFilters() {
    int count = 0;
    if (widget.selectedSiteTypes.isNotEmpty) count++;
    if (widget.accessibilityFilter) count++;
    if (widget.maxPrice != null) count++;
    if (!widget.availableOnly) count++; // Default is true, so false is active
    if (widget.searchController.text.isNotEmpty) count++;
    return count;
  }

  /// Clear all filters
  void _clearAllFilters() {
    widget.searchController.clear();
    widget.onSearchChanged('');
    widget.onSiteTypesChanged(<String>{});
    widget.onAccessibilityChanged(false);
    widget.onMaxPriceChanged(null);
    widget.onAvailableOnlyChanged(true);
    _priceController.clear();
  }
}
