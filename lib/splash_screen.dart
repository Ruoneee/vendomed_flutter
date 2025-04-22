// ignore_for_file: use_full_hex_values_for_flutter_colors, deprecated_member_use

import 'dart:async';
import 'package:flutter/material.dart';
import 'user_selection_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  SplashScreenState createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoFade;
  late final Animation<Offset> _textOffset;
  late final Animation<double> _textFade;

  int dotCount = 0; // fallback loading‑dots counter

  @override
  void initState() {
    super.initState();

    // 1) Logo + text animation controller (2s total)
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    // 1a) Logo scales from 0.8 → 1.0 and fades in over the first half
    _logoScale = Tween(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack),
      ),
    );
    _logoFade = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    // 1b) “Tap to Proceed!” slides up from 20px below and fades in next
    _textOffset = Tween(begin: const Offset(0, 0.1), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.5, 0.8, curve: Curves.easeOut),
      ),
    );
    _textFade = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.5, 0.8, curve: Curves.easeIn),
      ),
    );

    _animController.forward();

    // 2) Dots “loading” fallback
    Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (!mounted) return timer.cancel();
      setState(() => dotCount = (dotCount + 1) % 4);
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _goNext() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const UserSelectionScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // disable back
      child: GestureDetector(
        onTap: _goNext,
        child: Scaffold(
          backgroundColor: const Color(0xFFFFFFFF),
          body: SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 1) Logo with scale + fade
                  FadeTransition(
                    opacity: _logoFade,
                    child: ScaleTransition(
                      scale: _logoScale,
                      child: Image.asset(
                        'assets/images/splash_logo.png',
                        height: 600,
                      ),
                    ),
                  ),

                  const SizedBox(height: 48),

                  // 2) “Tap to Proceed!” slides + fades
                  SlideTransition(
                    position: _textOffset,
                    child: FadeTransition(
                      opacity: _textFade,
                      child: const Text(
                        "Tap to Proceed!",
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0D2A5E),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),

                  const SizedBox(height: 60),

                  // 3) Animated “...” dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (i) {
                      final active = dotCount == i;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        width: active ? 14 : 10,
                        height: active ? 14 : 10,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E5D6F)
                              .withOpacity(active ? 1.0 : 0.3),
                          shape: BoxShape.circle,
                        ),
                      );
                    }),
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
