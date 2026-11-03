import 'dart:math' as math;

import 'package:flutter/material.dart';

class BootSplashPage extends StatefulWidget {
  const BootSplashPage({super.key});

  @override
  State<BootSplashPage> createState() => _BootSplashPageState();
}

class _BootSplashPageState extends State<BootSplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animation;

  @override
  void initState() {
    super.initState();
    _animation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
  }

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF071B4A),
                  Color(0xFF1555C0),
                  Color(0xFF0785A8),
                ],
              ),
            ),
          ),
          IgnorePointer(
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, _) => CustomPaint(
                painter: _BootWavePainter(progress: _animation.value),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: .78, end: 1),
                duration: const Duration(milliseconds: 850),
                curve: Curves.easeOutBack,
                builder: (context, scale, child) => Opacity(
                  opacity: ((scale - .78) / .22).clamp(0, 1),
                  child: Transform.scale(scale: scale, child: child),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 190,
                      height: 190,
                      child: AnimatedBuilder(
                        animation: _animation,
                        builder: (context, _) => CustomPaint(
                          painter: _RipplePainter(progress: _animation.value),
                          child: Center(
                            child: Transform.scale(
                              scale:
                                  1 +
                                  .035 *
                                      math.sin(_animation.value * math.pi * 2),
                              child: Container(
                                width: 106,
                                height: 106,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: .16),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: .45),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.white.withValues(
                                        alpha: .12,
                                      ),
                                      blurRadius: 30,
                                      spreadRadius: 4,
                                    ),
                                  ],
                                ),
                                child: ClipOval(
                                  child: Image.asset(
                                    'assets/images/sigap_logo.png',
                                    width: 94,
                                    height: 94,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'SIGAP TSUNAMI',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sistem Informasi, Evakuasi,\ndan Kesiapsiagaan',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .78),
                        height: 1.4,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: 150,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: const LinearProgressIndicator(
                          minHeight: 3,
                          backgroundColor: Color(0x44FFFFFF),
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Menyiapkan aplikasi...',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .68),
                        fontSize: 12,
                      ),
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
}

class _RipplePainter extends CustomPainter {
  const _RipplePainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    for (var ring = 0; ring < 2; ring++) {
      final phase = (progress + ring * .5) % 1;
      canvas.drawCircle(
        center,
        48 + phase * 42,
        Paint()
          ..color = Colors.white.withValues(alpha: (1 - phase) * .28)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RipplePainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _BootWavePainter extends CustomPainter {
  const _BootWavePainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    for (var layer = 0; layer < 3; layer++) {
      final baseline = size.height * (.72 + layer * .08);
      final path = Path()..moveTo(0, baseline);
      for (var x = 0.0; x <= size.width; x += 8) {
        final angle =
            x / size.width * math.pi * 2 + progress * math.pi * 2 + layer * .85;
        final y = baseline + math.sin(angle) * (8 + layer * 4);
        path.lineTo(x, y);
      }
      path
        ..lineTo(size.width, size.height)
        ..lineTo(0, size.height)
        ..close();
      canvas.drawPath(
        path,
        Paint()
          ..color = Colors.white.withValues(alpha: .035 + layer * .012)
          ..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BootWavePainter oldDelegate) =>
      oldDelegate.progress != progress;
}
