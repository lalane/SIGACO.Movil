import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/branding/brand_colors.dart';
import '../../../core/branding/sigaco_wordmark.dart';
import '../../../core/responsive/responsive.dart';

/// Pantalla de arranque: fondo azul de marca con patron de puntos y wordmark.
class SplashPage extends StatefulWidget {
  const SplashPage({
    super.key,
    this.duration = const Duration(milliseconds: 1600),
  });

  final Duration duration;

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    Future.delayed(widget.duration, () {
      if (mounted) context.go('/login');
    });
  }

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    return Scaffold(
      backgroundColor: BrandColors.navy,
      body: Stack(
        children: [
          Positioned(
            top: 0,
            right: 0,
            child: Image.asset(
              'assets/branding/pattern.png',
              width: r.s(300),
              fit: BoxFit.fitWidth,
            ),
          ),
          Center(child: SigacoWordmark(fontSize: r.s(54))),
        ],
      ),
    );
  }
}
