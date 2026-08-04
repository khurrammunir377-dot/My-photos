import 'dart:math';
import 'package:flutter/material.dart';
import '../utils/constants.dart';
import 'auth/login_screen.dart';
import 'auth/signup_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> with TickerProviderStateMixin {
  late final AnimationController _bgController;
  late final AnimationController _floatController;
  late final AnimationController _entranceController;

  static const _gradientSets = [
    [Color(0xFF7C4DFF), Color(0xFFFF4D9D), Color(0xFFFF8A3D)],
    [Color(0xFFFF4D9D), Color(0xFFFF8A3D), Color(0xFF7C4DFF)],
  ];

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat(reverse: true);
    _floatController = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);
    _entranceController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _entranceController.forward();
  }

  @override
  void dispose() {
    _bgController.dispose();
    _floatController.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  /// Staggered fade+slide entrance for a child - each element starts at [start] (0-1
  /// fraction of the entrance timeline) so they cascade in one after another.
  Widget _staggered({required double start, required Widget child}) {
    final animation = CurvedAnimation(
      parent: _entranceController,
      curve: Interval(start, (start + 0.5).clamp(0.0, 1.0), curve: Curves.easeOutCubic),
    );
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        return Opacity(
          opacity: animation.value,
          child: Transform.translate(
            offset: Offset(0, 24 * (1 - animation.value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _bgController,
        builder: (context, _) {
          final t = _bgController.value;
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.lerp(_gradientSets[0][0], _gradientSets[1][0], t)!,
                  Color.lerp(_gradientSets[0][1], _gradientSets[1][1], t)!,
                  Color.lerp(_gradientSets[0][2], _gradientSets[1][2], t)!,
                ],
              ),
            ),
            child: Stack(
              children: [
                ..._floatingIcons(),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28.0),
                    child: Column(
                      children: [
                        const Spacer(flex: 2),
                        _staggered(start: 0.0, child: _logo()),
                        const SizedBox(height: 28),
                        _staggered(
                          start: 0.15,
                          child: const Text(
                            AppConstants.appName,
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.2,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _staggered(
                          start: 0.3,
                          child: const Text(
                            'Snap a photo, drop it in the right folder,\nautomatically. No more messy camera rolls.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 15, color: Colors.white70, height: 1.4),
                          ),
                        ),
                        const Spacer(flex: 3),
                        _staggered(start: 0.45, child: _primaryButton(context)),
                        const SizedBox(height: 14),
                        _staggered(start: 0.55, child: _secondaryButton(context)),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _logo() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 30, offset: const Offset(0, 12)),
        ],
      ),
      child: Icon(Icons.photo_library_rounded, color: AppColors.primary, size: 52),
    );
  }

  List<Widget> _floatingIcons() {
    final icons = [
      (Icons.camera_alt_rounded, 0.08, 0.12, 0.0),
      (Icons.folder_rounded, 0.85, 0.18, 0.4),
      (Icons.auto_awesome, 0.12, 0.75, 0.7),
      (Icons.image_rounded, 0.82, 0.68, 0.2),
    ];
    return icons.map((spec) {
      final (icon, dx, dy, phase) = spec;
      return AnimatedBuilder(
        animation: _floatController,
        builder: (context, _) {
          final bob = sin((_floatController.value + phase) * 2 * pi) * 10;
          return Positioned(
            left: MediaQuery.of(context).size.width * dx,
            top: MediaQuery.of(context).size.height * dy + bob,
            child: Opacity(
              opacity: 0.18,
              child: Icon(icon, color: Colors.white, size: 46),
            ),
          );
        },
      );
    }).toList();
  }

  Widget _primaryButton(BuildContext context) {
    return _PressableScale(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SignupScreen())),
      child: Container(
        width: double.infinity,
        height: 54,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 16, offset: const Offset(0, 6))],
        ),
        child: Text(
          'Get Started',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
        ),
      ),
    );
  }

  Widget _secondaryButton(BuildContext context) {
    return _PressableScale(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
      child: Container(
        width: double.infinity,
        height: 54,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white, width: 1.5),
        ),
        child: const Text(
          'I already have an account',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
    );
  }
}

/// A simple press-to-scale wrapper - gives buttons a tactile "squish" feel on tap.
/// Also responds to pointer hover (relevant if this app ever runs on web/desktop).
class _PressableScale extends StatefulWidget {
  final VoidCallback onTap;
  final Widget child;
  const _PressableScale({required this.onTap, required this.child});

  @override
  State<_PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<_PressableScale> {
  double _scale = 1.0;

  void _setScale(double value) => setState(() => _scale = value);

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _setScale(1.03),
      onExit: (_) => _setScale(1.0),
      child: GestureDetector(
        onTapDown: (_) => _setScale(0.96),
        onTapUp: (_) => _setScale(1.0),
        onTapCancel: () => _setScale(1.0),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _scale,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: widget.child,
        ),
      ),
    );
  }
}
