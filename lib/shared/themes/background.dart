import 'package:flutter/material.dart';
import 'dart:ui';

class CircleBackground extends StatelessWidget {
  final Widget? child;
  final double leftCircleBlur;
  final double rightCircleBlur;
  const CircleBackground({
    Key? key,
    this.child,
    this.leftCircleBlur = 100, // Default blur radius for left circle
    this.rightCircleBlur = 100, // Default blur radius for right circle
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double topPercent = 0.20; // 20% of the height
        final double topOffset = constraints.maxHeight * topPercent;
        return SizedBox.expand(
          child: Stack(
            children: [
              Container(color: Colors.white),
              // Left circle with Gaussian blur effect
              Positioned(
                top: topOffset,
                left: -100,
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(
                    sigmaX: leftCircleBlur,
                    sigmaY: leftCircleBlur,
                  ),
                  child: Container(
                    width: 260,
                    height: 260,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFF24E29E), Color(0xFF14C9EA)],
                      ),
                    ),
                  ),
                ),
              ),
              // Right circle with Gaussian blur effect
              Positioned(
                top: topOffset,
                right: -100,
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(
                    sigmaX: rightCircleBlur,
                    sigmaY: rightCircleBlur,
                  ),
                  child: Container(
                    width: 260,
                    height: 260,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFF24E29E), Color(0xFF14C9EA)],
                      ),
                    ),
                  ),
                ),
              ),
              if (child != null) child!,
            ],
          ),
        );
      },
    );
  }
}
