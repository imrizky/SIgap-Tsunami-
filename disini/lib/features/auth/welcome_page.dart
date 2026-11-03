import 'package:flutter/material.dart';

/// Entry screen with direct, working paths to login and registration.
class WelcomePage extends StatefulWidget {
  const WelcomePage({
    super.key,
    required this.onLogin,
    required this.onRegister,
    required this.onContinueAsGuest,
  });

  final VoidCallback onLogin;
  final VoidCallback onRegister;
  final VoidCallback onContinueAsGuest;

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const blue = Color(0xFF2453E6);

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
                  Color(0xFF0B1E58),
                  Color(0xFF1767D5),
                  Color(0xFF087EAA),
                ],
              ),
            ),
          ),
          IgnorePointer(
            child: AnimatedBuilder(
              animation: _waveController,
              builder: (context, _) => CustomPaint(
                painter: _OceanPainter(progress: _waveController.value),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 18),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 750),
                curve: Curves.easeOutCubic,
                builder: (context, progress, child) => Opacity(
                  opacity: progress,
                  child: Transform.translate(
                    offset: Offset(0, 24 * (1 - progress)),
                    child: child,
                  ),
                ),
                child: Column(
                  children: [
                    Column(
                      children: [
                        const SizedBox(height: 34),
                        Container(
                          width: 112,
                          height: 112,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: .14),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: .35),
                            ),
                          ),
                          child: const Icon(
                            Icons.tsunami_rounded,
                            size: 66,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Sigap Tsunami',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -.5,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Informasi kesiapsiagaan dan evakuasi\nuntuk membantu Anda bertindak sigap.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: .86),
                            height: 1.45,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 58),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        FilledButton.icon(
                          key: const ValueKey('welcome-login'),
                          onPressed: widget.onLogin,
                          icon: const Icon(Icons.arrow_forward_rounded),
                          label: const Text('Masuk'),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: blue,
                            padding: const EdgeInsets.symmetric(vertical: 17),
                            textStyle: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          key: const ValueKey('welcome-register'),
                          onPressed: widget.onRegister,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: BorderSide(
                              color: Colors.white.withValues(alpha: .75),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            textStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: const Text('Daftar akun'),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: widget.onContinueAsGuest,
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white.withValues(alpha: .9),
                          ),
                          child: const Text('Jelajahi sebagai tamu'),
                        ),
                      ],
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

class _OceanPainter extends CustomPainter {
  const _OceanPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    for (var layer = 0; layer < 4; layer++) {
      final path = Path();
      final baseline = size.height * (.62 + layer * .085);
      final amplitude = 10.0 + layer * 4;
      final offset = progress * 2 * 3.141592653589793 + layer * .9;
      path.moveTo(0, baseline);
      for (var x = 0.0; x <= size.width; x += 8) {
        final y =
            baseline +
            amplitude *
                (0.5 * _sin((x / size.width * 2 * 3.141592653589793) + offset));
        path.lineTo(x, y);
      }
      path.lineTo(size.width, size.height);
      path.lineTo(0, size.height);
      path.close();
      canvas.drawPath(
        path,
        Paint()
          ..color = Colors.white.withValues(alpha: .035 + layer * .012)
          ..style = PaintingStyle.fill,
      );
      final line = Path();
      line.moveTo(0, baseline);
      for (var x = 0.0; x <= size.width; x += 8) {
        line.lineTo(
          x,
          baseline +
              amplitude *
                  (0.5 *
                      _sin((x / size.width * 2 * 3.141592653589793) + offset)),
        );
      }
      canvas.drawPath(
        line,
        Paint()
          ..color = Colors.white.withValues(alpha: .12)
          ..strokeWidth = 1.2
          ..style = PaintingStyle.stroke,
      );
    }
  }

  double _sin(double value) {
    // Smooth, deterministic wave approximation without an extra package.
    final normalized = value % (2 * 3.141592653589793);
    final x = normalized > 3.141592653589793
        ? normalized - 2 * 3.141592653589793
        : normalized;
    final x2 = x * x;
    return x * (1 - x2 / 6 + x2 * x2 / 120);
  }

  @override
  bool shouldRepaint(covariant _OceanPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
