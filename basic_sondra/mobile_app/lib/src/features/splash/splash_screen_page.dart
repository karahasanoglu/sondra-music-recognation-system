import 'dart:async';
import 'package:flutter/material.dart';
import '../home/song_finder_page.dart';

class SplashScreenPage extends StatefulWidget {
  const SplashScreenPage({super.key});

  @override
  State<SplashScreenPage> createState() => _SplashScreenPageState();
}

class _SplashScreenPageState extends State<SplashScreenPage> with TickerProviderStateMixin {
  late final AnimationController _pulseController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2500),
  )..repeat();

  late final AnimationController _entranceController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  late final Animation<double> _scaleAnimation = CurvedAnimation(
    parent: _entranceController,
    curve: Curves.elasticOut,
  );

  late final Animation<double> _fadeAnimation = CurvedAnimation(
    parent: _entranceController,
    curve: const Interval(0.4, 1.0, curve: Curves.easeIn),
  );

  @override
  void initState() {
    super.initState();
    _entranceController.forward();
    
    Future.delayed(const Duration(milliseconds: 3200), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 1000),
            pageBuilder: (_, __, ___) => const SongFinderPage(),
            transitionsBuilder: (_, animation, __, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient Base (Vibrant Greens)
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [Color(0xFF052E16), Color(0xFF15803D), Color(0xFF022C11)],
                ),
              ),
            ),
          ),
          // Deep Glow Orb 1
          Positioned(
            top: -150,
            right: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF22C55E).withOpacity(0.3),
                    const Color(0xFF22C55E).withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),
          // Deep Glow Orb 2
          Positioned(
            bottom: -150,
            left: -100,
            child: Container(
              width: 450,
              height: 450,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF16A34A).withOpacity(0.4),
                    const Color(0xFF16A34A).withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),
          
          // Main Center View
          Center(
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    // Sonar Ripples
                    ...List.generate(3, (index) {
                      return _buildRipple(_pulseController.value, index);
                    }),
                    // Central Icon Core (Scaling Entrance)
                    ScaleTransition(
                      scale: _scaleAnimation,
                      child: Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.transparent, // Fully relying on the image
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF86EFAC).withOpacity(0.6),
                              blurRadius: 40,
                              spreadRadius: 8,
                            ),
                            BoxShadow(
                              color: const Color(0xFF14532D).withOpacity(0.4),
                              blurRadius: 80,
                              spreadRadius: 25,
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                             ClipRRect(
                               borderRadius: BorderRadius.circular(40), // Curved edges if the logo has them
                               child: Image.asset(
                                 'assets/app_logo.png',
                                 width: 120,
                                 height: 120,
                               ),
                             ),
                            const SizedBox(height: 16),
                            FadeTransition(
                              opacity: _fadeAnimation,
                              child: const Text(
                                'Sondra',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 30,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 2.0,
                                  shadows: [
                                    Shadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRipple(double animationValue, int index) {
    // Stagger 3 ripples offset evenly across 1.0 phase
    double progress = (animationValue + (index / 3.0)) % 1.0;
    
    // Grow from scale 1.0 to 3.0
    double scale = 1.0 + (progress * 1.5);
    // Opacity sharply vanishes at the edge
    double opacity = (1.0 - progress).clamp(0.0, 1.0) * 0.5;
    
    return Transform.scale(
      scale: scale,
      child: Container(
        width: 180,
        height: 180,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: const Color(0xFF86EFAC).withOpacity(opacity),
            width: 4,
          ),
        ),
      ),
    );
  }
}
