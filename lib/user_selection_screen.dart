import 'package:flutter/material.dart';
import 'medicine_menu.dart';  // Guest flow
import 'rfid_screen.dart';    // RFID scanning flow

class UserSelectionScreen extends StatefulWidget {
  const UserSelectionScreen({Key? key}) : super(key: key);

  @override
  _UserSelectionScreenState createState() => _UserSelectionScreenState();
}

class _UserSelectionScreenState extends State<UserSelectionScreen>
    with TickerProviderStateMixin {
  static const Color _brandStart = Color(0xFF0D2A5E);
  static const Color _brandEnd   = Color(0xFF1E5D6F);

  late final AnimationController _staggerCtrl;
  late final Animation<double>   _headlineFade,
      _subtextFade,
      _primaryBtnFade,
      _secondaryBtnFade;
  late final Animation<Offset>   _headlineOffset,
      _subtextOffset,
      _primaryBtnOffset,
      _secondaryBtnOffset;

  late final AnimationController _iconBobCtrl;
  late final Animation<double>   _iconBob;

  @override
  void initState() {
    super.initState();

    // 1) Staggered entry animation
    _staggerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..forward();

    _headlineFade = CurvedAnimation(
        parent: _staggerCtrl, curve: const Interval(0.00, 0.25, curve: Curves.easeOut)
    );
    _headlineOffset = Tween(begin: const Offset(0, .3), end: Offset.zero)
        .animate(CurvedAnimation(parent: _staggerCtrl, curve: const Interval(0.00, 0.25, curve: Curves.easeOut)));

    _subtextFade = CurvedAnimation(
        parent: _staggerCtrl, curve: const Interval(0.20, 0.45, curve: Curves.easeOut)
    );
    _subtextOffset = Tween(begin: const Offset(0, .3), end: Offset.zero)
        .animate(CurvedAnimation(parent: _staggerCtrl, curve: const Interval(0.20, 0.45, curve: Curves.easeOut)));

    _primaryBtnFade = CurvedAnimation(
        parent: _staggerCtrl, curve: const Interval(0.40, 0.65, curve: Curves.easeOut)
    );
    _primaryBtnOffset = Tween(begin: const Offset(0, .3), end: Offset.zero)
        .animate(CurvedAnimation(parent: _staggerCtrl, curve: const Interval(0.40, 0.65, curve: Curves.easeOut)));

    _secondaryBtnFade = CurvedAnimation(
        parent: _staggerCtrl, curve: const Interval(0.60, 0.85, curve: Curves.easeOut)
    );
    _secondaryBtnOffset = Tween(begin: const Offset(0, .3), end: Offset.zero)
        .animate(CurvedAnimation(parent: _staggerCtrl, curve: const Interval(0.60, 0.85, curve: Curves.easeOut)));

    // 2) Icon “bob” animation
    _iconBobCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _iconBob = Tween(begin: -4.0, end: 4.0)
        .animate(CurvedAnimation(parent: _iconBobCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _staggerCtrl.dispose();
    _iconBobCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final buttonW = w * 0.8;
    const btnH = 90.0;

    return Scaffold(
      // let our gradient show through
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [_brandStart, _brandEnd],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Headline
                  SlideTransition(
                    position: _headlineOffset,
                    child: FadeTransition(
                      opacity: _headlineFade,
                      child: Text(
                        "Are you a VendoCard user?",
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Subtext
                  SlideTransition(
                    position: _subtextOffset,
                    child: FadeTransition(
                      opacity: _subtextFade,
                      child: Text(
                        "Scan your VendoCard to access your account and earn points.\n"
                            "Or continue as guest to skip login.",
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.white70,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),

                  const SizedBox(height: 48),

                  // Primary button: RFID
                  SlideTransition(
                    position: _primaryBtnOffset,
                    child: FadeTransition(
                      opacity: _primaryBtnFade,
                      child: SizedBox(
                        width: buttonW,
                        height: btnH,
                        child: Material(
                          elevation: 6,
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            onTap: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (_) => const RfidScreen()),
                              );
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  AnimatedBuilder(
                                    animation: _iconBob,
                                    builder: (context, child) => Transform.translate(
                                      offset: Offset(0, _iconBob.value),
                                      child: child,
                                    ),
                                    child: const Icon(Icons.credit_card,
                                        color: _brandStart, size: 36),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    "I Have VendoCard",
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w600,
                                      color: _brandStart,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Secondary button: Guest
                  SlideTransition(
                    position: _secondaryBtnOffset,
                    child: FadeTransition(
                      opacity: _secondaryBtnFade,
                      child: SizedBox(
                        width: buttonW,
                        height: btnH,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const MedicineMenu(rfidData: "Guest"),
                              ),
                            );
                          },
                          icon: const Icon(Icons.person_outline,
                              color: Colors.white, size: 36),
                          label: const Text(
                            "Continue as Guest",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.white70, width: 2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
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
