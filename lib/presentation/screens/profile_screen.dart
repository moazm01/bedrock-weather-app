import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/bedrock_constants.dart';
import '../../core/theme/bedrock_theme.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/user_profile_provider.dart';
import '../../core/services/image_picker_service.dart';
import '../ui_components/profile_widgets.dart';
import '../ui_components/foundation_widgets.dart';

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
            if (profile.bio != null && profile.bio!.isNotEmpty) ...[
              const SizedBox(height: BedrockConstants.space8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Text(
                  profile.bio!,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
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
                      Icons.edit_rounded,
                      color: Colors.blueAccent,
                    ),
                    title: const Text('Edit Profile Information'),
                    trailing: const Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.white24,
                    ),
                    onTap: () => _showEditProfileSheet(context),
                  ),
                  const Divider(color: BedrockTheme.borderSubtle, height: 1),
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

  void _showEditProfileSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(BedrockConstants.radiusLarge),
        ),
      ),
      builder: (modalContext) => const EditProfileSheet(),
    );
  }

  void _updateAvatar(BuildContext context, UserProfileProvider provider) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: BedrockTheme.surfaceDark,
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: Colors.amber),
            SizedBox(width: 8),
            Text('Avatar Upload Status', style: TextStyle(fontSize: 16)),
          ],
        ),
        content: const Text(
          '• Firebase Storage: Uploading custom profile avatars to Cloud Storage requires upgrading to a Firebase Blaze Plan (Pay-as-you-go).\n\n'
          '• Fallback State: Avatar fallback icons automatically generate initial-based badges with tier styling.',
          style: TextStyle(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

class EditProfileSheet extends StatefulWidget {
  const EditProfileSheet({super.key});

  @override
  State<EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<EditProfileSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _bioController;
  DateTime? _selectedBirthdate;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final profile = Provider.of<UserProfileProvider>(context, listen: false).profile;
    _nameController = TextEditingController(text: profile?.username);
    _bioController = TextEditingController(text: profile?.bio);
    _selectedBirthdate = profile?.birthdate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _selectBirthdate() async {
    final initialDate = _selectedBirthdate ?? DateTime(2000, 1, 1);
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 13)), // At least 13 years old
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: BedrockTheme.accentBlueDark,
              onPrimary: Colors.white,
              surface: BedrockTheme.surfaceDark,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      setState(() {
        _selectedBirthdate = pickedDate;
      });
    }
  }

  void _saveProfile() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isSaving = true);
      final provider = Provider.of<UserProfileProvider>(context, listen: false);
      final currentProfile = provider.profile;
      if (currentProfile != null) {
        final updated = currentProfile.copyWith(
          username: _nameController.text.trim(),
          bio: _bioController.text.trim(),
          birthdate: _selectedBirthdate,
        );
        final success = await provider.updateProfile(updated);
        if (mounted) {
          setState(() => _isSaving = false);
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Profile updated successfully!')),
            );
            Navigator.pop(context);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(provider.errorMessage ?? 'Failed to update profile.'),
                backgroundColor: BedrockTheme.hazardCriticalDark,
              ),
            );
          }
        }
      }
    }
  }

  void _confirmDeleteProfile() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: BedrockTheme.surfaceDark,
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: BedrockTheme.hazardCriticalDark),
              SizedBox(width: 8),
              Text('Delete Profile?'),
            ],
          ),
          content: const Text(
            'This action is irreversible. All your reported hazards, reputation tier score, and contributions will be permanently erased.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogContext); // Close dialog
                Navigator.pop(context); // Close bottom sheet
                
                final provider = Provider.of<UserProfileProvider>(context, listen: false);
                final success = await provider.deleteProfile();
                if (!mounted) return;
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Your account has been deleted.'),
                      backgroundColor: BedrockTheme.hazardCriticalDark,
                    ),
                  );
                  Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                }
              },
              child: const Text(
                'Delete Permanently',
                style: TextStyle(color: BedrockTheme.hazardCriticalDark, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: BedrockTheme.surfaceDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(BedrockConstants.radiusLarge)),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Edit Profile', style: Theme.of(context).textTheme.headlineMedium),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Edit Name
              BedrockTextField(
                label: 'Name',
                controller: _nameController,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Name is required';
                  }
                  if (v.trim().length < 3) {
                    return 'Name must be at least 3 characters';
                  }
                  if (v.trim().length > 20) {
                    return 'Name must be less than 20 characters';
                  }
                  if (!RegExp(r'^[a-zA-Z0-9_ ]+$').hasMatch(v)) {
                    return 'Letters, numbers, spaces, and underscores only';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Edit Bio
              BedrockTextField(
                label: 'Bio',
                hintText: 'Tell us about yourself...',
                controller: _bioController,
                maxLines: 3,
                validator: (v) {
                  if (v != null && v.length > 150) {
                    return 'Bio must be 150 characters or less';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Birthdate Selector Tile
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Birthdate'),
                subtitle: Text(
                  _selectedBirthdate != null
                      ? DateFormat('MMMM dd, yyyy').format(_selectedBirthdate!)
                      : 'Add your birthdate',
                  style: TextStyle(
                    color: _selectedBirthdate != null ? Colors.white : Colors.white60,
                  ),
                ),
                trailing: const Icon(Icons.calendar_month, color: Colors.blueAccent),
                onTap: _selectBirthdate,
              ),
              const SizedBox(height: 32),

              BedrockPrimaryButton(
                text: 'Save Changes',
                isLoading: _isSaving,
                onPressed: _saveProfile,
              ),
              const SizedBox(height: 16),

              TextButton(
                onPressed: _confirmDeleteProfile,
                child: const Text(
                  'Delete Account',
                  style: TextStyle(
                    color: BedrockTheme.hazardCriticalDark,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
