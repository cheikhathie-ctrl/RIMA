import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/theme/colors.dart';

enum RideRatingRole {
  customer,
  driver,
}

class RideRatingScreen extends StatefulWidget {
  const RideRatingScreen({
    super.key,
    required this.rideId,
    required this.role,
    required this.otherPartyName,
  });

  final String rideId;
  final RideRatingRole role;
  final String otherPartyName;

  @override
  State<RideRatingScreen> createState() => _RideRatingScreenState();
}

class _RideRatingScreenState extends State<RideRatingScreen> {
  final TextEditingController _commentController = TextEditingController();

  int _rating = 0;
  bool _isSubmitting = false;

  String get _title =>
      widget.role == RideRatingRole.customer
          ? 'Rate your driver'
          : 'Rate your customer';

  String get _question {
    final name = widget.otherPartyName.trim();
    if (name.isEmpty) {
      return widget.role == RideRatingRole.customer
          ? 'How was your ride with your driver?'
          : 'How was your ride with your customer?';
    }
    return 'How was your ride with $name?';
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating < 1 || _rating > 5 || _isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      await Supabase.instance.client.rpc(
        'submit_ride_rating',
        params: {
          'p_ride_id': widget.rideId,
          'p_rating': _rating,
          'p_comment': _commentController.text.trim(),
        },
      );

      if (!mounted) return;

      Navigator.pop(context, true);
    } on PostgrestException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to submit rating: ${e.message}'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to submit rating. Please try again.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _skip() {
    if (_isSubmitting) return;
    Navigator.pop(context, false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFDF7),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          _title,
          style: const TextStyle(
            color: RimaColors.primary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFF3D6),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.star_rounded,
                      size: 52,
                      color: RimaColors.gold,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    _title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 27,
                      fontWeight: FontWeight.w800,
                      color: RimaColors.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _question,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 4,
                    children: List.generate(5, (index) {
                      final value = index + 1;
                      final selected = value <= _rating;

                      return IconButton(
                        onPressed: _isSubmitting
                            ? null
                            : () {
                                setState(() {
                                  _rating = value;
                                });
                              },
                        iconSize: 46,
                        tooltip: '$value star${value == 1 ? '' : 's'}',
                        icon: Icon(
                          selected
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          color: RimaColors.gold,
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 22),
                  TextField(
                    controller: _commentController,
                    enabled: !_isSubmitting,
                    maxLines: 5,
                    maxLength: 1000,
                    decoration: InputDecoration(
                      labelText: 'Comment (optional)',
                      hintText: 'Tell us about your ride...',
                      alignLabelWithHint: true,
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed:
                          _rating == 0 || _isSubmitting ? null : _submit,
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check_rounded),
                      label: Text(
                        _isSubmitting ? 'Submitting...' : 'Submit rating',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _isSubmitting ? null : _skip,
                    child: const Text('Skip for now'),
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
