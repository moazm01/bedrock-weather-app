import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../core/theme/bedrock_theme.dart';
import '../../domain/enums/domain_enums.dart';
import '../../domain/models/domain_models.dart';
import '../../core/providers/hazard_feed_provider.dart';
import '../../core/providers/location_provider.dart';
import '../../core/providers/radar_provider.dart';
import '../../core/providers/earthquake_provider.dart';

class BedrockMapWidget extends StatefulWidget {
  final MapController mapController;
  final Function(HazardDisplayModel)? onHazardTap;

  const BedrockMapWidget({
    super.key,
    required this.mapController,
    this.onHazardTap,
  });

  @override
  State<BedrockMapWidget> createState() => _BedrockMapWidgetState();
}

class _BedrockMapWidgetState extends State<BedrockMapWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Color _getStatusColor(SafetyStatus status) {
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
    final locationProvider = Provider.of<LocationProvider>(context);
    final feedProvider = Provider.of<HazardFeedProvider>(context);
    final radarProvider = Provider.of<RadarProvider>(context);
    final eqProvider = Provider.of<EarthquakeProvider>(context);
    final double lat = locationProvider.latitude != 0.0
        ? locationProvider.latitude
        : 34.1500;
    final double lng = locationProvider.longitude != 0.0
        ? locationProvider.longitude
        : 73.2000;
    final userCoords = LatLng(lat, lng);

    // Pakistan bounding box coordinates
    final pakistanBounds = LatLngBounds(
      const LatLng(23.5, 60.5),
      const LatLng(37.5, 77.8),
    );

    final mapWidget = FlutterMap(
      mapController: widget.mapController,
      options: MapOptions(
        initialCenter: userCoords,
        initialZoom: 14.0,
        minZoom: 5.0,
        maxZoom: 18.0,
        cameraConstraint: CameraConstraint.contain(bounds: pakistanBounds),
      ),
      children: [
        // 1. Waze-style premium dark basemap from CartoDB Dark Matter
        TileLayer(
          urlTemplate:
              'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
          subdomains: const ['a', 'b', 'c', 'd'],
          retinaMode: RetinaMode.isHighDensity(context),
          tileProvider: CancellableNetworkTileProvider(),
          userAgentPackageName: 'com.example.bedrockPhase1',
        ),

        // 1.5 Radar Tile Layer (Conditionally rendered)
        if (radarProvider.isRadarVisible &&
            radarProvider.latestTimestamp != null)
          Opacity(
            opacity: 0.5,
            child: TileLayer(
              urlTemplate:
                  'https://tilecache.rainviewer.com/v2/radar/${radarProvider.latestTimestamp}/256/{z}/{x}/{y}/2/1_1.png',
              tileProvider: CancellableNetworkTileProvider(),
              userAgentPackageName: 'com.example.bedrockPhase1',
            ),
          ),

        // 1.8 Earthquake Markers Layer (USGS)
        MarkerLayer(
          markers: eqProvider.earthquakes.map((eq) {
            final double size = 20.0 + (eq.magnitude * 5.0);
            return Marker(
              point: LatLng(eq.latitude, eq.longitude),
              width: size,
              height: size,
              child: GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        backgroundColor: BedrockTheme.surfaceDark,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: const BorderSide(
                            color: BedrockTheme.borderSubtle,
                          ),
                        ),
                        title: Row(
                          children: [
                            const Icon(
                              Icons.grid_3x3_rounded,
                              color: Colors.orangeAccent,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'M ${eq.magnitude} Earthquake',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              eq.place,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Depth: ${eq.depth} km',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Time: ${eq.time.toLocal().toString().substring(0, 16)}',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Close'),
                          ),
                        ],
                      );
                    },
                  );
                },
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: size,
                        height: size,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.orange.withOpacity(0.15),
                          border: Border.all(
                            color: Colors.orangeAccent.withOpacity(0.6),
                            width: 1.5,
                          ),
                        ),
                      ),
                      Container(
                        width: 14,
                        height: 14,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.orangeAccent,
                        ),
                        child: Center(
                          child: Text(
                            eq.magnitude.toStringAsFixed(1),
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),

        // 2. Hazard Markers Layer
        MarkerLayer(
          markers: feedProvider.hazards.map((hazard) {
            final color = _getStatusColor(hazard.safetyStatus);
            return Marker(
              point: LatLng(hazard.latitude, hazard.longitude),
              width: 44,
              height: 44,
              child: GestureDetector(
                onTap: () {
                  if (widget.onHazardTap != null) {
                    widget.onHazardTap!(hazard);
                  }
                },
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 14 + (_pulseController.value * 12),
                            height: 14 + (_pulseController.value * 12),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: color.withOpacity(
                                0.3 * (1.0 - _pulseController.value),
                              ),
                            ),
                          ),
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: color,
                              border: Border.all(
                                color: Colors.white,
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                hazard.type.emoji,
                                style: const TextStyle(fontSize: 6),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            );
          }).toList(),
        ),

        // 3. User Location Dot Marker
        MarkerLayer(
          markers: [
            Marker(
              point: userCoords,
              width: 40,
              height: 40,
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 12 + (_pulseController.value * 20),
                        height: 12 + (_pulseController.value * 20),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(
                            0xFF0A84FF,
                          ).withOpacity(0.4 * (1.0 - _pulseController.value)),
                        ),
                      ),
                      Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF0A84FF),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 4,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Container(
                            width: 5,
                            height: 5,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );

    return Stack(
      children: [
        mapWidget,
        if (!eqProvider.isUsingServerCache)
          Positioned(
            top: 16,
            right: 16,
            child: SafeArea(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.black87,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.info_outline,
                    color: Colors.amber,
                  ),
                  tooltip: 'Direct API Fallback Mode',
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (dialogContext) => AlertDialog(
                        title: const Text('Direct API Fallback'),
                        content: const Text(
                          'This earthquake data is being fetched directly from the USGS API.\n\n'
                          'To enable server-side caching and reduce device bandwidth, '
                          'deploy the getEarthquakeData Cloud Function (requires a Firebase Blaze Plan).',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
      ],
    );
  }
}
