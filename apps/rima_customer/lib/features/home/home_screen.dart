import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../messages/messages_screen.dart';
import '../notifications/notifications_screen.dart';
import '../profile/profile_screen.dart';
import '../rides/ride_booking_screen.dart';
import '../rides/ride_history_screen.dart';
import '../rides/ride_searching_screen.dart';
import '../wallet/wallet_screen.dart';
import '../../app/localization/rima_localization.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _checkingLatestRide = true;
  bool _resumeHandled = false;

  // ============================================================
  // FINAL RIMA EMERALD + GOLD DESIGN
  // ============================================================

  static const Color _pageTop = Color(0xFF064E3B);
  static const Color _pageBottom = Color(0xFF023D2E);

  static const Color _panelGreen = Color(0xFF064E3B);
  static const Color _panelGreenLight = Color(0xFF075B43);

  static const Color _gold = Color(0xFFFFC52F);
  static const Color _goldLight = Color(0xFFFFE27A);
  static const Color _goldDeep = Color(0xFFE8A91F);

  static const Color _white = Color(0xFFF8F8F4);

  static const Set<String> _activeRideStatuses = {
    'requested',
    'searching',
    'awaiting_payment',
    'payment_confirmed',
    'driver_assigned',
    'driver_arriving',
    'driver_arrived',
    'in_progress',
  };
void _onLanguageChanged() {
  if (mounted) {
    setState(() {});
  }
}

