import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ContactInformationSection extends StatefulWidget {
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String specialRequests;
  final ValueChanged<String> onFirstNameChanged;
  final ValueChanged<String> onLastNameChanged;
  final ValueChanged<String> onEmailChanged;
  final ValueChanged<String> onPhoneChanged;
  final ValueChanged<String> onSpecialRequestsChanged;

  const ContactInformationSection({
    super.key,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.specialRequests,
    required this.onFirstNameChanged,
    required this.onLastNameChanged,
    required this.onEmailChanged,
    required this.onPhoneChanged,
    required this.onSpecialRequestsChanged,
  });

  @override
  State<ContactInformationSection> createState() => _ContactInformationSectionState();
}

class _ContactInformationSectionState extends State<ContactInformationSection> {
  final _formKey = GlobalKey<FormState>();
  
  // Text controllers for form fields
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _specialRequestsController;

  // Focus nodes for better UX
  final _firstNameFocus = FocusNode();
  final _lastNameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _specialRequestsFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    
    // Initialize controllers with current values
    _firstNameController = TextEditingController(text: widget.firstName);
    _lastNameController = TextEditingController(text: widget.lastName);
    _emailController = TextEditingController(text: widget.email);
    _phoneController = TextEditingController(text: widget.phone);
    _specialRequestsController = TextEditingController(text: widget.specialRequests);

    // Add listeners to update parent state
    _firstNameController.addListener(() {
      widget.onFirstNameChanged(_firstNameController.text);
    });
    _lastNameController.addListener(() {
      widget.onLastNameChanged(_lastNameController.text);
    });
    _emailController.addListener(() {
      widget.onEmailChanged(_emailController.text);
    });
    _phoneController.addListener(() {
      widget.onPhoneChanged(_phoneController.text);
    });
    _specialRequestsController.addListener(() {
      widget.onSpecialRequestsChanged(_specialRequestsController.text);
    });
  }

  @override
  void dispose() {
    // Dispose controllers and focus nodes
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _specialRequestsController.dispose();
    
    _firstNameFocus.dispose();
    _lastNameFocus.dispose();
    _emailFocus.dispose();
    _phoneFocus.dispose();
    _specialRequestsFocus.dispose();
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Contact Information',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          
          const SizedBox(height: 8),
          
          Text(
            'We\'ll use this information to confirm your reservation and send updates.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Required fields section
          _buildRequiredFieldsSection(theme),
          
          const SizedBox(height: 32),
          
          // Optional fields section
          _buildOptionalFieldsSection(theme),
        ],
      ),
    );
  }

  Widget _buildRequiredFieldsSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Required Information',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Name fields row
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _firstNameController,
                focusNode: _firstNameFocus,
                decoration: InputDecoration(
                  labelText: 'First Name',
                  hintText: 'Enter your first name',
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) {
                  _lastNameFocus.requestFocus();
                },
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'First name is required';
                  }
                  if (value.trim().length < 2) {
                    return 'First name must be at least 2 characters';
                  }
                  return null;
                },
              ),
            ),
            
            const SizedBox(width: 16),
            
            Expanded(
              child: TextFormField(
                controller: _lastNameController,
                focusNode: _lastNameFocus,
                decoration: InputDecoration(
                  labelText: 'Last Name',
                  hintText: 'Enter your last name',
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) {
                  _emailFocus.requestFocus();
                },
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Last name is required';
                  }
                  if (value.trim().length < 2) {
                    return 'Last name must be at least 2 characters';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 20),
        
        // Email field
        TextFormField(
          controller: _emailController,
          focusNode: _emailFocus,
          decoration: InputDecoration(
            labelText: 'Email Address',
            hintText: 'Enter your email address',
            prefixIcon: const Icon(Icons.email_outlined),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          onFieldSubmitted: (_) {
            _phoneFocus.requestFocus();
          },
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Email address is required';
            }
            final emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
            if (!emailRegExp.hasMatch(value.trim())) {
              return 'Please enter a valid email address';
            }
            return null;
          },
        ),
        
        const SizedBox(height: 20),
        
        // Phone field
        TextFormField(
          controller: _phoneController,
          focusNode: _phoneFocus,
          decoration: InputDecoration(
            labelText: 'Phone Number',
            hintText: 'Enter your phone number',
            prefixIcon: const Icon(Icons.phone_outlined),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.next,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(10),
            _PhoneNumberFormatter(),
          ],
          onFieldSubmitted: (_) {
            _specialRequestsFocus.requestFocus();
          },
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Phone number is required';
            }
            final phoneRegExp = RegExp(r'^\(\d{3}\) \d{3}-\d{4}$');
            if (!phoneRegExp.hasMatch(value.trim())) {
              return 'Please enter a valid phone number';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildOptionalFieldsSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Additional Information',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        
        const SizedBox(height: 8),
        
        Text(
          'Optional',
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Special requests field
        TextFormField(
          controller: _specialRequestsController,
          focusNode: _specialRequestsFocus,
          decoration: InputDecoration(
            labelText: 'Special Requests or Notes',
            hintText: 'Any special needs, accessibility requirements, or other requests...',
            prefixIcon: const Icon(Icons.note_outlined),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            alignLabelWithHint: true,
          ),
          maxLines: 4,
          maxLength: 500,
          textInputAction: TextInputAction.done,
        ),
        
        const SizedBox(height: 16),
        
        // Privacy notice
        Container(
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
                    Icons.privacy_tip_outlined,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Privacy & Communication',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              Text(
                'Your information will be used solely for reservation purposes. '
                'We\'ll send confirmation details and any important updates about your stay.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Custom formatter for phone number input
class _PhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final newText = newValue.text;
    
    if (newText.isEmpty) {
      return newValue;
    }
    
    // Remove any non-digit characters
    final digitsOnly = newText.replaceAll(RegExp(r'\D'), '');
    
    String formattedNumber = '';
    
    if (digitsOnly.isNotEmpty) {
      if (digitsOnly.length <= 3) {
        formattedNumber = '($digitsOnly';
      } else if (digitsOnly.length <= 6) {
        formattedNumber = '(${digitsOnly.substring(0, 3)}) ${digitsOnly.substring(3)}';
      } else {
        formattedNumber = '(${digitsOnly.substring(0, 3)}) ${digitsOnly.substring(3, 6)}-${digitsOnly.substring(6)}';
      }
    }
    
    return TextEditingValue(
      text: formattedNumber,
      selection: TextSelection.collapsed(
        offset: formattedNumber.length,
      ),
    );
  }
}