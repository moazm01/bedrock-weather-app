import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../core/theme/bedrock_theme.dart';
import '../../core/constants/bedrock_constants.dart';
import '../../domain/enums/domain_enums.dart';
import '../../core/providers/location_provider.dart';
import '../../core/providers/hazard_feed_provider.dart';
import '../../core/providers/earthquake_provider.dart';
import '../../core/providers/radar_provider.dart';
import '../../core/providers/broadcast_provider.dart';
import '../ui_components/home_widgets.dart';
import '../ui_components/foundation_widgets.dart';
import '../ui_components/map_widgets.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _showThreatBanner = true;
  bool _showSafetyCard = true;
  final MapController _mapController = MapController();

  // Opens an overlay from the bottom of the screen.
  // Reference: https://api.flutter.dev/flutter/material/showModalBottomSheet.html
  void _showBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(BedrockConstants.radiusLarge),
        ),
      ),
      builder: (context) {
        return BedrockBottomDrawer(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(BedrockConstants.space24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Abbottabad Emergency Contacts',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: BedrockConstants.space16),
                  const ListTile(
                    leading: Icon(Icons.phone_in_talk, color: Colors.red),
                    title: Text('Rescue 1122 Abbottabad'),
                    subtitle: Text('Immediate Emergency Response'),
                  ),
                  const ListTile(
                    leading: Icon(Icons.local_hospital, color: Colors.blue),
                    title: Text('Ayub Teaching Hospital'),
                    subtitle: Text('General Health & Injury Hotline'),
                  ),
                  const SizedBox(height: BedrockConstants.space16),
                  BedrockPrimaryButton(
                    text: 'Close',
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final loc = Provider.of<LocationProvider>(context, listen: false);
      Provider.of<HazardFeedProvider>(
        context,
        listen: false,
      ).startStreaming(loc.latitude, loc.longitude);
      Provider.of<EarthquakeProvider>(
        context,
        listen: false,
      ).fetchEarthquakes(loc.latitude, loc.longitude);
      loc.startTracking();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<LocationProvider>(context, listen: false).stopTracking();
      }
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final feedProvider = Provider.of<HazardFeedProvider>(context);
    final locationProvider = Provider.of<LocationProvider>(context);
    final radarProvider = Provider.of<RadarProvider>(context);
    final broadcastProvider = Provider.of<BroadcastProvider>(context);
    final latestBroadcast = broadcastProvider.latestBroadcast;

    // Calculate dynamic safety status from actual Firestore feed data
    final activeCount = feedProvider.hazards.length;
    final criticalHazards = feedProvider.hazards
        .where((h) => h.safetyStatus == SafetyStatus.critical)
        .toList();
    final hasCritical = criticalHazards.isNotEmpty;

    final maxSeverity = feedProvider.hazards.isEmpty
        ? SafetyStatus.safe
        : hasCritical
        ? SafetyStatus.critical
        : SafetyStatus.caution;

    final safetyTitle = maxSeverity == SafetyStatus.safe
        ? 'Abbottabad is Safe'
        : maxSeverity == SafetyStatus.critical
        ? 'Critical Hazard Alert'
        : 'Caution advised';

    final safetyDescription = maxSeverity == SafetyStatus.safe
        ? 'No active hazards reported currently.'
        : '$activeCount active hazard reports in the area.';

    return Scaffold(
      body: Stack(
        children: [
          // 1. Map Layer (Bottom)
          Positioned.fill(
            child: BedrockMapWidget(
              mapController: _mapController,
              onHazardTap: (hazard) {
                Navigator.of(
                  context,
                ).pushNamed('/hazard_detail', arguments: hazard);
              },
            ),
          ),

          // 2. HUD Layer (Top)
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: BedrockConstants.space16),

                // System Broadcast Banner
                if (latestBroadcast != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: BedrockConstants.space16,
                      vertical: 4,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.blueAccent.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.blue, width: 1.5),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ListTile(
                        leading: const Icon(
                          Icons.campaign_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                        title: Text(
                          latestBroadcast.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          latestBroadcast.body,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.close_rounded,
                            color: Colors.white70,
                          ),
                          onPressed: () {
                            broadcastProvider.dismissBroadcast();
                          },
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: BedrockConstants.space8),

                // Threat Banner (Dismissible)
                if (hasCritical && _showThreatBanner)
                  BedrockThreatBanner(
                    message: 'CRITICAL: ${criticalHazards.first.description}',
                    onClose: () => setState(() => _showThreatBanner = false),
                    onTap: () {
                      Navigator.of(context).pushNamed(
                        '/hazard_detail',
                        arguments: criticalHazards.first,
                      );
                    },
                  ),

                const SizedBox(height: BedrockConstants.space16),

                // Safety Status Card
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: BedrockConstants.space16,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_showSafetyCard) ...[
                        Expanded(
                          child: BedrockSafetyStatusCard(
                            status: maxSeverity,
                            title: safetyTitle,
                            description: safetyDescription,
                            onClose: () =>
                                setState(() => _showSafetyCard = false),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 3. Map Controls (Floating Right)
          Positioned(
            right: BedrockConstants.space16,
            bottom: 168.0, // Shifted up to clear floating bottom nav bar
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Weather Radar Toggle Button
                FloatingActionButton.small(
                  heroTag: 'radar_fab',
                  backgroundColor: radarProvider.isRadarVisible
                      ? Colors.blueAccent
                      : BedrockTheme.cardDark,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(color: BedrockTheme.borderSubtle),
                  ),
                  onPressed: () {
                    radarProvider.toggleRadar();
                  },
                  child: const Icon(Icons.radar),
                ),
                const SizedBox(height: 8),
                // GPS Center Button
                FloatingActionButton.small(
                  heroTag: 'locate_fab',
                  backgroundColor: BedrockTheme.cardDark,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(color: BedrockTheme.borderSubtle),
                  ),
                  onPressed: () {
                    final lat = locationProvider.latitude != 0.0
                        ? locationProvider.latitude
                        : 34.1500;
                    final lng = locationProvider.longitude != 0.0
                        ? locationProvider.longitude
                        : 73.2000;
                    _mapController.move(LatLng(lat, lng), 14.0);
                  },
                  child: const Icon(Icons.my_location),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'zoom_in_fab',
                  backgroundColor: BedrockTheme.cardDark,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(color: BedrockTheme.borderSubtle),
                  ),
                  onPressed: () {
                    _mapController.move(
                      _mapController.camera.center,
                      _mapController.camera.zoom + 0.5,
                    );
                  },
                  child: const Icon(Icons.add),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'zoom_out_fab',
                  backgroundColor: BedrockTheme.cardDark,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(color: BedrockTheme.borderSubtle),
                  ),
                  onPressed: () {
                    _mapController.move(
                      _mapController.camera.center,
                      _mapController.camera.zoom - 0.5,
                    );
                  },
                  child: const Icon(Icons.remove),
                ),
              ],
            ),
          ),

          // 4. Bottom controls
          Positioned(
            left: BedrockConstants.space16,
            right: BedrockConstants.space16,
            bottom: 96.0, // Shifted up to clear floating bottom nav bar
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                FloatingActionButton(
                  heroTag: 'feed_fab',
                  backgroundColor: BedrockTheme.cardDark,
                  foregroundColor: Theme.of(context).colorScheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: const BorderSide(color: BedrockTheme.borderSubtle),
                  ),
                  onPressed: _showBottomSheet,
                  child: const Icon(Icons.quick_contacts_dialer),
                ),

                // Emergency Report FAB
                BedrockEmergencyFAB(
                  onPressed: () async {
                    final result = await Navigator.of(
                      context,
                    ).pushNamed('/hazard_report');
                    if (result == 'new_report_submitted' && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Hazard report submitted successfully!',
                          ),
                          backgroundColor: Colors.green,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