@override
void dispose() {
  RimaLocaleController.language.removeListener(_onLanguageChanged);
  super.dispose();
}

  @override
  void initState() {
    super.initState();
RimaLocaleController.language.addListener(_onLanguageChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkLatestRide();
    });
  }

  // ============================================================
  // ACTIVE RIDE RESUME
  // ============================================================

  Future<void> _checkLatestRide() async {
    if (_resumeHandled) return;

    try {
      final user = Supabase.instance.client.auth.currentUser;

      if (user == null) {
        if (mounted) {
          setState(() {
            _checkingLatestRide = false;
          });
        }
        return;
      }

      final result = await Supabase.instance.client
          .from('rides')
          .select(
            'id,status,service_type,destination_label,quoted_fare_mru,requested_at,updated_at',
          )
          .eq('customer_id', user.id)
          .order('requested_at', ascending: false)
          .limit(1);

      if (!mounted) return;

      if (result.isEmpty) {
        setState(() {
          _checkingLatestRide = false;
        });
        return;
      }

      final ride = Map<String, dynamic>.from(result.first);

      final status = ride['status']?.toString() ?? '';
      final rideId = ride['id']?.toString();

      if (status == 'completed' ||
          status == 'cancelled' ||
          !_activeRideStatuses.contains(status) ||
          rideId == null) {
        setState(() {
          _checkingLatestRide = false;
        });
        return;
      }

      _resumeHandled = true;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => RideSearchingScreen(
            rideId: rideId,
            rideType: _serviceLabel(
              ride['service_type']?.toString() ?? 'rima_go',
            ),
            destination:
                ride['destination_label']?.toString() ?? 'Destination',
            fare: _formatFare(
              ride['quoted_fare_mru'],
            ),
          ),
        ),
        (route) => false,
      );
    } catch (e) {
      debugPrint(
        'RIMA CUSTOMER HOME ACTIVE RIDE ERROR: $e',
      );

      if (mounted) {
        setState(() {
          _checkingLatestRide = false;
        });
      }
    }
  }

  String _serviceLabel(String serviceType) {
    switch (serviceType) {
      case 'rima_comfort':
        return 'RIMA Comfort';

      case 'rima_xl':
        return 'RIMA XL';

      default:
        return 'RIMA Go';
    }
  }

  String _formatFare(dynamic value) {
    final parsed = double.tryParse(
      value?.toString() ?? '',
    );

    if (parsed == null) {
      return '-- MRU';
    }

    final decimals =
        parsed == parsed.roundToDouble() ? 0 : 2;

    return '${parsed.toStringAsFixed(decimals)} MRU';
  }

  // ============================================================
  // NAVIGATION
  // ============================================================

  void _open(Widget page) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => page,
      ),
    );
  }

  void _comingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: _panelGreen,
        behavior: SnackBarBehavior.floating,
        content: Text(
          '$feature is coming soon.',
          style: const TextStyle(
            color: _gold,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final t = RimaText.get;
    if (_checkingLatestRide) {
      return const Scaffold(
        backgroundColor: _pageBottom,
        body: SafeArea(
          child: Center(
            child: CircularProgressIndicator(
              color: _gold,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _pageBottom,

      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _pageTop,
              _pageBottom,
            ],
          ),
        ),

        child: SafeArea(
          bottom: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 520,
              ),

              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  18,
                  12,
                  18,
                  28,
                ),

                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    // ==================================================
                    // HEADER
                    // ==================================================

                    Row(
                      children: [
                        Expanded(
                          child: ColorFiltered(
                            colorFilter:
                                const ColorFilter.mode(
                              _gold,
                              BlendMode.srcIn,
                            ),
                            child: Image.asset(
                              'assets/images/rima_logo.png',
                              height: 58,
                              alignment:
                                  Alignment.centerLeft,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),

                        _topButton(
                          icon:
                              Icons.notifications_none_rounded,
                          onTap: () {
                            _open(
                              const NotificationsScreen(),
                            );
                          },
                        ),

                        const SizedBox(width: 12),

                        _topButton(
                          icon:
                              Icons.person_outline_rounded,
                          onTap: () {
                            _open(
                              const ProfileScreen(),
                            );
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // ==================================================
                    // WELCOME
                    // ==================================================

                    _luxuryPanel(
                      radius: 27,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          20,
                          16,
                          18,
                          16,
                        ),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                           Text(
  t('welcome'),
  style: const TextStyle(
    color: _gold,
    fontSize: 23,
    height: 1.05,
    fontWeight:
        FontWeight.w900,
  ),
),
                            SizedBox(height: 13),

                            Text(
  t('tagline'),
  style: const TextStyle(
                                color: _white,
                                fontSize: 13.5,
                                fontWeight:
                                    FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // ==================================================
                    // SEARCH
                    // ==================================================

                    Material(
                      color: Colors.transparent,
                      borderRadius:
                          BorderRadius.circular(25),

                      child: InkWell(
                        borderRadius:
                            BorderRadius.circular(25),

                        onTap: () {
                          _open(
                            const RideBookingScreen(),
                          );
                        },

                        child: _luxuryPanel(
                          radius: 25,
                          child: SizedBox(
                            height: 54,
                            child: Padding(
                              padding:
                                 const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.search_rounded,
                                    color: _gold,
                                    size: 25,
                                  ),

                                  SizedBox(width: 16),

                                Expanded(
  child: Text(
    t('destination'),
    style: const TextStyle(
      color:
          Colors.white70,
      fontSize: 13.5,
      fontWeight:
          FontWeight.w500,
    ),
  ),
),

                                  Icon(
                                    Icons
                                        .arrow_forward_rounded,
                                    color: _gold,
                                    size: 25,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                  Text(
  t('services'),
  style: const TextStyle(
    color: _gold,
    fontSize: 22,
    fontWeight: FontWeight.w900,
  ),
),

                    const SizedBox(height: 17),

                    GridView(
                      shrinkWrap: true,
                      physics:
                          const NeverScrollableScrollPhysics(),

                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 15,
                        mainAxisSpacing: 17,

                        // More room = no overflow.
                        mainAxisExtent: 145,
                      ),

                      children: [
                        _serviceCard(
                          icon:
                              Icons.local_taxi_rounded,
                          title: 'RIMA Go',
                         subtitle:
    t('goSubtitle'),
buttonText: t('bookRide'),
                          showArrow: true,
                          onTap: () {
                            _open(
                              const RideBookingScreen(),
                            );
                          },
                        ),

                        _serviceCard(
                          icon:
                              Icons.restaurant_rounded,
                          title: 'RIMA Food',
                         subtitle:
    t('foodSubtitle'),
buttonText: t('comingSoon'),                         
 onTap: () {
                            _comingSoon(
                              'RIMA Food',
                            );
                          },
                        ),

                        _serviceCard(
                          icon: Icons
                              .inventory_2_outlined,
                          title: 'RIMA Express',
                          subtitle:
    t('expressSubtitle'),
buttonText: t('comingSoon'),
                          onTap: () {
                            _comingSoon(
                              'RIMA Express',
                            );
                          },
                        ),

                        _serviceCard(
                          icon: Icons
                              .account_balance_wallet_outlined,
                          title: 'RIMA Pay',
                         subtitle:
    t('paySubtitle'),
buttonText: t('viewWallet'),                        
  showArrow: true,
                          onTap: () {
                            _open(
                              const WalletScreen(),
                            );
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

               Text(
  t('quickAccess'),
  style: const TextStyle(
    color: _gold,
    fontSize: 22,
    fontWeight: FontWeight.w900,
  ),
),

                    const SizedBox(height: 14),

                    Material(
                      color: Colors.transparent,
                      borderRadius:
                          BorderRadius.circular(25),

                      child: InkWell(
                        borderRadius:
                            BorderRadius.circular(25),

                        onTap: () {
                          _open(
                            const RideHistoryScreen(),
                          );
                        },

                        child: _luxuryPanel(
                          radius: 25,
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),

                            child: Row(
                              children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration:
                                      BoxDecoration(
                                    shape:
                                        BoxShape.circle,
                                    color:
                                        _panelGreenLight,
                                    border:
                                        Border.all(
                                      color: _gold,
                                      width: 1.3,
                                    ),
                                    boxShadow:
                                        const [
                                      BoxShadow(
                                        color: Color(
                                          0x66FFC52F,
                                        ),
                                        blurRadius: 14,
                                      ),
                                    ],
                                  ),

                                  child: const Icon(
                                    Icons
                                        .history_rounded,
                                    color: _gold,
                                    size: 21,
                                  ),
                                ),

                                const SizedBox(
                                  width: 17,
                                ),

                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,
                                    children: [
                                     Text(
  t('recentActivity'),
  style:
      const TextStyle(
    color: _gold,
    fontSize: 15,
    fontWeight:
        FontWeight
            .w900,
  ),
),

                                      SizedBox(
                                        height: 4,
                                      ),

                                     Text(
  t('seeTrips'),
  style:
      const TextStyle(
    color: _white,
    fontSize: 11.5,
    fontWeight:
        FontWeight
            .w500,
  ),
),
                                    ],
                                  ),
                                ),

                                const Icon(
                                  Icons
                                      .chevron_right_rounded,
                                  color: _gold,
                                  size: 34,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),

      // ============================================================
      // BOTTOM NAVIGATION
      // ============================================================

      bottomNavigationBar: Container(
        color: _pageBottom,

        child: SafeArea(
          top: false,
          child: Padding(
            padding:
                const EdgeInsets.fromLTRB(
              12,
              4,
              12,
              8,
            ),

            child: Container(
              height: 62,

              decoration: BoxDecoration(
                color: _panelGreen,
                borderRadius:
                    BorderRadius.circular(27),
                border: Border.all(
                  color: _gold,
                  width: 1.2,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(
                      0x55FFC52F,
                    ),
                    blurRadius: 16,
                    spreadRadius: -5,
                  ),
                ],
              ),

              child: Row(
                children: [
                  Expanded(
                    child: _bottomItem(
                      icon:
                          Icons.home_rounded,
                      label: t('home'),
                      selected: true,
                      onTap: () {},
                    ),
                  ),

                  Expanded(
                    child: _bottomItem(
                      icon: Icons
                          .receipt_long_outlined,
                      label: t('activity'),
                      onTap: () {
                        _open(
                          const RideHistoryScreen(),
                        );
                      },
                    ),
                  ),

                  Expanded(
                    child: _bottomItem(
                      icon: Icons
                          .account_balance_wallet_outlined,
                      label: t('wallet'),
                      onTap: () {
                        _open(
                          const WalletScreen(),
                        );
                      },
                    ),
                  ),

                  Expanded(
                    child: _bottomItem(
                      icon: Icons
                          .chat_bubble_outline_rounded,
                      label: t('messages'),
                      onTap: () {
                        _open(
                          const MessagesScreen(),
                        );
                      },
                    ),
                  ),

                  Expanded(
                    child: _bottomItem(
                      icon: Icons
                          .person_outline_rounded,
                      label: t('profile'),
                      onTap: () {
                        _open(
                          const ProfileScreen(),
                        );
                      },
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
  // ============================================================
  // LUXURY PANEL
  // ============================================================

  Widget _luxuryPanel({
    required Widget child,
    required double radius,
  }) {
    return Container(
      width: double.infinity,

      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _panelGreenLight,
            _panelGreen,
          ],
        ),

        borderRadius:
            BorderRadius.circular(radius),

        border: Border.all(
          color: _gold,
          width: 1.25,
        ),

        boxShadow: const [
          BoxShadow(
            color: Color(0x4A000000),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),

          BoxShadow(
            color: Color(0x55FFC52F),
            blurRadius: 15,
            spreadRadius: -7,
          ),
        ],
      ),

      child: Stack(
        clipBehavior: Clip.none,
        children: [
          child,

          // Gold reflection across top.
          Positioned(
            top: -1.5,
            left: 70,
            right: 70,
            child: Container(
              height: 3,
              decoration:
                  const BoxDecoration(
                gradient:
                    LinearGradient(
                  colors: [
                    Colors.transparent,
                    _goldLight,
                    _gold,
                    _goldLight,
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Soft reflection glow.
          Positioned(
            top: -6,
            left: 90,
            right: 90,
            child: IgnorePointer(
              child: Container(
                height: 14,
                decoration:
                    const BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color:
                          Color(0x66FFD451),
                      blurRadius: 18,
                      spreadRadius: 0,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TOP BUTTON
  // ============================================================

  Widget _topButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      width: 51,
      height: 51,

      decoration: BoxDecoration(
        shape: BoxShape.circle,

        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _panelGreenLight,
            _panelGreen,
          ],
        ),

        border: Border.all(
          color: _gold,
          width: 1.25,
        ),

        boxShadow: const [
          BoxShadow(
            color: Color(0x66FFC52F),
            blurRadius: 14,
          ),
        ],
      ),

      child: IconButton(
        padding: EdgeInsets.zero,
        onPressed: onTap,
        icon: Icon(
          icon,
          color: _gold,
          size: 21,
        ),
      ),
    );
  }

  // ============================================================
  // SERVICE CARD
  // ============================================================

  Widget _serviceCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String buttonText,
    required VoidCallback onTap,
    bool showArrow = false,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius:
          BorderRadius.circular(25),

      child: InkWell(
        borderRadius:
            BorderRadius.circular(25),
        onTap: onTap,

        child: Container(
          padding:
              const EdgeInsets.all(11),

          decoration: BoxDecoration(
            gradient:
                const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _panelGreenLight,
                _panelGreen,
              ],
            ),

            borderRadius:
                BorderRadius.circular(25),

            border: Border.all(
              color: _gold,
              width: 1.25,
            ),

            // Raised, but no black slab.
            boxShadow: const [
              BoxShadow(
                color:
                    Color(0x42000000),
                blurRadius: 8,
                offset: Offset(0, 4),
              ),

              BoxShadow(
                color:
                    Color(0x55FFC52F),
                blurRadius: 13,
                spreadRadius: -6,
              ),
            ],
          ),

          child: Stack(
            children: [
              // Decorative gold wave/reflection.
              Positioned(
                right: -20,
                bottom: 6,
                child: CustomPaint(
                  size:
                      const Size(95, 90),
                  painter:
                      _GoldWavePainter(),
                ),
              ),

              Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 38,
                    height: 38,

                    decoration:
                        BoxDecoration(
                      shape:
                          BoxShape.circle,

                      color:
                          _panelGreen,

                      border:
                          Border.all(
                        color: _gold,
                        width: 1.2,
                      ),

                      boxShadow:
                          const [
                        BoxShadow(
                          color: Color(
                            0x66FFC52F,
                          ),
                          blurRadius: 12,
                        ),
                      ],
                    ),

                    child: Icon(
                      icon,
                      color: _gold,
                      size: 21,
                    ),
                  ),

                  const SizedBox(
                    height: 7,
                  ),

                  Text(
                    title,
                    maxLines: 1,
                    overflow:
                        TextOverflow
                            .ellipsis,

                    style:
                        const TextStyle(
                      color: _gold,
                      fontSize: 16,
                      fontWeight:
                          FontWeight.w900,
                    ),
                  ),

                  const SizedBox(
                    height: 5,
                  ),

                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow:
                        TextOverflow
                            .ellipsis,

                    style:
                        const TextStyle(
                      color: _white,
                      fontSize: 9,
                      fontWeight:
                          FontWeight.w500,
                    ),
                  ),

                  const Spacer(),

                  Container(
                    constraints:
                        const BoxConstraints(
                      minHeight: 26,
                    ),

                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),

                    decoration:
                        BoxDecoration(
                      gradient:
                          const LinearGradient(
                        begin:
                            Alignment.topLeft,
                        end:
                            Alignment.bottomRight,
                        colors: [
                          _goldLight,
                          _gold,
                          _goldDeep,
                        ],
                      ),

                      borderRadius:
                          BorderRadius.circular(
                        20,
                      ),

                      boxShadow:
                          const [
                        BoxShadow(
                          color: Color(
                            0x66FFC52F,
                          ),
                          blurRadius: 10,
                        ),
                      ],
                    ),

                    child: Row(
                      mainAxisSize:
                          MainAxisSize.min,

                      children: [
                        Flexible(
                          child: Text(
                            buttonText,
                            maxLines: 1,
                            overflow:
                                TextOverflow
                                    .ellipsis,

                            style:
                                const TextStyle(
                              color:
                                  _panelGreen,
                              fontSize: 9.5,
                              fontWeight:
                                  FontWeight
                                      .w900,
                            ),
                          ),
                        ),

                        if (showArrow) ...[
                          const SizedBox(
                            width: 7,
                          ),

                          const Icon(
                            Icons
                                .arrow_forward_rounded,
                            color:
                                _panelGreen,
                            size: 18,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),

              // Gold highlight on top edge.
              Positioned(
                top: -15,
                left: 35,
                right: 35,
                child: Container(
                  height: 18,

                  decoration:
                      const BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Color(
                          0x77FFD451,
                        ),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // BOTTOM NAV
  // ============================================================

  Widget _bottomItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool selected = false,
  }) {
    return InkWell(
      borderRadius:
          BorderRadius.circular(21),

      onTap: onTap,

      child: Container(
        margin:
            const EdgeInsets.symmetric(
          horizontal: 2,
          vertical: 7,
        ),

        decoration: selected
            ? BoxDecoration(
                borderRadius:
                    BorderRadius.circular(
                  21,
                ),

                gradient:
                    const LinearGradient(
                  begin:
                      Alignment.topLeft,
                  end:
                      Alignment.bottomRight,
                  colors: [
                    Color(
                      0xFF0A6D4F,
                    ),
                    _panelGreen,
                  ],
                ),

                boxShadow:
                    const [
                  BoxShadow(
                    color: Color(
                      0x55FFC52F,
                    ),
                    blurRadius: 10,
                  ),
                ],
              )
            : null,

        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,

          children: [
            Icon(
              icon,
              color: _gold,
              size:
                  selected ? 27 : 24,
            ),

            const SizedBox(height: 3),

            Text(
              label,

              maxLines: 1,

              style: TextStyle(
                color: _gold,
                fontSize: 9,
                fontWeight:
                    FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// GOLD WAVE / REFLECTION PAINTER
// ============================================================

class _GoldWavePainter extends CustomPainter {
  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    for (int i = 0; i < 7; i++) {
      final paint = Paint()
        ..color = const Color(
          0xFFFFC52F,
        ).withValues(
          alpha: 0.08 +
              (i * 0.012),
        )
        ..style =
            PaintingStyle.stroke
        ..strokeWidth = 0.8;

      final path = Path();

      final offset =
          i * 6.0;

      path.moveTo(
        0,
        size.height -
            10 -
            offset,
      );

      path.cubicTo(
        size.width * 0.28,
        size.height -
            45 -
            offset,
        size.width * 0.58,
        size.height -
            25 -
            offset,
        size.width,
        size.height -
            70 -
            offset,
      );

      canvas.drawPath(
        path,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(
    covariant CustomPainter
        oldDelegate,
  ) {
    return false;
  }
}
