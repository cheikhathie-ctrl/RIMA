import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'otp_screen.dart';

class PhoneLoginScreen extends StatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  final TextEditingController _phoneController = TextEditingController();

  bool _isSending = false;

  String _countryCode = '+222';
  String _countryName = 'Mauritania';

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
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

  Future<void> _sendOtp() async {
    final phoneDigits = _phoneController.text.replaceAll(RegExp(r'[^0-9]'), '');

    if (phoneDigits.isEmpty) {
      _showMessage('Please enter your phone number.');
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

    setState(() {
      _isSending = true;
    });

    try {
      await Supabase.instance.client.auth.signInWithOtp(
        phone: phone,
        //
        // Login should not silently create a new account.
        //
        shouldCreateUser: false,
      );

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => OtpScreen(phoneNumber: phone)),
      );
    } on AuthException catch (e) {
      if (!mounted) return;

      _showMessage(e.message);
    } catch (e) {
      debugPrint('RIMA LOGIN OTP ERROR: $e');

      if (!mounted) return;

      _showMessage('Unable to send verification code.');
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F3E8),
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),

                  Center(
                    child: Image.asset(
                      'assets/images/rima_logo.png',
                      height: 90,
                      fit: BoxFit.contain,
                    ),
                  ),

                  const SizedBox(height: 35),

                  const Text(
                    'Log in to RIMA',
                    style: TextStyle(fontSize: 29, fontWeight: FontWeight.w800),
                  ),

                  const SizedBox(height: 10),

                  const Text(
                    'Enter your phone number and we’ll send you a verification code.',
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: 16,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 34),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InkWell(
                        onTap: _isSending ? null : _selectCountry,
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
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
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
                          enabled: !_isSending,
                          decoration: InputDecoration(
                            labelText: 'Phone number',
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

                  const SizedBox(height: 28),

                  SizedBox(
                    width: double.infinity,
                    height: 58,
                    child: ElevatedButton(
                      onPressed: _isSending ? null : _sendOtp,
                      child: _isSending
                          ? const SizedBox(
                              width: 24,
                              height: 24,
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

                  const SizedBox(height: 20),

                  const Center(
                    child: Text(
                      'Your phone number is used to secure your RIMA account.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.black54, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
