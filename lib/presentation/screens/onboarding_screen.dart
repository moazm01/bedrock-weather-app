import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/bedrock_constants.dart';
import '../../core/theme/bedrock_theme.dart';
import '../ui_components/foundation_widgets.dart';
import '../../domain/models/domain_models.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  // PageController controls the viewport of the PageView and scrolls between pages programmatically.
  // Reference: https://api.flutter.dev/flutter/widgets/PageController-class.html
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingStepModel> _steps = const [
    OnboardingStepModel(
      title: 'Live Disaster Alerts',
      description:
          'Receive immediate updates on flash floods, landslides, and road collapses in Abbottabad—reported directly by local citizens.',
      iconAsset: 'warning_amber',
    ),
    OnboardingStepModel(
      title: 'Crowdsource Hazards',
      description:
          'Help protect others by reporting severe weather, flooding, or blockages in 3 seconds as soon as you encounter them.',
      iconAsset: 'add_location_alt',
    ),
    OnboardingStepModel(
      title: 'Community Verification',
      description:
          'Help verify reports nearby to increase the grid accuracy. Build your contributor rank and access priority warning updates.',
      iconAsset: 'verified_user',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/permission');
    }
  }

  @override
  Widget build(BuildContext context) {
    // MediaQuery.of(context) retrieves screen size, padding, and device orientation constraints.
    // We use it here to adjust vertical spaces dynamically on short screen devices (like web wrappers or small phones).
    // Reference: https://docs.flutter.dev/ui/layout/responsive/adaptive-apps
    final size = MediaQuery.of(context).size;
    final isShort = size.height < 650;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _steps.length,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemBuilder: (context, index) {
                  final step = _steps[index];

                  // Styled semantic gradient borders per slide
                  final List<Color> glowColors = index == 0
                      ? [
                          BedrockTheme.hazardCriticalDark,
                          BedrockTheme.hazardWarningDark,
                        ]
                      : index == 1
                      ? [BedrockTheme.accentBlueDark, Colors.cyan]
                      : [Colors.purpleAccent, BedrockTheme.hazardSafeDark];

                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: BedrockConstants.space24,
                      vertical: BedrockConstants.space16,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          height: isShort
                              ? BedrockConstants.space16
                              : BedrockConstants.space48,
                        ),

                        // Apple Style Glow Icon Container
                        Container(
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: glowColors[0].withOpacity(0.04),
                            border: Border.all(
                              color: glowColors[0].withOpacity(0.2),
                              width: 1.5,
                            ),
                          ),
                          child: Icon(
                            index == 0
                                ? Icons.warning_amber_rounded
                                : index == 1
                                ? Icons.add_location_alt_rounded
                                : Icons.verified_user_rounded,
                            size: isShort ? 64 : 80,
                            color: glowColors[0],
                          ),
                        ),
                        SizedBox(
                          height: isShort
                              ? BedrockConstants.space24
                              : BedrockConstants.space48,
                        ),
                        Text(
                          step.title,
                          style: Theme.of(context).textTheme.displayLarge
                              ?.copyWith(
                                fontSize: isShort ? 26 : 30,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.5,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: BedrockConstants.space16),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: BedrockConstants.space16,
                          ),
                          child: Text(
                            step.description,
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(
                                  color: BedrockTheme.labelSecondaryDark,
                                  fontSize: 15,
                                  height: 1.45,
                                ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Bottom Area (Controls)
            Padding(
              padding: const EdgeInsets.all(BedrockConstants.space24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Page Indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _steps.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == index ? 20 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(
                            BedrockConstants.radiusSmall,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: isShort
                        ? BedrockConstants.space16
                        : BedrockConstants.space32,
                  ),

                  // Action Buttons
                  BedrockPrimaryButton(
                    text: _currentPage == _steps.length - 1
                        ? 'Proceed to Alerts'
                        : 'Next',
                    onPressed: () {
                      if (_currentPage < _steps.length - 1) {
                        _pageController.nextPage(
                          duration: BedrockConstants.animStandard,
                          curve: Curves.easeInOut,
                        );
                      } else {
                        _completeOnboarding();
                      }
                    },
                  ),
                  if (_currentPage < _steps.length - 1) ...[
                    const SizedBox(height: BedrockConstants.space8),
                    BedrockSecondaryButton(
                      text: 'Skip Intro',
                      onPressed: _completeOnboarding,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
