import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/bedrock_constants.dart';
import '../../core/theme/bedrock_theme.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/user_profile_provider.dart';
import '../../core/services/image_picker_service.dart';
import '../ui_components/profile_widgets.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profileProvider = Provider.of<UserProfileProvider>(context);
    final profile = profileProvider.profile;

    if (profile == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).pushNamed('/settings');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(BedrockConstants.space16),
        child: Column(
          children: [
            const SizedBox(height: BedrockConstants.space24),
            Center(
              child: Stack(
                children: [
                  GestureDetector(
                    onTap: () => _updateAvatar(context, profileProvider),
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: UserAvatarWidget(
                        username: profile.username,
                        tier: profile.tier,
                        radius: 48,
                        avatarUrl: profile.avatarUrl,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Colors.blueAccent,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt_rounded,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: BedrockConstants.space16),
            Text(
              profile.username,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: BedrockConstants.space8),
            ReputationTierBadge(tier: profile.tier),
            const SizedBox(height: BedrockConstants.space32),
            ReputationProgressBar(currentScore: profile.trustCoefficient),
            const SizedBox(height: BedrockConstants.space32),
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    label: 'Reports',
                    value: profile.totalReports.toString(),
                    icon: Icons.campaign,
                    iconColor: BedrockTheme.hazardCriticalDark,
                  ),
                ),
                const SizedBox(width: BedrockConstants.space16),
                Expanded(
                  child: StatCard(
                    label: 'Trust Rating',
                    value:
                        '${(profile.trustCoefficient * 100).toStringAsFixed(0)}%',
                    icon: Icons.verified,
                    iconColor: BedrockTheme.hazardSafeDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: BedrockConstants.space32),
            Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'QUICK LINKS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: BedrockTheme.labelSecondaryDark,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ),
            Material(
              color: BedrockTheme.cardDark,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: BedrockTheme.borderSubtle),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(
                      Icons.location_city_rounded,
                      color: Colors.blueAccent,
                    ),
                    title: const Text('Abbottabad Sectors'),
                    trailing: const Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.white24,
                    ),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Selected Abbottabad Sector Info'),
                        ),
                      );
                    },
                  ),
                  const Divider(color: BedrockTheme.borderSubtle, height: 1),
                  ListTile(
                    leading: const Icon(
                      Icons.security_rounded,
                      color: Colors.greenAccent,
                    ),
                    title: const Text('Safety Guidelines'),
                    trailing: const Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.white24,
                    ),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Safety Guidelines Opened'),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: BedrockConstants.space24),
            Material(
              color: BedrockTheme.cardDark,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: BedrockTheme.borderSubtle),
              ),
              child: ListTile(
                leading: const Icon(
                  Icons.logout_rounded,
                  color: Colors.redAccent,
                ),
                title: const Text(
                  'Log Out',
                  style: TextStyle(color: Colors.redAccent),
                ),
                onTap: () async {
                  final authProvider = Provider.of<AuthProvider>(
                    context,
                    listen: false,
                  );
                  final profileProvider = Provider.of<UserProfileProvider>(
                    context,
                    listen: false,
                  );

                  profileProvider.stopListening();
                  await authProvider.signOut();

                  if (context.mounted) {
                    Navigator.of(
                      context,
                    ).pushNamedAndRemoveUntil('/login', (route) => false);
                  }
                },
              ),
            ),
            const SizedBox(height: BedrockConstants.space48),
          ],
        ),
      ),
    );
  }

  void _updateAvatar(BuildContext context, UserProfileProvider provider) {
    final imagePickerService = ImagePickerService();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(BedrockConstants.radiusLarge),
        ),
      ),
      builder: (modalContext) {
        return Container(
          padding: const EdgeInsets.all(24),
          color: BedrockTheme.surfaceDark,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Update Profile Picture',
                style: Theme.of(modalContext).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded),
                title: const Text('Gallery'),
                onTap: () async {
                  Navigator.pop(modalContext);
                  final path = await imagePickerService.pickImageFromGallery();
                  if (path != null) {
                    final success = await provider.updateAvatar(path);
                    if (success && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Profile picture updated successfully!',
                          ),
                        ),
                      );
                    }
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded),
                title: const Text('Camera'),
                onTap: () async {
                  Navigator.pop(modalContext);
                  final path = await imagePickerService.pickImageFromCamera();
                  if (path != null) {
                    final success = await provider.updateAvatar(path);
                    if (success && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Profile picture updated successfully!',
                          ),
                        ),
                      );
                    }
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
