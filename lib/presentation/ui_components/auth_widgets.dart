import 'package:flutter/material.dart';
import '../../core/constants/bedrock_constants.dart';
import '../../core/theme/bedrock_theme.dart';

// BedrockDividerWithLabel displays a clean visual divider separating username/password
// forms from third-party social authentication buttons.
// Reference: https://docs.flutter.dev/ui/widgets-intro
class BedrockDividerWithLabel extends StatelessWidget {
  final String label;

  const BedrockDividerWithLabel({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: BedrockTheme.borderSubtle)),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: BedrockConstants.space16,
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: BedrockTheme.labelSecondaryDark,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.0,
            ),
          ),
        ),
        const Expanded(child: Divider(color: BedrockTheme.borderSubtle)),
      ],
    );
  }
}

// PasswordStrengthMeter draws an animated password strength indicator bar.
// It leverages simple password length logic to adjust strength colors dynamically.
// Reference: https://api.flutter.dev/flutter/widgets/AnimatedContainer-class.html
class PasswordStrengthMeter extends StatelessWidget {
  final String password;

  const PasswordStrengthMeter({super.key, required this.password});

  int _calculateStrength() {
    if (password.isEmpty) return 0;
    if (password.length < 6) return 1; // Weak
    if (password.length < 10) return 2; // Medium
    return 3; // Strong
  }

  Color _getStrengthColor(int score, BuildContext context) {
    if (score == 1) return Theme.of(context).colorScheme.error;
    if (score == 2) return BedrockTheme.hazardWarningDark;
    return BedrockTheme.hazardSafeDark;
  }

  String _getStrengthText(int score) {
    if (score == 0) return '';
    if (score == 1) return 'Weak password';
    if (score == 2) return 'Moderate password';
    return 'Strong password';
  }

  @override
  Widget build(BuildContext context) {
    final score = _calculateStrength();
    if (score == 0) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(3, (index) {
            return Expanded(
              // AnimatedContainer automatically interpolates its decoration color and sizing
              // changes over the specified duration when rebuilds occur.
              // Reference: https://docs.flutter.dev/cookbook/animation/animated-container
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 4,
                margin: EdgeInsets.only(
                  right: index < 2 ? BedrockConstants.space8 : 0,
                ),
                decoration: BoxDecoration(
                  color: index < score
                      ? _getStrengthColor(score, context)
                      : const Color(0xFF1C1C1E),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 6),
        Text(
          _getStrengthText(score),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: score == 1
                ? Theme.of(context).colorScheme.error
                : score == 2
                ? BedrockTheme.hazardWarningDark
                : BedrockTheme.hazardSafeDark,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// BedrockOAuthButton renders a stylized social auth trigger.
// It wraps an OutlinedButton in a scale-interaction gesture responder.
// Reference: https://api.flutter.dev/flutter/material/OutlinedButton-class.html
class BedrockOAuthButton extends StatefulWidget {
  final VoidCallback onPressed;
  final String text;

  const BedrockOAuthButton({
    super.key,
    required this.onPressed,
    this.text = 'Continue with Google',
  });

  @override
  State<BedrockOAuthButton> createState() => _BedrockOAuthButtonState();
}

class _BedrockOAuthButtonState extends State<BedrockOAuthButton> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.96),
      onTapUp: (_) => setState(() => _scale = 1.0),
      onTapCancel: () => setState(() => _scale = 1.0),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.onSurface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              side: const BorderSide(color: BedrockTheme.borderSubtle),
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            onPressed: widget.onPressed,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Clean Custom Google Logo shape (White circle with a blue G)
                Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  child: const Center(
                    child: Text(
                      'G',
                      style: TextStyle(
                        color: Color(0xFF4285F4),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'sans-serif',
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: BedrockConstants.space12),
                Text(
                  widget.text,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
