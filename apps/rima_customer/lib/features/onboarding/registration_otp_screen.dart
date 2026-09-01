import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../home/home_screen.dart';

class RegistrationOtpScreen extends StatefulWidget {
  const RegistrationOtpScreen({
    super.key,
    required this.phoneNumber,
    required this.firstName,
    required this.lastName,
    required this.dateOfBirth,
    this.email,
  });

  final String phoneNumber;
  final String firstName;
  final String lastName;
  final String? email;
  final DateTime dateOfBirth;

  @override
  State<RegistrationOtpScreen> createState() => _RegistrationOtpScreenState();
}

class _RegistrationOtpScreenState extends State<RegistrationOtpScreen> {
  final TextEditingController _otpController = TextEditingController();

  bool _isVerifying = false;
  bool _isResending = false;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  String get _formattedDob {
    return '${widget.dateOfBirth.year.toString().padLeft(4, '0')}-'
        '${widget.dateOfBirth.month.toString().padLeft(2, '0')}-'
        '${widget.dateOfBirth.day.toString().padLeft(2, '0')}';
  }

  Future<void> _verifyOtp() async {
    final code = _otpController.text.trim();

    if (code.length != 6) {
      _showMessage('Please enter the 6-digit verification code.');
      return;
    }

    setState(() {
      _isVerifying = true;
    });

    try {
      final response = await Supabase.instance.client.auth.verifyOTP(
        phone: widget.phoneNumber,
        token: code,
        type: OtpType.sms,
      );

      if (response.session == null) {
        throw const AuthException('Unable to create authenticated session.');
      }

      await Supabase.instance.client.rpc(
        'complete_customer_account_setup',
        params: {
          'p_first_name': widget.firstName,
          'p_last_name': widget.lastName,
          'p_email': widget.email,
          'p_date_of_birth': _formattedDob,
        },
      );

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    } on AuthException catch (e) {
      if (!mounted) return;

      _showMessage(e.message);
    } on PostgrestException catch (e) {
      debugPrint('RIMA CUSTOMER REGISTRATION DATABASE ERROR: ${e.message}');

      if (!mounted) return;

      _showMessage('Unable to create account: ${e.message}');
    } catch (e) {
      debugPrint('RIMA CUSTOMER REGISTRATION VERIFY ERROR: $e');

      if (!mounted) return;

      _showMessage('Unable to complete registration.');
    } finally {
      if (mounted) {
        setState(() {
          _isVerifying = false;
        });
      }
    }
  }

  Future<void> _resendOtp() async {
    if (_isResending) {
      return;
    }

    setState(() {
      _isResending = true;
    });

    try {
      await Supabase.instance.client.auth.signInWithOtp(
        phone: widget.phoneNumber,
        shouldCreateUser: true,
      );

      if (!mounted) return;

      _showMessage('A new verification code was sent.');
    } on AuthException catch (e) {
      if (!mounted) return;

      _showMessage(e.message);
    } catch (e) {
      debugPrint('RIMA CUSTOMER REGISTRATION RESEND ERROR: $e');

      if (!mounted) return;

      _showMessage('Unable to resend verification code.');
    } finally {
      if (mounted) {
        setState(() {
          _isResending = false;
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Verify phone'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.verified_user_outlined, size: 64),

                  const SizedBox(height: 28),

                  const Text(
                    'Verify your phone number',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    'Enter the 6-digit code sent to\n'
                    '${widget.phoneNumber}',
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 30),

                  TextField(
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    enabled: !_isVerifying,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 10,
                    ),
                    decoration: const InputDecoration(
                      counterText: '',
                      hintText: '------',
                    ),
                  ),

                  const SizedBox(height: 28),

                  SizedBox(
                    width: double.infinity,
                    height: 58,
                    child: ElevatedButton(
                      onPressed: _isVerifying ? null : _verifyOtp,
                      child: _isVerifying
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Verify & create account',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  Center(
                    child: TextButton(
                      onPressed: _isResending ? null : _resendOtp,
                      child: Text(
                        _isResending
                            ? 'Sending...'
                            : 'Resend verification code',
                      ),
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
