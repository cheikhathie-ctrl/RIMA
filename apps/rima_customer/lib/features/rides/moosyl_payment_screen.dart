import 'package:flutter/material.dart';
import 'package:moosyl_flutter/moosyl.dart';

import '../../app/theme/colors.dart';

class MoosylPaymentScreen extends StatefulWidget {
  const MoosylPaymentScreen({
    super.key,
    required this.transactionId,
    required this.rideId,
  });

  final String transactionId;
  final String rideId;

  @override
  State<MoosylPaymentScreen> createState() => _MoosylPaymentScreenState();
}

class _MoosylPaymentScreenState extends State<MoosylPaymentScreen> {
  static const String _publishableApiKey = String.fromEnvironment(
    'MOOSYL_PUBLISHABLE_KEY',
  );

  bool _isOpeningPayment = false;
  String? _errorMessage;

  Future<void> _openMoosylPayment() async {
    if (_isOpeningPayment) {
      return;
    }

    if (_publishableApiKey.isEmpty) {
      setState(() {
        _errorMessage = 'Moosyl publishable key is missing.';
      });

      return;
    }

    setState(() {
      _isOpeningPayment = true;
      _errorMessage = null;
    });

    try {
      final result = await MoosylFlutter.show(
        context,
        publishableApiKey: _publishableApiKey,
        transactionId: widget.transactionId,
        isFullPage: true,
      );

      debugPrint(
        'RIMA MOOSYL PAYMENT RESULT: '
        'ride=${widget.rideId} '
        'result=$result',
      );

      if (!mounted) {
        return;
      }

      if (result == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Payment submitted. '
              'RIMA is confirming your payment.',
            ),
          ),
        );

        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint('RIMA MOOSYL PAYMENT ERROR: $e');

      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = 'Unable to open payment. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isOpeningPayment = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFDF7),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Complete Payment',
          style: TextStyle(
            color: RimaColors.primary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEAF6ED),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_rounded,
                      size: 46,
                      color: RimaColors.primary,
                    ),
                  ),

                  const SizedBox(height: 24),

                  const Text(
                    'Your driver accepted the ride',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: RimaColors.primary,
                    ),
                  ),

                  const SizedBox(height: 12),

                  const Text(
                    'Complete payment to confirm your ride. '
                    'Your driver will begin heading to you '
                    'after payment is confirmed.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.5,
                      color: Colors.black54,
                    ),
                  ),

                  if (_errorMessage != null) ...[
                    const SizedBox(height: 20),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF0ED),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 30),

                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: _isOpeningPayment ? null : _openMoosylPayment,
                      icon: _isOpeningPayment
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.lock_rounded),
                      label: Text(
                        _isOpeningPayment
                            ? 'Opening payment...'
                            : 'Pay securely with Moosyl',
                        style: const TextStyle(fontWeight: FontWeight.w700),
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
