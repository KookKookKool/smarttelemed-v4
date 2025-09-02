import 'package:flutter/material.dart';
import 'dart:math';

typedef PlusLoaderCompleted = void Function();

class PlusLoader extends StatefulWidget {
  const PlusLoader({Key? key, this.size = 80.0, this.onCompleted})
    : super(key: key);
  final double size;
  final PlusLoaderCompleted? onCompleted;

  @override
  State<PlusLoader> createState() => _PlusLoaderState();
}

class _PlusLoaderState extends State<PlusLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fillAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _fillAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _controller.forward();
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && widget.onCompleted != null) {
        widget.onCompleted!();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _fillAnimation,
        builder: (context, child) {
          return CustomPaint(
            painter: _PlusFillPainter(
              fillPercent: _fillAnimation.value,
              color: const Color(0xFF27E88D),
            ),
          );
        },
      ),
    );
  }
}

class _PlusFillPainter extends CustomPainter {
  final double fillPercent; // 0.0 - 1.0
  final Color color;
  _PlusFillPainter({required this.fillPercent, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.15)
      ..style = PaintingStyle.fill;
    final plusWidth = size.width * 0.3;
    final plusHeight = size.height * 0.8;
    final plusRect = Path()
      ..addRect(
        Rect.fromCenter(
          center: Offset(size.width / 2, size.height / 2),
          width: plusWidth,
          height: plusHeight,
        ),
      )
      ..addRect(
        Rect.fromCenter(
          center: Offset(size.width / 2, size.height / 2),
          width: plusHeight,
          height: plusWidth,
        ),
      );
    canvas.drawPath(plusRect, paint);

    // Draw wave fill
    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final clipHeight = size.height * fillPercent;
    final waveHeight = 8.0;
    final waveLength = size.width / 1.2;
    final wavePath = Path();
    final baseY = size.height - clipHeight;
    wavePath.moveTo(0, size.height);
    for (double x = 0; x <= size.width; x++) {
      double y =
          baseY +
          waveHeight *
              (1 - fillPercent) *
              (0.5 *
                  (1 + sin(2 * pi * (x / waveLength) + fillPercent * 2 * pi)));
      wavePath.lineTo(x, y);
    }
    wavePath.lineTo(size.width, size.height);
    wavePath.close();
    canvas.save();
    canvas.clipPath(plusRect);
    canvas.drawPath(wavePath, fillPaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _PlusFillPainter oldDelegate) {
    return oldDelegate.fillPercent != fillPercent || oldDelegate.color != color;
  }
}
