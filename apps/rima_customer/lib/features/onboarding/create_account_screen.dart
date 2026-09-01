import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'registration_otp_screen.dart';

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  static const int minimumAge = 14;

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isSendingOtp = false;

  DateTime? _dateOfBirth;

  String _countryCode = '+222';
  String _countryName = 'Mauritania';

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  bool _isOldEnough(DateTime birthDate) {
    final today = DateTime.now();

    final minimumBirthDate = DateTime(
      today.year - minimumAge,
      today.month,
      today.day,
    );

    return !birthDate.isAfter(minimumBirthDate);
  }

  Future<void> _selectDateOfBirth() async {
    final today = DateTime.now();

    final selected = await showDatePicker(
      context: context,
      initialDate: DateTime(today.year - 18),
      firstDate: DateTime(today.year - 100),
      lastDate: today,
    );

    if (selected == null || !mounted) {
      return;
    }

    setState(() {
      _dateOfBirth = selected;
    });
  }

  void _selectCountry() {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'Select country',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
              ),
              ListTile(
                leading: const Text('🇲🇷', style: TextStyle(fontSize: 26)),
                title: const Text('Mauritania'),
                trailing: const Text('+222'),
                onTap: () {
                  setState(() {
                    _countryCode = '+222';
                    _countryName = 'Mauritania';
                    _phoneController.clear();
                  });

                  Navigator.pop(sheetContext);
                },
              ),
              ListTile(
                leading: const Text('🇺🇸', style: TextStyle(fontSize: 26)),
                title: const Text('United States'),
                trailing: const Text('+1'),
                onTap: () {
                  setState(() {
                    _countryCode = '+1';
                    _countryName = 'United States';
                    _phoneController.clear();
                  });

                  Navigator.pop(sheetContext);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  String _normalizedPhone() {
    final digits = _phoneController.text.replaceAll(RegExp(r'[^0-9]'), '');

    return '$_countryCode$digits';
  }

  Future<void> _continueRegistration() async {
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final email = _emailController.text.trim();

    final phoneDigits = _phoneController.text.replaceAll(RegExp(r'[^0-9]'), '');

    if (firstName.isEmpty || lastName.isEmpty) {
      _showMessage('Please enter your first and last name.');
      return;
    }

    if (_dateOfBirth == null) {
      _showMessage('Please enter your date of birth.');
      return;
    }

    if (!_isOldEnough(_dateOfBirth!)) {
      _showMessage(
        'You must be at least $minimumAge years old to create a RIMA account.',
      );
      return;
    }

    if (email.isNotEmpty &&
        !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      _showMessage('Please enter a valid email address.');
      return;
    }

    if (_countryCode == '+222' && phoneDigits.length != 8) {
      _showMessage('Enter a valid Mauritania phone number.');
      return;
    }

    if (_countryCode == '+1' && phoneDigits.length != 10) {
      _showMessage('Enter a valid 10-digit U.S. phone number.');
      return;
    }

    final phone = _normalizedPhone();

    try {
      final exists = await Supabase.instance.client.rpc(
        'rima_phone_account_exists',
        params: {'p_phone': phone},
      );

      if (exists == true) {
        if (!mounted) return;

        _showMessage(
          'This phone number is already associated with a RIMA account. Please log in instead.',
        );
        return;
      }
    } on PostgrestException catch (e) {
      debugPrint('RIMA CUSTOMER ACCOUNT CHECK ERROR: ${e.message}');

      if (!mounted) return;

      _showMessage('Unable to verify this phone number. Please try again.');
      return;
    }

    setState(() {
      _isSendingOtp = true;
    });

    try {
      await Supabase.instance.client.auth.signInWithOtp(
        phone: phone,
        shouldCreateUser: true,
      );

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RegistrationOtpScreen(
            phoneNumber: phone,
            firstName: firstName,
            lastName: lastName,
            email: email.isEmpty ? null : email,
            dateOfBirth: _dateOfBirth!,
          ),
        ),
      );
    } on AuthException catch (e) {
      if (!mounted) return;

      _showMessage(e.message);
    } catch (e) {
      debugPrint('RIMA CUSTOMER REGISTRATION OTP ERROR: $e');

      if (!mounted) return;

      _showMessage('Unable to send verification code.');
    } finally {
      if (mounted) {
        setState(() {
          _isSendingOtp = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String get _formattedDateOfBirth {
    final value = _dateOfBirth;

    if (value == null) {
      return 'Date of birth';
    }

    return '${value.month}/${value.day}/${value.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F3E8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Create account'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Create your RIMA account',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
              ),

              const SizedBox(height: 8),

              const Text(
                'Enter your information, then we’ll verify your phone number.',
                style: TextStyle(color: Colors.black54, fontSize: 16),
              ),

              const SizedBox(height: 28),

              TextField(
                controller: _firstNameController,
                textCapitalization: TextCapitalization.words,
                enabled: !_isSendingOtp,
                decoration: const InputDecoration(
                  labelText: 'First name *',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),

              const SizedBox(height: 16),

              TextField(
                controller: _lastNameController,
                textCapitalization: TextCapitalization.words,
                enabled: !_isSendingOtp,
                decoration: const InputDecoration(
                  labelText: 'Last name *',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),

              const SizedBox(height: 16),

              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                enabled: !_isSendingOtp,
                decoration: const InputDecoration(
                  labelText: 'Email (optional)',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),

              const SizedBox(height: 16),

              InkWell(
                onTap: _isSendingOtp ? null : _selectDateOfBirth,
                borderRadius: BorderRadius.circular(12),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date of birth *',
                    prefixIcon: Icon(Icons.cake_outlined),
                  ),
                  child: Text(_formattedDateOfBirth),
                ),
              ),

              const SizedBox(height: 16),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    onTap: _isSendingOtp ? null : _selectCountry,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      height: 58,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.black26),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Text(
                            _countryCode,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.arrow_drop_down),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      enabled: !_isSendingOtp,
                      decoration: InputDecoration(
                        labelText: 'Phone number *',
                        hintText: _countryCode == '+222'
                            ? '36 12 34 56'
                            : '614 555 1234',
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              Text(
                'Country: $_countryName',
                style: const TextStyle(color: Colors.black54, fontSize: 13),
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton(
                  onPressed: _isSendingOtp ? null : _continueRegistration,
                  child: _isSendingOtp
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Continue',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 14),

              const Center(
                child: Text(
                  'You must be at least 14 years old.',
                  style: TextStyle(color: Colors.black54, fontSize: 13),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
