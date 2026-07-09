import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/bedrock_constants.dart';
import '../../core/theme/bedrock_theme.dart';
import '../ui_components/foundation_widgets.dart';
import '../../core/providers/location_provider.dart';
import '../../core/services/fcm_notification_service.dart';

// PermissionPrimerScreen is a StatelessWidget.
// In Flutter, a StatelessWidget has no internal mutable state. Its layout is completely
// determined by the parameters passed to its constructor at build time.
// Reference: https://docs.flutter.dev/ui/widgets-intro
class PermissionPrimerScreen extends StatelessWidget {
  const PermissionPrimerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Retreiving the viewport size to adjust layout spacings responsively.
    final size = MediaQuery.of(context).size;
    final isShort = size.height < 650;
    final padding = size.width > 600
        ? BedrockConstants.space32
        : BedrockConstants.space24;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        // CustomScrollView with SliverFillRemaining is used to prevent layout overflows
        // on extremely short device screens.
        // Reference: https://api.flutter.dev/flutter/widgets/SliverFillRemaining-class.html
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: padding,
                  vertical: BedrockConstants.space16,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Spacer(),

                    // Location Icon Container with Pulse Glow
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withOpacity(0.04),
                          border: Border.all(
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withOpacity(0.2),
                            width: 1.5,
                          ),
                        ),
                        child: Icon(
                          Icons.location_on_rounded,
                          size: isShort ? 64 : 80,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                    SizedBox(
                      height: isShort
                          ? BedrockConstants.space24
                          : BedrockConstants.space48,
                    ),

                    Text(
                      'Enable Location Alerts',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            fontSize: isShort ? 22 : 26,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: BedrockConstants.space16),
                    Text(
                      'Allowing location access lets the system push severe weather warnings for your specific area in Abbottabad and lets you broadcast live road blocks.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: BedrockTheme.labelSecondaryDark,
                        fontSize: 15,
                        height: 1.45,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const Spacer(),

                    // Named Route navigation redirects
                    // pushReplacementNamed ensures the user cannot return to the permission screen.
                    // Reference: https://docs.flutter.dev/cookbook/navigation/navigation-basics
                    BedrockPrimaryButton(
                      text: 'Share Location',
                      onPressed: () async {
                        final locationProvider = Provider.of<LocationProvider>(
                          context,
                          listen: false,
                        );
                        await locationProvider.updateLocation();

                        try {
                          final fcm = FcmNotificationService();
                          await fcm.initialize();
                          await fcm.subscribeToTopic('abbottabad_hazards');
                        } catch (_) {}

                        if (context.mounted) {
                          Navigator.of(context).pushReplacementNamed('/login');
                        }
                      },
                    ),
                    const SizedBox(height: BedrockConstants.space8),
                    BedrockSecondaryButton(
                      text: 'Skip',
                      onPressed: () {
                        Navigator.of(context).pushReplacementNamed('/login');
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
