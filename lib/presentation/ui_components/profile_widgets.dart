import 'package:flutter/material.dart';
import '../../core/constants/bedrock_constants.dart';
import '../../core/theme/bedrock_theme.dart';
import '../../domain/enums/domain_enums.dart';

Color getReputationColor(ReputationTier tier) {
  switch (tier) {
    case ReputationTier.rookie:
      return Colors.grey.shade400;
    case ReputationTier.trusted:
      return BedrockTheme.accentBlueDark;
    case ReputationTier.expert:
      return BedrockTheme.hazardCautionDark;
    case ReputationTier.veteran:
      return BedrockTheme.hazardWarningDark;
  }
}

// UserAvatarWidget displays a circular avatar showing user initials.
// It wraps a CircleAvatar inside a styled gradient ring.
// Reference: https://api.flutter.dev/flutter/material/CircleAvatar-class.html
class UserAvatarWidget extends StatelessWidget {
  final String username;
  final ReputationTier tier;
  final double radius;
  final String? avatarUrl;

  const UserAvatarWidget({
    super.key,
    required this.username,
    required this.tier,
    this.radius = 24.0,
    this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    final color = getReputationColor(tier);
    final isHighTier =
        tier == ReputationTier.expert || tier == ReputationTier.veteran;

    return Container(
      padding: const EdgeInsets.all(2.5),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: isHighTier
            ? const LinearGradient(
                colors: [Colors.purpleAccent, BedrockTheme.hazardWarningDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        border: isHighTier
            ? null
            : Border.all(color: color.withOpacity(0.3), width: 1.5),
      ),
      child: CircleAvatar(
        radius: radius - 2.5,
        backgroundColor: BedrockTheme.cardDark,
        backgroundImage: avatarUrl != null && avatarUrl!.isNotEmpty
            ? NetworkImage(avatarUrl!)
            : null,
        child: avatarUrl != null && avatarUrl!.isNotEmpty
            ? null
            : Text(
                username.isNotEmpty ? username[0].toUpperCase() : '?',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: (radius - 2.5) * 0.75,
                ),
              ),
      ),
    );
  }
}

class ReputationTierBadge extends StatelessWidget {
  final ReputationTier tier;

  const ReputationTierBadge({super.key, required this.tier});

  String _getTierName() {
    switch (tier) {
      case ReputationTier.rookie:
        return 'Rookie';
      case ReputationTier.trusted:
        return 'Trusted';
      case ReputationTier.expert:
        return 'Expert';
      case ReputationTier.veteran:
        return 'Veteran';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = getReputationColor(tier);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: BedrockConstants.space12,
        vertical: BedrockConstants.space4,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(BedrockConstants.radiusPill),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        _getTierName().toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class ReputationProgressBar extends StatelessWidget {
  final double currentScore; // 0.0 to 1.0

  const ReputationProgressBar({super.key, required this.currentScore});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Trust Coefficient',
              style: Theme.of(context).textTheme.labelSmall,
            ),
            Text(
              '${(currentScore * 100).toInt()}%',
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
        const SizedBox(height: BedrockConstants.space8),
        LinearProgressIndicator(
          value: currentScore,
          backgroundColor: Theme.of(context).colorScheme.secondary,
          valueColor: AlwaysStoppedAnimation<Color>(
            Theme.of(context).colorScheme.primary,
          ),
          minHeight: 8,
          borderRadius: BorderRadius.circular(BedrockConstants.radiusPill),
        ),
      ],
    );
  }
}

class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.iconColor = BedrockTheme.accentBlueDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(BedrockConstants.space16),
      decoration: BoxDecoration(
        color: BedrockTheme.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: BedrockTheme.borderSubtle, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(height: BedrockConstants.space12),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: BedrockTheme.labelSecondaryDark,
            ),
          ),
        ],
      ),
    );
  }
}
