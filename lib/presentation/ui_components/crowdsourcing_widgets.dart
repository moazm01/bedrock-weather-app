import 'package:flutter/material.dart';
import '../../core/constants/bedrock_constants.dart';
import '../../core/theme/bedrock_theme.dart';
import '../../domain/enums/domain_enums.dart';
import '../../domain/models/domain_models.dart';

// HazardCard is a StatelessWidget representing a single item in the feed list.
// Reference: https://docs.flutter.dev/ui/widgets-intro
class HazardCard extends StatelessWidget {
  final HazardDisplayModel hazard;
  final VoidCallback? onTap;
  final Function(bool isUpvote)? onVote;

  const HazardCard({super.key, required this.hazard, this.onTap, this.onVote});

  Color _getStatusColor(BuildContext context, SafetyStatus status) {
    switch (status) {
      case SafetyStatus.safe:
        return BedrockTheme.hazardSafeDark;
      case SafetyStatus.caution:
        return BedrockTheme.hazardWarningDark;
      case SafetyStatus.critical:
        return BedrockTheme.hazardCriticalDark;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(context, hazard.safetyStatus);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: BedrockConstants.space16),
      decoration: BoxDecoration(
        color: BedrockTheme.cardDark,
        borderRadius: BorderRadius.circular(BedrockConstants.radiusMedium),
        border: Border.all(color: BedrockTheme.borderSubtle, width: 1.0),
      ),
      // InkWell is a material widget that displays ink splash ripples when tapped.
      // It must be placed on a Material-decorated container to render properly.
      // Reference: https://docs.flutter.dev/cookbook/gestures/ripples
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(BedrockConstants.radiusMedium),
        child: Padding(
          padding: const EdgeInsets.all(BedrockConstants.space16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        hazard.type.emoji,
                        style: const TextStyle(fontSize: 24),
                      ),
                      const SizedBox(width: BedrockConstants.space8),
                      Text(
                        hazard.type.displayName,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: statusColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: BedrockConstants.space8),
              Text(
                hazard.description,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: BedrockConstants.space12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'By ${hazard.reporterName} • ${hazard.distanceMeters.toStringAsFixed(0)}m away',
                      style: Theme.of(context).textTheme.labelSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  VoteRow(
                    upvotes: hazard.upvotes,
                    downvotes: hazard.downvotes,
                    initialVote: hazard.currentUserVote,
                    onVote: onVote,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class VoteRow extends StatefulWidget {
  final int upvotes;
  final int downvotes;
  final VoteState initialVote;
  final Function(bool isUpvote)? onVote;

  const VoteRow({
    super.key,
    required this.upvotes,
    required this.downvotes,
    required this.initialVote,
    this.onVote,
  });

  @override
  State<VoteRow> createState() => _VoteRowState();
}

class _VoteRowState extends State<VoteRow> {
  late VoteState _voteState;
  late int _upvotes;
  late int _downvotes;

  @override
  void initState() {
    super.initState();
    _voteState = widget.initialVote;
    _upvotes = widget.upvotes;
    _downvotes = widget.downvotes;
  }

  @override
  void didUpdateWidget(covariant VoteRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialVote != widget.initialVote ||
        oldWidget.upvotes != widget.upvotes ||
        oldWidget.downvotes != widget.downvotes) {
      _voteState = widget.initialVote;
      _upvotes = widget.upvotes;
      _downvotes = widget.downvotes;
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = Theme.of(context).colorScheme.primary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            setState(() {
              if (_voteState == VoteState.upvoted) {
                _voteState = VoteState.none;
                _upvotes--;
                widget.onVote?.call(true); // Toggles off
              } else {
                if (_voteState == VoteState.downvoted) _downvotes--;
                _voteState = VoteState.upvoted;
                _upvotes++;
                widget.onVote?.call(true);
              }
            });
          },
          child: SizedBox(
            width: BedrockConstants.minTapTarget,
            height: BedrockConstants.minTapTarget,
            child: Center(
              child: Icon(
                _voteState == VoteState.upvoted
                    ? Icons.thumb_up_rounded
                    : Icons.thumb_up_outlined,
                size: 16,
                color: _voteState == VoteState.upvoted
                    ? activeColor
                    : BedrockTheme.labelSecondaryDark,
              ),
            ),
          ),
        ),
        Text('$_upvotes', style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(width: 4),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            setState(() {
              if (_voteState == VoteState.downvoted) {
                _voteState = VoteState.none;
                _downvotes--;
                widget.onVote?.call(false); // Toggles off
              } else {
                if (_voteState == VoteState.upvoted) _upvotes--;
                _voteState = VoteState.downvoted;
                _downvotes++;
                widget.onVote?.call(false);
              }
            });
          },
          child: SizedBox(
            width: BedrockConstants.minTapTarget,
            height: BedrockConstants.minTapTarget,
            child: Center(
              child: Icon(
                _voteState == VoteState.downvoted
                    ? Icons.thumb_down_rounded
                    : Icons.thumb_down_outlined,
                size: 16,
                color: _voteState == VoteState.downvoted
                    ? BedrockTheme.hazardCriticalDark
                    : BedrockTheme.labelSecondaryDark,
              ),
            ),
          ),
        ),
        Text('$_downvotes', style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}
