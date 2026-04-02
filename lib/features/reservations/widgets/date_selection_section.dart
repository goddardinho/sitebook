import 'package:flutter/material.dart';

class DateSelectionSection extends StatefulWidget {
  final DateTime? checkInDate;
  final DateTime? checkOutDate;
  final ValueChanged<DateTime?> onCheckInChanged;
  final ValueChanged<DateTime?> onCheckOutChanged;

  const DateSelectionSection({
    super.key,
    this.checkInDate,
    this.checkOutDate,
    required this.onCheckInChanged,
    required this.onCheckOutChanged,
  });

  @override
  State<DateSelectionSection> createState() => _DateSelectionSectionState();
}

class _DateSelectionSectionState extends State<DateSelectionSection> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'When would you like to stay?',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 8),

        Text(
          'Select your check-in and check-out dates to see availability.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),

        const SizedBox(height: 24),

        // Date selection cards
        Column(
          children: [
            _DatePickerCard(
              label: 'Check-in Date',
              date: widget.checkInDate,
              onDateChanged: widget.onCheckInChanged,
              isCheckIn: true,
              checkOutDate: widget.checkOutDate,
            ),

            const SizedBox(height: 16),

            _DatePickerCard(
              label: 'Check-out Date',
              date: widget.checkOutDate,
              onDateChanged: widget.onCheckOutChanged,
              isCheckIn: false,
              checkInDate: widget.checkInDate,
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Duration and nights info
        if (widget.checkInDate != null && widget.checkOutDate != null)
          _buildStayDurationInfo(theme),
      ],
    );
  }

  Widget _buildStayDurationInfo(ThemeData theme) {
    final nights = widget.checkOutDate!.difference(widget.checkInDate!).inDays;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withAlpha(128),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.primary.withAlpha(128)),
      ),
      child: Row(
        children: [
          Icon(Icons.calendar_month, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$nights Night${nights != 1 ? 's' : ''}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
              Text(
                '${_formatDate(widget.checkInDate!)} - ${_formatDate(widget.checkOutDate!)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}';
  }
}

class _DatePickerCard extends StatelessWidget {
  final String label;
  final DateTime? date;
  final ValueChanged<DateTime?> onDateChanged;
  final bool isCheckIn;
  final DateTime? checkInDate;
  final DateTime? checkOutDate;

  const _DatePickerCard({
    required this.label,
    this.date,
    required this.onDateChanged,
    required this.isCheckIn,
    this.checkInDate,
    this.checkOutDate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: () => _selectDate(context),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: date != null
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withAlpha(128),
          ),
          borderRadius: BorderRadius.circular(12),
          color: date != null
              ? theme.colorScheme.primaryContainer.withAlpha(77)
              : theme.colorScheme.surface,
        ),
        child: Row(
          children: [
            Icon(
              isCheckIn ? Icons.login : Icons.logout,
              color: date != null
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),

            const SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    date != null ? _formatSelectedDate(date!) : 'Select date',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: date != null
                          ? theme.colorScheme.onSurface
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            Icon(
              Icons.calendar_today,
              size: 20,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    DateTime? initialDate;
    DateTime? firstDate;
    DateTime? lastDate;

    if (isCheckIn) {
      initialDate = date ?? today;
      firstDate = today;
      lastDate =
          checkOutDate?.subtract(const Duration(days: 1)) ??
          DateTime(today.year + 1, today.month, today.day);
    } else {
      final minCheckOut =
          checkInDate?.add(const Duration(days: 1)) ??
          today.add(const Duration(days: 1));
      initialDate = date ?? minCheckOut;
      firstDate = minCheckOut;
      lastDate = DateTime(today.year + 1, today.month, today.day);
    }

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: isCheckIn ? 'Select check-in date' : 'Select check-out date',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Theme.of(context).colorScheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (selectedDate != null) {
      onDateChanged(selectedDate);

      // Auto-adjust check-out date if necessary
      if (isCheckIn &&
          checkOutDate != null &&
          selectedDate.isAtOrAfter(checkOutDate!)) {
        // Move check-out date to one day after new check-in date
        // This would need to be handled by the parent widget
      }
    }
  }

  String _formatSelectedDate(DateTime date) {
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    final weekday = weekdays[date.weekday - 1];
    final month = months[date.month - 1];

    return '$weekday, $month ${date.day}, ${date.year}';
  }
}

extension DateTimeExtensions on DateTime {
  bool isAtOrAfter(DateTime other) {
    return isAfter(other) || isAtSameMomentAs(other);
  }
}
