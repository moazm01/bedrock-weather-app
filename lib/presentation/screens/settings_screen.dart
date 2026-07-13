import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:provider/provider.dart';
import '../../core/constants/bedrock_constants.dart';
import '../../core/theme/bedrock_theme.dart';
import '../ui_components/foundation_widgets.dart';
import '../../core/services/biometric_service.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/user_profile_provider.dart';
import '../../domain/enums/domain_enums.dart';

// SettingsScreen is a StatefulWidget because we modify local switch states.
// Reference: https://docs.flutter.dev/ui/interactivity
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _biometricEnabled = false;
  int _versionTapCount = 0;

  final BiometricService _biometricService = BiometricService();

  @override
  void initState() {
    super.initState();
    _checkBiometricState();
  }

  void _checkBiometricState() async {
    final enabled = await _biometricService.isBiometricsEnabled();
    setState(() {
      _biometricEnabled = enabled;
    });
  }

  void _toggleBiometrics(bool enable) async {
    if (!enable) {
      await _biometricService.disableBiometrics();
      setState(() {
        _biometricEnabled = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Biometric login disabled.')),
        );
      }
      return;
    }

    final available = await _biometricService.isBiometricsAvailable();
    if (!available) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Biometric authentication is not supported on this device.',
            ),
          ),
        );
      }
      return;
    }

    // Prompt for password
    if (!mounted) return;
    final passwordController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: BedrockTheme.surfaceDark,
          title: const Text('Enable Biometric Login'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Enter your account password to confirm biometric setup',
                style: TextStyle(
                  color: BedrockTheme.labelSecondaryDark,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(hintText: 'Password'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                passwordController.dispose();
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final password = passwordController.text.trim();
                passwordController.dispose();
                Navigator.pop(context);

                if (password.isEmpty) {
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    const SnackBar(content: Text('Password cannot be empty.')),
                  );
                  return;
                }

                final messenger = ScaffoldMessenger.of(context);
                // Confirm identity with biometric authentication
                final authenticated = await _biometricService.authenticate();
                if (authenticated) {
                  final email = FirebaseAuth.instance.currentUser?.email;
                  if (email != null) {
                    await _biometricService.enableBiometrics(email, password);
                    if (mounted) {
                      setState(() {
                        _biometricEnabled = true;
                      });
                    }
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('Biometric login enabled successfully!'),
                      ),
                    );
                  }
                } else {
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Biometric verification failed.'),
                    ),
                  );
                }
              },
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  void _accessAdminPanel() async {
    final available = await _biometricService.isBiometricsAvailable();
    if (available) {
      final authenticated = await _biometricService.authenticate();
      if (authenticated) {
        if (mounted) {
          Navigator.of(context).pushNamed('/admin_panel');
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Authentication failed.'),
              backgroundColor: BedrockTheme.hazardCriticalDark,
            ),
          );
        }
      }
    } else {
      Navigator.of(context).pushNamed('/admin_panel');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
      // ListView lays out children sequentially inside a scrollable view.
      // Reference: https://api.flutter.dev/flutter/widgets/ListView-class.html
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(
          horizontal: BedrockConstants.space16,
          vertical: BedrockConstants.space8,
        ),
        children: [
          // Section 1: PREFERENCES
          const Padding(
            padding: EdgeInsets.only(
              left: 8,
              bottom: 8,
              top: BedrockConstants.space16,
            ),
            child: Text(
              'GENERAL PREFERENCES',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: BedrockTheme.labelSecondaryDark,
                letterSpacing: 1.0,
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
                  leading: Icon(
                    Icons.notifications_rounded,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: const Text('Push Notifications'),
                  trailing: Switch.adaptive(
                    value: _notificationsEnabled,
                    activeColor: Theme.of(context).colorScheme.primary,
                    onChanged: (v) {
                      setState(() {
                        _notificationsEnabled = v;
                      });
                    },
                  ),
                ),
                const Divider(height: 1, color: BedrockTheme.borderSubtle),
                ListTile(
                  leading: Icon(
                    Icons.fingerprint_rounded,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: const Text('Biometric Login'),
                  trailing: Switch.adaptive(
                    value: _biometricEnabled,
                    activeColor: Theme.of(context).colorScheme.primary,
                    onChanged: (v) {
                      _toggleBiometrics(v);
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: BedrockConstants.space24),

          // Section 2: DEV TOOLS / RUBRIC DEMO
          const Padding(
            padding: EdgeInsets.only(left: 8, bottom: 8),
            child: Text(
              'INTERACTIVE COMPONENTS SHOWCASE',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: BedrockTheme.labelSecondaryDark,
                letterSpacing: 1.0,
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
            child: ListTile(
              leading: const Icon(
                Icons.science_outlined,
                color: Colors.purpleAccent,
              ),
              title: const Text('Interactive Widgets Lab'),
              subtitle: const Text(
                'Abbottabad Grid, Radio, Slider & Date/Time Pickers',
              ),
              trailing: const Icon(
                Icons.chevron_right_rounded,
                color: Colors.white30,
              ),
              onTap: () {
                Navigator.of(context).pushNamed('/widgets_lab');
              },
            ),
          ),
          const SizedBox(height: BedrockConstants.space32),

          // Red destructive log out styling
          Theme(
            data: Theme.of(context).copyWith(
              colorScheme: Theme.of(
                context,
              ).colorScheme.copyWith(primary: BedrockTheme.hazardCriticalDark),
            ),
            child: BedrockSecondaryButton(
              text: 'Log Out',
              onPressed: () async {
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
          const SizedBox(height: BedrockConstants.space32),
          const Padding(
            padding: EdgeInsets.only(left: 8, bottom: 8),
            child: Text(
              'ABOUT',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: BedrockTheme.labelSecondaryDark,
                letterSpacing: 1.0,
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
            child: GestureDetector(
              onTap: () {
                final profile = Provider.of<UserProfileProvider>(context, listen: false).profile;
                setState(() {
                  _versionTapCount++;
                  if (_versionTapCount >= 5) {
                    _versionTapCount = 0;
                    if (profile?.tier == ReputationTier.admin) {
                      _accessAdminPanel();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Access denied. Administrator privileges required.'),
                          backgroundColor: BedrockTheme.hazardCriticalDark,
                        ),
                      );
                    }
                  }
                });
              },
              child: ListTile(
                leading: const Icon(
                  Icons.info_outline_rounded,
                  color: BedrockTheme.labelSecondaryDark,
                ),
                title: const Text('Version'),
                subtitle: const Text('1.0.0 (Phase 1)'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
