import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/campground.dart';
import 'widgets/date_selection_section.dart';
import 'widgets/guest_selection_section.dart';
import 'widgets/contact_information_section.dart';
import 'widgets/reservation_summary_section.dart';

class ReservationFormScreen extends ConsumerStatefulWidget {
  final Campground campground;

  const ReservationFormScreen({
    super.key,
    required this.campground,
  });

  @override
  ConsumerState<ReservationFormScreen> createState() => _ReservationFormScreenState();
}

class _ReservationFormScreenState extends ConsumerState<ReservationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  
  // Form data
  DateTime? _checkInDate;
  DateTime? _checkOutDate;
  int _numberOfGuests = 2;
  String? _selectedCampsiteType;
  String _firstName = '';
  String _lastName = '';
  String _email = '';
  String _phone = '';
  String _specialRequests = '';

  // UI State
  int _currentStep = 0;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Make Reservation'),
        elevation: 0,
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // Progress indicator
            _buildProgressIndicator(theme),
            
            // Form content
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Campground info header
                    _buildCampgroundHeader(theme),
                    
                    const SizedBox(height: 24),
                    
                    // Form sections based on current step
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _buildCurrentStep(),
                    ),
                  ],
                ),
              ),
            ),
            
            // Bottom action bar
            _buildBottomActionBar(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withAlpha(77),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Step ${_currentStep + 1} of 4',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(4, (index) {
              final isActive = index <= _currentStep;
              final isCompleted = index < _currentStep;
              
              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(
                    right: index < 3 ? 8 : 0,
                  ),
                  height: 4,
                  decoration: BoxDecoration(
                    color: isCompleted 
                        ? theme.colorScheme.primary
                        : isActive 
                            ? theme.colorScheme.primary.withAlpha(128)
                            : theme.colorScheme.outline.withAlpha(77),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Text(
            _getStepTitle(_currentStep),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCampgroundHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withAlpha(77),
        ),
      ),
      child: Row(
        children: [
          // Campground image placeholder
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: theme.colorScheme.surfaceContainerHighest,
            ),
            child: widget.campground.imageUrls.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      widget.campground.imageUrls.first,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => 
                          Icon(Icons.nature, color: theme.colorScheme.primary),
                    ),
                  )
                : Icon(Icons.nature, color: theme.colorScheme.primary),
          ),
          
          const SizedBox(width: 16),
          
          // Campground info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.campground.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      widget.campground.state,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return DateSelectionSection(
          key: const ValueKey('dates'),
          checkInDate: _checkInDate,
          checkOutDate: _checkOutDate,
          onCheckInChanged: (date) => setState(() => _checkInDate = date),
          onCheckOutChanged: (date) => setState(() => _checkOutDate = date),
        );
      case 1:
        return GuestSelectionSection(
          key: const ValueKey('guests'),
          numberOfGuests: _numberOfGuests,
          selectedCampsiteType: _selectedCampsiteType,
          onGuestCountChanged: (count) => setState(() => _numberOfGuests = count),
          onCampsiteTypeChanged: (type) => setState(() => _selectedCampsiteType = type),
        );
      case 2:
        return ContactInformationSection(
          key: const ValueKey('contact'),
          firstName: _firstName,
          lastName: _lastName,
          email: _email,
          phone: _phone,
          specialRequests: _specialRequests,
          onFirstNameChanged: (value) => setState(() => _firstName = value),
          onLastNameChanged: (value) => setState(() => _lastName = value),
          onEmailChanged: (value) => setState(() => _email = value),
          onPhoneChanged: (value) => setState(() => _phone = value),
          onSpecialRequestsChanged: (value) => setState(() => _specialRequests = value),
        );
      case 3:
        return ReservationSummarySection(
          key: const ValueKey('summary'),
          campground: widget.campground,
          checkInDate: _checkInDate,
          checkOutDate: _checkOutDate,
          numberOfGuests: _numberOfGuests,
          campsiteType: _selectedCampsiteType,
          firstName: _firstName,
          lastName: _lastName,
          email: _email,
          phone: _phone,
          specialRequests: _specialRequests,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildBottomActionBar(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withAlpha(77),
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Back button
            if (_currentStep > 0)
              OutlinedButton(
                onPressed: _goToPreviousStep,
                child: const Text('Back'),
              ),
            
            const Spacer(),
            
            // Next/Submit button
            FilledButton(
              onPressed: _isSubmitting ? null : _handleNextOrSubmit,
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_currentStep < 3 ? 'Next' : 'Submit Reservation'),
            ),
          ],
        ),
      ),
    );
  }

  String _getStepTitle(int step) {
    switch (step) {
      case 0:
        return 'Select Dates';
      case 1:
        return 'Choose Details';
      case 2:
        return 'Contact Info';
      case 3:
        return 'Review & Submit';
      default:
        return '';
    }
  }

  bool _canProceedToNextStep() {
    switch (_currentStep) {
      case 0:
        return _checkInDate != null && _checkOutDate != null;
      case 1:
        return _numberOfGuests > 0;
      case 2:
        return _firstName.isNotEmpty && 
               _lastName.isNotEmpty && 
               _email.isNotEmpty && 
               _phone.isNotEmpty;
      case 3:
        return true;
      default:
        return false;
    }
  }

  void _goToPreviousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _scrollToTop();
    }
  }

  void _handleNextOrSubmit() {
    if (!_canProceedToNextStep()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete all required fields'),
        ),
      );
      return;
    }

    if (_currentStep < 3) {
      setState(() {
        _currentStep++;
      });
      _scrollToTop();
    } else {
      _submitReservation();
    }
  }

  void _scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _submitReservation() async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      // TODO: Implement actual reservation submission
      await Future.delayed(const Duration(seconds: 2)); // Simulate API call

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reservation submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        
        Navigator.of(context).pop(); // Return to previous screen
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit reservation: $error'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
}