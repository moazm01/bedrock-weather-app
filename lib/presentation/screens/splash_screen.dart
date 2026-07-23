import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/bedrock_constants.dart';
import '../../core/theme/bedrock_theme.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/user_profile_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

// SingleTickerProviderStateMixin is used because this state class serves as the ticker provider (vsync)
// for exactly one AnimationController. If there were multiple controllers, we would use TickerProviderStateMixin.
// Official Reference: https://docs.flutter.dev/ui/animations/tutorial
class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  // The AnimationController generates double values between 0.0 and 1.0 sequentially over a duration.
  // Reference: https://api.flutter.dev/flutter/animation/AnimationController-class.html
  late AnimationController _controller;
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _textOpacity;
  late Animation<double> _glowScale;

  // initState is the first method called when this widget is inserted into the element tree.
  // Use it to initialize variables, controllers, and start asynchronous timers.
  // Reference: https://api.flutter.dev/flutter/widgets/State/initState.html
  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync:
          this, // vsync prevents animations from consuming resources when screen is off.
      duration: const Duration(milliseconds: 1600),
    );

    _logoScale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.elasticOut),
      ),
    );

    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
      ),
    );

    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 0.8, curve: Curves.easeIn),
      ),
    );

    _glowScale = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0, curve: Curves.slowMiddle),
      ),
    );

    // Start animations
    _controller.forward();

    // Wait 2.2 seconds, check onboarding & auth state, then route accordingly.
    Timer(const Duration(milliseconds: 2200), () async {
      if (!mounted) return;

      final prefs = await SharedPreferences.getInstance();
      final isOnboardingComplete =
          prefs.getBool('onboarding_complete') ?? false;

      if (!mounted) return;

      if (!isOnboardingComplete) {
        Navigator.of(context).pushReplacementNamed('/onboarding');
      } else {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        if (authProvider.isAuthenticated) {
          final uid = authProvider.currentUserId;
          if (uid != null) {
            Provider.of<UserProfileProvider>(
              context,
              listen: false,
            ).startListening(uid);
          }
          Navigator.of(context).pushReplacementNamed('/main');
        } else {
          Navigator.of(context).pushReplacementNamed('/login');
        }
      }
    });
  }

  // dispose is called when this State object is permanently removed from the widget tree.
  // We must release animation controller tickers to avoid memory leaks.
  // Reference: https://api.flutter.dev/flutter/widgets/State/dispose.html
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                // Soft ambient glow background ring
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _glowScale.value,
                      child: Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(
                                context,
                              ).colorScheme.primary.withOpacity(0.08),
                              blurRadius: 40,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                // Pulsing shield logo
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _logoOpacity.value,
                      child: Transform.scale(
                        scale: _logoScale.value,
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: BedrockTheme.cardDark,
                            border: Border.all(
                              color: BedrockTheme.borderSubtle,
                              width: 1.0,
                            ),
                          ),
                          child: Image.asset(
                            'assets/icons/logo.png',
                            width: 80,
                            height: 80,
                            errorBuilder: (context, error, stackTrace) => Icon(
                              Icons.shield_outlined,
                              size: 64,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: BedrockConstants.space32),

            // Title and Subtitle text fade-in
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Opacity(
                  opacity: _textOpacity.value,
                  child: Column(
                    children: [
                      Text(
                        'BEDROCK',
                        style: Theme.of(context).textTheme.displayLarge
                            ?.copyWith(letterSpacing: 6.0, fontSize: 28),
                      ),
                      const SizedBox(height: BedrockConstants.space12),
                      Text(
                        'Abbottabad Weather & Disaster Alerts',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: BedrockTheme.labelSecondaryDark,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
