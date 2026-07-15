import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/bedrock_constants.dart';
import '../../core/theme/bedrock_theme.dart';
import '../../core/providers/user_profile_provider.dart';
import '../../core/providers/hazard_feed_provider.dart';
import '../../domain/models/domain_models.dart';
import '../ui_components/profile_widgets.dart';
import '../ui_components/crowdsourcing_widgets.dart';

class UserProfileDetailScreen extends StatefulWidget {
  const UserProfileDetailScreen({super.key});

  @override
  State<UserProfileDetailScreen> createState() => _UserProfileDetailScreenState();
}

class _UserProfileDetailScreenState extends State<UserProfileDetailScreen> {
  UserProfileModel? _memberProfile;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadMemberProfile();
  }

  void _loadMemberProfile() async {
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final uid = args['uid'] as String;

    final profileProvider = Provider.of<UserProfileProvider>(context, listen: false);
    try {
      final profile = await profileProvider.fetchUserProfile(uid);
      if (mounted) {
        setState(() {
          _memberProfile = profile;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _handleFollowToggle() async {
    if (_memberProfile == null) return;
    final profileProvider = Provider.of<UserProfileProvider>(context, listen: false);
    
    // Optimistic UI updates
    final currentProfile = profileProvider.profile;
    if (currentProfile == null) return;

    final isFollowing = currentProfile.following.contains(_memberProfile!.uid);
    final targetFollowers = List<String>.from(_memberProfile!.followers);

    setState(() {
      if (isFollowing) {
        targetFollowers.remove(currentProfile.uid);
      } else {
        targetFollowers.add(currentProfile.uid);
      }
      _memberProfile = _memberProfile!.copyWith(followers: targetFollowers);
    });

    await profileProvider.toggleFollow(_memberProfile!.uid);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null || _memberProfile == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Contributor Profile')),
        body: Center(
          child: Text(
            _errorMessage ?? 'Failed to load profile.',
            style: const TextStyle(color: Colors.redAccent),
          ),
        ),
      );
    }

    final profileProvider = Provider.of<UserProfileProvider>(context);
    final currentProfile = profileProvider.profile;
    final feedProvider = Provider.of<HazardFeedProvider>(context);

    final isMe = currentProfile?.uid == _memberProfile!.uid;
    final isFollowing = currentProfile?.following.contains(_memberProfile!.uid) ?? false;

    // Filter contributions from hazard feed
    final contributions = feedProvider.hazards
        .where((h) => h.reporterId == _memberProfile!.uid)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('${_memberProfile!.username}\'s Profile'),
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(BedrockConstants.space16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: BedrockConstants.space16),
            Center(
              child: UserAvatarWidget(
                username: _memberProfile!.username,
                tier: _memberProfile!.tier,
                radius: 48,
                avatarUrl: _memberProfile!.avatarUrl,
              ),
            ),
            const SizedBox(height: BedrockConstants.space16),
            Center(
              child: Text(
                _memberProfile!.username,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            const SizedBox(height: BedrockConstants.space8),
            Center(child: ReputationTierBadge(tier: _memberProfile!.tier)),
            const SizedBox(height: BedrockConstants.space24),

            // Bio Section
            if (_memberProfile!.bio != null && _memberProfile!.bio!.isNotEmpty) ...[
              Text(
                'BIO',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: BedrockTheme.labelSecondaryDark,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: BedrockConstants.space8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: BedrockTheme.cardDark,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: BedrockTheme.borderSubtle),
                ),
                child: Text(
                  _memberProfile!.bio!,
                  style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
                ),
              ),
              const SizedBox(height: BedrockConstants.space24),
            ],

            // Stats row
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: BedrockTheme.cardDark,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: BedrockTheme.borderSubtle),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '${_memberProfile!.followers.length}',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        const Text('Followers', style: TextStyle(color: Colors.white54, fontSize: 11)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: BedrockConstants.space12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: BedrockTheme.cardDark,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: BedrockTheme.borderSubtle),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '${_memberProfile!.following.length}',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        const Text('Following', style: TextStyle(color: Colors.white54, fontSize: 11)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: BedrockConstants.space12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: BedrockTheme.cardDark,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: BedrockTheme.borderSubtle),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '${contributions.length}',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        const Text('Reports', style: TextStyle(color: Colors.white54, fontSize: 11)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: BedrockConstants.space24),

            // Follow/Unfollow Button (Only show if not looking at self)
            if (!isMe) ...[
              SizedBox(
                height: 46,
                child: ElevatedButton(
                  onPressed: _handleFollowToggle,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isFollowing
                        ? const Color(0xFF1C1C1E)
                        : Theme.of(context).colorScheme.primary,
                    foregroundColor: isFollowing
                        ? Theme.of(context).colorScheme.primary
                        : Colors.white,
                    side: isFollowing
                        ? const BorderSide(color: BedrockTheme.borderSubtle)
                        : BorderSide.none,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: Text(
                    isFollowing ? 'Following' : 'Follow Contributor',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                ),
              ),
              const SizedBox(height: BedrockConstants.space32),
            ],

            // Past contributions title
            Text(
              'ACTIVE CONTRIBUTIONS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: BedrockTheme.labelSecondaryDark,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: BedrockConstants.space12),

            if (contributions.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    'No active hazard reports from this user in this sector.',
                    style: TextStyle(color: Colors.white30, fontSize: 13),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: contributions.length,
                itemBuilder: (context, index) {
                  final item = contributions[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: BedrockConstants.space12),
                    child: HazardCard(
                      hazard: item,
                      onTap: () {
                        Navigator.of(context).pushNamed(
                          '/hazard_detail',
                          arguments: item,
                        );
                      },
                      onVote: (isUpvote) {
                        feedProvider.vote(item.id, isUpvote);
                      },
                    ),
                  );
                },
              ),
            const SizedBox(height: BedrockConstants.space24),
          ],
        ),
      ),
    );
  }
}
