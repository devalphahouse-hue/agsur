import 'package:flutter/material.dart';

/// Skeleton genérico com shimmer suave.
/// Use AppSkeleton.box, .text ou .circle conforme o caso.
class AppSkeleton extends StatefulWidget {
  const AppSkeleton._({
    required this.width,
    required this.height,
    required this.radius,
  });

  factory AppSkeleton.box({
    double width = double.infinity,
    double height = 64,
    double radius = 12,
  }) =>
      AppSkeleton._(width: width, height: height, radius: radius);

  factory AppSkeleton.text({
    double width = 120,
    double height = 12,
  }) =>
      AppSkeleton._(width: width, height: height, radius: 6);

  factory AppSkeleton.circle({double size = 40}) =>
      AppSkeleton._(width: size, height: size, radius: size);

  final double width;
  final double height;
  final double radius;

  @override
  State<AppSkeleton> createState() => _AppSkeletonState();
}

class _AppSkeletonState extends State<AppSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final t = _ctrl.value;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: LinearGradient(
              begin: const Alignment(-1.5, 0),
              end: const Alignment(1.5, 0),
              colors: const [
                Color(0x10FFFFFF),
                Color(0x22FFFFFF),
                Color(0x10FFFFFF),
              ],
              stops: [
                (t - 0.3).clamp(0.0, 1.0),
                t.clamp(0.0, 1.0),
                (t + 0.3).clamp(0.0, 1.0),
              ],
            ),
          ),
        );
      },
    );
  }
}
