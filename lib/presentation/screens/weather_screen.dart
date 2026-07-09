import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import '../../core/constants/bedrock_constants.dart';
import '../../core/theme/bedrock_theme.dart';
import '../../core/providers/weather_provider.dart';
import '../../core/providers/location_provider.dart';
import '../../domain/models/weather_model.dart';

// WeatherScreen displays a detailed, Samsung-style AMOLED weather dashboard for Abbottabad.
// It serves as the primary screen (Tab 0) of the application.
// This is a StatefulWidget because it has scroll listeners and interactive elements.
class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  List<HourlyForecast> _hourlyForecast = [];
  List<DailyForecast> _dailyForecast = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final loc = Provider.of<LocationProvider>(context, listen: false);
      Provider.of<WeatherProvider>(
        context,
        listen: false,
      ).fetchWeather(loc.latitude, loc.longitude);
    });
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case 1:
        return 'Mon';
      case 2:
        return 'Tue';
      case 3:
        return 'Wed';
      case 4:
        return 'Thu';
      case 5:
        return 'Fri';
      case 6:
        return 'Sat';
      case 7:
        return 'Sun';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final padding = size.width > 600
        ? BedrockConstants.space24
        : BedrockConstants.space16;

    final locationProvider = Provider.of<LocationProvider>(context);
    final weatherProvider = Provider.of<WeatherProvider>(context);

    // Map live data to UI forecast lists if available
    if (weatherProvider.currentWeather != null) {
      _hourlyForecast = weatherProvider.hourlyForecast.map((w) {
        final hour = w.timestamp.hour;
        final ampm = hour >= 12 ? 'PM' : 'AM';
        final displayHour = hour % 12 == 0 ? 12 : hour % 12;
        final isNow = DateTime.now().difference(w.timestamp).inHours.abs() == 0;
        final timeStr = isNow ? 'Now' : '$displayHour $ampm';
        return HourlyForecast(
          time: timeStr,
          temp: w.temperature.round(),
          icon: w.icon,
          rainProb: '${w.precipitation.round()}%',
          mm: w.precipitation * 0.05, // Scaled representation for chart drawing
        );
      }).toList();

      _dailyForecast = weatherProvider.dailyForecast.map((w) {
        final isToday = DateTime.now().day == w.timestamp.day;
        final isYesterday =
            DateTime.now().subtract(const Duration(days: 1)).day ==
            w.timestamp.day;
        final dayStr = isToday
            ? 'Today'
            : isYesterday
            ? 'Yesterday'
            : _getDayName(w.timestamp.weekday);
        return DailyForecast(
          day: dayStr,
          icon: w.icon,
          tempMax: w.pressure.round(), // Max Temp was stored in pressure
          tempMin: w.feelsLike.round(), // Min Temp was stored in feelsLike
          rainProb: '${w.precipitation.round()}%',
        );
      }).toList();
    }

    if (weatherProvider.isLoading && _hourlyForecast.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: const Center(
          child: CircularProgressIndicator(color: Colors.blueAccent),
        ),
      );
    }

    final String updateStr = weatherProvider.currentWeather != null
        ? 'Last updated: ${_getDayName(weatherProvider.currentWeather!.timestamp.weekday)}, '
              '${weatherProvider.currentWeather!.timestamp.hour % 12 == 0 ? 12 : weatherProvider.currentWeather!.timestamp.hour % 12}:'
              '${weatherProvider.currentWeather!.timestamp.minute.toString().padLeft(2, '0')} '
              '${weatherProvider.currentWeather!.timestamp.hour >= 12 ? 'PM' : 'AM'}'
        : 'Data mock source: The Weather Channel\nUpdated 7/1, 9:21 PM';

    return Scaffold(
      backgroundColor: Colors.black, // Lock in pure black AMOLED background
      appBar: AppBar(
        title: const Text('Abbottabad'),
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.add_location_alt_rounded,
              color: Colors.blueAccent,
            ),
            tooltip: 'Report Local Weather',
            onPressed: () => _showReportWeatherDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: () {
              weatherProvider.fetchWeather(
                locationProvider.latitude,
                locationProvider.longitude,
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await locationProvider.updateLocation();
          if (context.mounted) {
            await weatherProvider.fetchWeather(
              locationProvider.latitude,
              locationProvider.longitude,
            );
          }
        },
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: padding,
            vertical: BedrockConstants.space16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Current Temperature & Condition HUD
              _buildWeatherSummaryHeader(
                weatherProvider.currentWeather,
                _dailyForecast,
              ),
              const SizedBox(height: BedrockConstants.space24),

              // 2. Hourly Forecast Scroll View (contains spline graph custom painter)
              if (_hourlyForecast.isNotEmpty) ...[
                _buildSectionHeader('Hourly Forecast'),
                const SizedBox(height: BedrockConstants.space12),
                _buildHourlyForecastCard(),
                const SizedBox(height: BedrockConstants.space16),
              ],

              // 3. Precipitation Bar Chart Card
              if (_hourlyForecast.isNotEmpty) ...[
                _buildSectionHeader('Precipitation (mm)'),
                const SizedBox(height: BedrockConstants.space12),
                _buildPrecipitationCard(),
                const SizedBox(height: BedrockConstants.space16),
              ],

              // 4. Recommendation Card ("Grab an Umbrella")
              _buildRecommendationCard(),
              const SizedBox(height: BedrockConstants.space16),

              // 5. 10-Day Forecast Table
              if (_dailyForecast.isNotEmpty) ...[
                _buildSectionHeader('7-Day Forecast'),
                const SizedBox(height: BedrockConstants.space12),
                _buildTenDayForecastCard(),
                const SizedBox(height: BedrockConstants.space16),
              ],

              // 6. Air Quality Index (AQI) Card
              _buildSectionHeader('Air Quality Index'),
              const SizedBox(height: BedrockConstants.space12),
              _buildAQICard(),
              const SizedBox(height: BedrockConstants.space16),

              // 7. Grid of Weather Metrics
              _buildMetricsGrid(weatherProvider.currentWeather),
              const SizedBox(height: BedrockConstants.space16),

              // 8. Sunrise & Sunset Cycle Custom Paint Card
              _buildSectionHeader('Sun Cycle'),
              const SizedBox(height: BedrockConstants.space12),
              _buildSunCycleCard(),
              const SizedBox(height: BedrockConstants.space16),

              // 8.5 Community Weather Reports
              _buildSectionHeader('Community Weather Updates'),
              const SizedBox(height: BedrockConstants.space12),
              _buildCommunityWeatherCard(),
              const SizedBox(height: BedrockConstants.space16),

              // 9. Moon Phase Card
              _buildMoonPhaseCard(),
              const SizedBox(height: BedrockConstants.space16),

              // 10. Footer info
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Text(
                    updateStr,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.3),
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Widget Builders
  // ---------------------------------------------------------------------------

  // Section title styling helper
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.white.withOpacity(0.6),
          fontWeight: FontWeight.bold,
          fontSize: 13,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  // Header showing temperature, description, and vector night sky mockup
  Widget _buildWeatherSummaryHeader(
    WeatherModel? current,
    List<DailyForecast> daily,
  ) {
    final tempStr = current != null ? '${current.temperature.round()}°' : '22°';
    final condStr = current != null ? current.condition : 'Mostly Cloudy';

    int maxTemp = 30;
    int minTemp = 20;
    if (daily.isNotEmpty) {
      maxTemp = daily.first.tempMax;
      minTemp = daily.first.tempMin;
    }

    final detailsStr = current != null
        ? '$maxTemp° / $minTemp°  Feels like ${current.feelsLike.round()}°'
        : '30° / 20°  Feels like 22°';

    final String timeStr;
    if (current != null) {
      final hour = current.timestamp.hour;
      final minute = current.timestamp.minute.toString().padLeft(2, '0');
      final ampm = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour % 12 == 0 ? 12 : hour % 12;
      final weekday = _getDayName(current.timestamp.weekday);
      timeStr = '$weekday, $displayHour:$minute $ampm';
    } else {
      timeStr = 'Wed, 9:21 PM';
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(BedrockConstants.space16),
          decoration: BoxDecoration(
            color: BedrockTheme.cardDark.withOpacity(0.7),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: BedrockTheme.borderSubtle.withOpacity(0.4),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Left: Temperature readouts
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tempStr,
                      style: const TextStyle(
                        fontSize: 72,
                        fontWeight: FontWeight.w200,
                        color: Colors.white,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      condStr,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      detailsStr,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      timeStr,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.4),
                      ),
                    ),
                  ],
                ),
              ),
              // Right: Vector drawing representing current night conditions
              Container(
                width: 100,
                height: 120,
                alignment: Alignment.centerRight,
                child: CustomPaint(
                  size: const Size(100, 120),
                  painter: NightSkyIllustrationPainter(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Card holding the scrollable hourly list with the spline graph
  Widget _buildHourlyForecastCard() {
    // Total width of the spline paint canvas = columns * cellWidth
    const double cellWidth = 70.0;
    final double totalWidth = _hourlyForecast.length * cellWidth;

    return Container(
      decoration: BoxDecoration(
        color: BedrockTheme.cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: BedrockTheme.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Thunderstorms. Low 20C.',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Divider(color: BedrockTheme.borderSubtle, height: 1),
          // Scrollable area holding the Stack
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: SizedBox(
              width: totalWidth,
              height: 160,
              child: Stack(
                children: [
                  // Layer 1: Background Layout of Columns (Hours, Emojis, Rain Prob)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      children: _hourlyForecast.map((h) {
                        return SizedBox(
                          width: cellWidth,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Text(
                                h.time,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.white38,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                h.icon,
                                style: const TextStyle(fontSize: 18),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                h.rainProb,
                                style: TextStyle(
                                  fontSize: 9,
                                  color: Colors.blueAccent.shade100,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  // Layer 2: CustomPaint spline overlaid on top
                  IgnorePointer(
                    child: CustomPaint(
                      size: Size(totalWidth, 160),
                      painter: HourlySplinePainter(
                        forecast: _hourlyForecast,
                        cellWidth: cellWidth,
                        accentColor: BedrockTheme.accentBlueDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Precipitation mm bar chart Card
  Widget _buildPrecipitationCard() {
    return Container(
      padding: const EdgeInsets.all(BedrockConstants.space16),
      decoration: BoxDecoration(
        color: BedrockTheme.cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: BedrockTheme.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _hourlyForecast.take(6).map((h) {
              return Expanded(
                child: Column(
                  children: [
                    Text(
                      h.time,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white30,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Bar representation
                    Container(
                      height: 60,
                      width: 14,
                      alignment: Alignment.bottomCenter,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: FractionallySizedBox(
                        // Set height ratio relative to max rain value of 4.5mm
                        heightFactor: (h.mm / 4.5).clamp(0.0, 1.0),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Colors.cyanAccent, Colors.blueAccent],
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                            ),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      h.mm == 0.0 ? '0.0' : h.mm.toStringAsFixed(2),
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white70,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              'mm of precipitation hourly',
              style: TextStyle(
                fontSize: 9,
                color: Colors.white.withOpacity(0.2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Umbrella indicator banner
  Widget _buildRecommendationCard() {
    return Container(
      padding: const EdgeInsets.all(BedrockConstants.space16),
      decoration: BoxDecoration(
        color: BedrockTheme.accentBlueDark.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: BedrockTheme.accentBlueDark.withOpacity(0.3)),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.umbrella_rounded,
            color: BedrockTheme.accentBlueDark,
            size: 24,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Grab an Umbrella!',
                  style: TextStyle(
                    color: BedrockTheme.accentBlueDark,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Thunderstorms expected around 10:45 PM.',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            '11mm',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  // Card displaying 10-day forecasts
  Widget _buildTenDayForecastCard() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: BedrockTheme.cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: BedrockTheme.borderSubtle),
      ),
      child: Column(
        children: _dailyForecast.map((d) {
          return Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 10.0,
            ),
            child: Row(
              children: [
                // Day name
                Expanded(
                  flex: 3,
                  child: Text(
                    d.day,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // Rain probability
                Expanded(
                  flex: 2,
                  child: Row(
                    children: [
                      const Icon(
                        Icons.water_drop,
                        size: 10,
                        color: Colors.blueAccent,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        d.rainProb,
                        style: const TextStyle(
                          color: Colors.blueAccent,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                // Weather icon
                Expanded(
                  flex: 2,
                  child: Text(d.icon, style: const TextStyle(fontSize: 16)),
                ),
                // Temperatures max/min
                Expanded(
                  flex: 3,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        '${d.tempMax}°',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${d.tempMin}°',
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // Air Quality Index (AQI) progress card
  Widget _buildAQICard() {
    return Container(
      padding: const EdgeInsets.all(BedrockConstants.space16),
      decoration: BoxDecoration(
        color: BedrockTheme.cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: BedrockTheme.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'AQI',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 12,
                ),
              ),
              const Text(
                'Moderate (94)',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: BedrockConstants.space12),
          // AQI bar (Moderate means yellow/orange)
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(3),
            ),
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: 0.45, // progress slider representation
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.green, Colors.tealAccent],
                  ),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Air quality is acceptable. Sensitive individuals should consider limiting heavy outdoor exertion.',
            style: TextStyle(fontSize: 10, color: Colors.white60, height: 1.3),
          ),
        ],
      ),
    );
  }

  // Grid layout showing UV Index, Humidity, Wind, Dew point, Pressure, Visibility
  Widget _buildMetricsGrid(WeatherModel? current) {
    final humidityStr = current != null
        ? '${current.humidity.round()}%'
        : '85%';
    final windStr = current != null
        ? '${current.windSpeed.toStringAsFixed(1)} km/h'
        : '11 km/h';
    final feelsLikeStr = current != null
        ? '${current.feelsLike.round()}°'
        : '22°';
    final pressureStr = current != null
        ? '${current.pressure.toStringAsFixed(0)} hPa'
        : '1000.3 mb';
    final visibilityStr = current != null
        ? '${(current.visibility / 1000).toStringAsFixed(1)} km'
        : '9.66 km';

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.6,
      crossAxisSpacing: BedrockConstants.space12,
      mainAxisSpacing: BedrockConstants.space12,
      children: [
        _buildMetricCell(
          'UV Index',
          'Low',
          Icons.wb_sunny_rounded,
          Colors.deepOrangeAccent,
        ),
        _buildMetricCell(
          'Humidity',
          humidityStr,
          Icons.opacity_rounded,
          Colors.blueAccent,
        ),
        _buildMetricCell('Wind', windStr, Icons.air_rounded, Colors.cyanAccent),
        _buildMetricCell(
          'Feels Like',
          feelsLikeStr,
          Icons.thermostat_rounded,
          Colors.purpleAccent,
        ),
        _buildMetricCell(
          'Pressure',
          pressureStr,
          Icons.speed_rounded,
          Colors.greenAccent,
        ),
        _buildMetricCell(
          'Visibility',
          visibilityStr,
          Icons.visibility_rounded,
          Colors.lightBlueAccent,
        ),
      ],
    );
  }

  Widget _buildMetricCell(
    String label,
    String value,
    IconData icon,
    Color iconColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(BedrockConstants.space12),
      decoration: BoxDecoration(
        color: BedrockTheme.cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: BedrockTheme.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 12,
                ),
              ),
              Icon(icon, size: 16, color: iconColor.withOpacity(0.8)),
            ],
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // Sun Cycle custom arc card
  Widget _buildSunCycleCard() {
    return Container(
      padding: const EdgeInsets.all(BedrockConstants.space16),
      decoration: BoxDecoration(
        color: BedrockTheme.cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: BedrockTheme.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 100,
            child: CustomPaint(
              painter: SunriseSunsetArcPainter(
                sunRatio: 0.65,
              ), // Sun positioned at 65% of day path
            ),
          ),
          const SizedBox(height: 12),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                children: [
                  Text(
                    'Sunrise',
                    style: TextStyle(color: Colors.white30, fontSize: 10),
                  ),
                  SizedBox(height: 2),
                  Text(
                    '4:59 AM',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Column(
                children: [
                  Text(
                    'Sunset',
                    style: TextStyle(color: Colors.white30, fontSize: 10),
                  ),
                  SizedBox(height: 2),
                  Text(
                    '7:22 PM',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Moon Phase Card
  Widget _buildMoonPhaseCard() {
    return Container(
      padding: const EdgeInsets.all(BedrockConstants.space16),
      decoration: BoxDecoration(
        color: BedrockTheme.cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: BedrockTheme.borderSubtle),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Moonset',
                style: TextStyle(color: Colors.white30, fontSize: 10),
              ),
              SizedBox(height: 2),
              Text(
                '5:47 AM',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Column(
            children: [
              const Text(
                '🌑', // Moon emoji
                style: TextStyle(fontSize: 32),
              ),
              const SizedBox(height: 4),
              Text(
                'Waning gibbous',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 10,
                ),
              ),
            ],
          ),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Moonrise',
                style: TextStyle(color: Colors.white30, fontSize: 10),
              ),
              SizedBox(height: 2),
              Text(
                '8:40 PM',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Show Community Weather Updates list
  Widget _buildCommunityWeatherCard() {
    if (Firebase.apps.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(BedrockConstants.space24),
        decoration: BoxDecoration(
          color: BedrockTheme.cardDark,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: BedrockTheme.borderSubtle),
        ),
        child: Column(
          children: [
            Icon(
              Icons.cloud_off_rounded,
              color: Colors.white.withOpacity(0.2),
              size: 40,
            ),
            const SizedBox(height: 12),
            Text(
              'Offline Demo Mode Active',
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Firebase is not yet configured. Connect your project to enable live weather posts.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.3),
                fontSize: 11,
              ),
            ),
          ],
        ),
      );
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('weather_reports')
          .orderBy('reportedAt', descending: true)
          .limit(10)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(color: Colors.blueAccent),
            ),
          );
        }
        if (snapshot.hasError) {
          return Container(
            padding: const EdgeInsets.all(BedrockConstants.space16),
            decoration: BoxDecoration(
              color: BedrockTheme.cardDark,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
            ),
            child: const Center(
              child: Text(
                'Could not load community updates.',
                style: TextStyle(color: Colors.redAccent, fontSize: 12),
              ),
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(BedrockConstants.space24),
            decoration: BoxDecoration(
              color: BedrockTheme.cardDark,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: BedrockTheme.borderSubtle),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.wb_sunny_outlined,
                  color: Colors.white.withOpacity(0.2),
                  size: 40,
                ),
                const SizedBox(height: 12),
                Text(
                  'No community updates reported yet.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tap the blue weather-pin icon in the App Bar to submit the first update!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.3),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          );
        }

        return Container(
          decoration: BoxDecoration(
            color: BedrockTheme.cardDark,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: BedrockTheme.borderSubtle),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: docs.length,
            separatorBuilder: (context, index) => Divider(
              color: BedrockTheme.borderSubtle.withOpacity(0.5),
              height: 1,
            ),
            itemBuilder: (context, index) {
              final data = docs[index].data();
              final double temp = (data['temp'] as num?)?.toDouble() ?? 0.0;
              final String condition = data['condition'] as String? ?? 'Clear';
              final String reporter =
                  data['reporterName'] as String? ?? 'Anonymous';
              final String tier = data['reporterTier'] as String? ?? 'Novice';
              final Timestamp? time = data['reportedAt'] as Timestamp?;
              final String notes = data['notes'] as String? ?? '';

              String timeAgo = 'Just now';
              if (time != null) {
                final diff = DateTime.now().difference(time.toDate());
                if (diff.inDays > 0) {
                  timeAgo = '${diff.inDays}d ago';
                } else if (diff.inHours > 0) {
                  timeAgo = '${diff.inHours}h ago';
                } else if (diff.inMinutes > 0) {
                  timeAgo = '${diff.inMinutes}m ago';
                }
              }

              // Color coordinate depending on temperature
              Color tempColor = Colors.orangeAccent;
              if (temp < 15) {
                tempColor = Colors.blueAccent;
              } else if (temp > 30) {
                tempColor = Colors.redAccent;
              }

              return Padding(
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
                              '${temp.round()}°C',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: tempColor,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                condition,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          timeAgo,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.3),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          '@$reporter',
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: tier == 'Expert'
                                ? Colors.purple.withOpacity(0.2)
                                : tier == 'Trusted'
                                ? Colors.blue.withOpacity(0.2)
                                : Colors.grey.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            tier.toUpperCase(),
                            style: TextStyle(
                              color: tier == 'Expert'
                                  ? Colors.purpleAccent
                                  : tier == 'Trusted'
                                  ? Colors.blueAccent
                                  : Colors.grey,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (notes.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        notes,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  // Dialog to submit weather report
  void _showReportWeatherDialog(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final double defaultTemp = 24.0;
    double temp = defaultTemp;
    String condition = 'Sunny ☀️';
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: BedrockTheme.surfaceDark,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: BedrockTheme.borderSubtle),
              ),
              title: const Row(
                children: [
                  Icon(Icons.wb_sunny, color: Colors.blueAccent),
                  SizedBox(width: 8),
                  Text(
                    'Report Local Weather',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Help train the forecasting models by reporting live local conditions in Abbottabad!',
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Temperature:',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        Text(
                          '${temp.round()}°C',
                          style: const TextStyle(
                            color: Colors.blueAccent,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: temp,
                      min: -10.0,
                      max: 50.0,
                      divisions: 60,
                      activeColor: Colors.blueAccent,
                      inactiveColor: Colors.white10,
                      onChanged: (val) {
                        setDialogState(() {
                          temp = val;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Condition:',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      dropdownColor: BedrockTheme.surfaceDark,
                      value: condition,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.03),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: BedrockTheme.borderSubtle,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Colors.blueAccent,
                          ),
                        ),
                      ),
                      items:
                          [
                            'Sunny ☀️',
                            'Cloudy ☁️',
                            'Rainy 🌧️',
                            'Stormy ⛈️',
                            'Snowy ❄️',
                            'Windy 💨',
                          ].map((item) {
                            return DropdownMenuItem<String>(
                              value: item,
                              child: Text(item),
                            );
                          }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() {
                            condition = val;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Additional Notes:',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: notesController,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'e.g. Sudden rain shower started...',
                        hintStyle: TextStyle(
                          color: Colors.white.withOpacity(0.3),
                        ),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.03),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: BedrockTheme.borderSubtle,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Colors.blueAccent,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.white30),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () async {
                    if (Firebase.apps.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Firebase is not yet configured. Please set up Firebase to submit weather reports.',
                          ),
                          backgroundColor: Colors.orangeAccent,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      Navigator.pop(context);
                      return;
                    }

                    // Read locationProvider before any asynchronous operations to avoid async gaps
                    final locationProvider = Provider.of<LocationProvider>(
                      context,
                      listen: false,
                    );
                    final double lat = locationProvider.latitude != 0.0
                        ? locationProvider.latitude
                        : 34.1500;
                    final double lng = locationProvider.longitude != 0.0
                        ? locationProvider.longitude
                        : 73.2000;

                    try {
                      final name =
                          user?.displayName ??
                          (user?.email != null
                              ? user!.email!.split('@')[0]
                              : 'Anonymous');

                      // Fetch reputation/tier info if exists
                      String tier = 'Novice';
                      if (user != null) {
                        final userDoc = await FirebaseFirestore.instance
                            .collection('users')
                            .doc(user.uid)
                            .get();
                        if (userDoc.exists) {
                          tier = userDoc.data()?['tier'] ?? 'Novice';
                        }
                      }

                      await FirebaseFirestore.instance
                          .collection('weather_reports')
                          .add({
                            'temp': temp,
                            'condition': condition,
                            'reporterName': name,
                            'reporterTier': tier,
                            'reportedAt': FieldValue.serverTimestamp(),
                            'latitude': lat,
                            'longitude': lng,
                            'notes': notesController.text.trim(),
                          });

                      // Award points to user scoring if user is logged in
                      if (user != null) {
                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(user.uid)
                            .update({
                              'totalReports': FieldValue.increment(1),
                              'trustCoefficient': FieldValue.increment(0.01),
                            });
                      }

                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Weather update submitted successfully! model training point awarded.',
                            ),
                            backgroundColor: Colors.green,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to submit report: $e'),
                            backgroundColor: Colors.redAccent,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    }
                  },
                  child: const Text(
                    'Submit',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Struct Data Types
// ---------------------------------------------------------------------------

class HourlyForecast {
  final String time;
  final int temp;
  final String icon;
  final String rainProb;
  final double mm;

  HourlyForecast({
    required this.time,
    required this.temp,
    required this.icon,
    required this.rainProb,
    required this.mm,
  });
}

class DailyForecast {
  final String day;
  final String icon;
  final int tempMax;
  final int tempMin;
  final String rainProb;

  DailyForecast({
    required this.day,
    required this.icon,
    required this.tempMax,
    required this.tempMin,
    required this.rainProb,
  });
}

// ---------------------------------------------------------------------------
// Custom Painters
// ---------------------------------------------------------------------------

// Paints a beautiful night sky vector inside the Summary Card header.
class NightSkyIllustrationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw Crescent Moon
    final moonPaint = Paint()
      ..color = Colors.white.withOpacity(0.85)
      ..style = PaintingStyle.fill;

    // Outer circle
    canvas.drawCircle(
      Offset(size.width * 0.6, size.height * 0.35),
      24,
      moonPaint,
    );

    // Mask circle (offsets to carve the crescent moon curve)
    final maskPaint = Paint()
      ..color = BedrockTheme.cardDark
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(size.width * 0.72, size.height * 0.31),
      22,
      maskPaint,
    );

    // 2. Draw Stars
    final starPaint = Paint()..color = Colors.white.withOpacity(0.6);
    canvas.drawCircle(
      Offset(size.width * 0.15, size.height * 0.25),
      1.2,
      starPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.3, size.height * 0.45),
      1.5,
      starPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.8, size.height * 0.7),
      1.0,
      starPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.4, size.height * 0.15),
      1.8,
      starPaint,
    );

    // 3. Draw a flat vector cloud overlapping
    final cloudPaint = Paint()..color = Colors.white.withOpacity(0.08);
    final cloudPath = Path()
      ..moveTo(size.width * 0.4, size.height * 0.7)
      ..arcToPoint(
        Offset(size.width * 0.6, size.height * 0.55),
        radius: const Radius.circular(15),
      )
      ..arcToPoint(
        Offset(size.width * 0.85, size.height * 0.7),
        radius: const Radius.circular(20),
      )
      ..lineTo(size.width * 0.4, size.height * 0.7)
      ..close();
    canvas.drawPath(cloudPath, cloudPaint);
  }

  @override
  bool shouldRepaint(covariant NightSkyIllustrationPainter oldDelegate) =>
      false;
}

// Draws the hourly temperatures connected by a continuous spline line graph.
class HourlySplinePainter extends CustomPainter {
  final List<HourlyForecast> forecast;
  final double cellWidth;
  final Color accentColor;

  HourlySplinePainter({
    required this.forecast,
    required this.cellWidth,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (forecast.isEmpty) return;

    // Line drawing paint properties
    final linePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final dotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // Helper bounds calculation
    const double graphTop = 90.0;
    const double graphBottom = 125.0;

    int maxTemp = forecast.map((h) => h.temp).reduce((a, b) => a > b ? a : b);
    int minTemp = forecast.map((h) => h.temp).reduce((a, b) => a < b ? a : b);
    int tempRange = (maxTemp - minTemp).clamp(1, 100);

    // Maps a temperature value to a vertical coordinate on the canvas.
    double getTempY(int temp) {
      double ratio = (temp - minTemp) / tempRange;
      return graphBottom - (ratio * (graphBottom - graphTop));
    }

    // List of coordinates for spline points
    final List<Offset> points = [];
    for (int i = 0; i < forecast.length; i++) {
      double x = (i * cellWidth) + (cellWidth / 2);
      double y = getTempY(forecast[i].temp);
      points.add(Offset(x, y));
    }

    // 1. Draw connecting line segments
    final splinePath = Path();
    splinePath.moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < points.length; i++) {
      splinePath.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(splinePath, linePaint);

    // 2. Draw labels & values at each index column
    for (int i = 0; i < forecast.length; i++) {
      final h = forecast[i];
      final pt = points[i];

      // Draw Temp Dot on the spline
      canvas.drawCircle(pt, 3.5, dotPaint);

      // Draw Temperature Text above the dot (ordinary characters, no emojis!)
      _drawText(
        canvas,
        '${h.temp}°',
        Offset(pt.dx - 10, pt.dy - 16),
        11,
        color: Colors.white,
        fontWeight: FontWeight.bold,
      );
    }
  }

  // Text layouts helper
  void _drawText(
    Canvas canvas,
    String text,
    Offset offset,
    double fontSize, {
    Color color = Colors.white,
    FontWeight fontWeight = FontWeight.normal,
  }) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: fontWeight,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant HourlySplinePainter oldDelegate) => false;
}

// Custom Painter to draw a semi-elliptical Sunrise/Sunset path arc.
class SunriseSunsetArcPainter extends CustomPainter {
  final double
  sunRatio; // Progress indicator of sun along the day path (0.0 to 1.0)

  SunriseSunsetArcPainter({required this.sunRatio});

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw dashed arc line representing the path of the sun
    final arcPaint = Paint()
      ..color = Colors.white.withOpacity(0.12)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final arcPath = Path();
    // Starting offset, quadratic control point (apex), ending offset
    arcPath.moveTo(10, size.height - 10);
    arcPath.quadraticBezierTo(
      size.width / 2,
      -20,
      size.width - 10,
      size.height - 10,
    );

    // Draw the dashed path manually by extracting segments or using a standard arc path
    canvas.drawPath(arcPath, arcPaint);

    // 2. Draw colored progress line segment along the sun path
    final progressPaint = Paint()
      ..color = const Color(0xFFE0E0E0)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    // Approximate progress using quadratic bezier parametric equations
    // B(t) = (1-t)^2 * P0 + 2*(1-t)*t * P1 + t^2 * P2
    Offset getBezierPoint(double t) {
      double x =
          (1 - t) * (1 - t) * 10 +
          2 * (1 - t) * t * (size.width / 2) +
          t * t * (size.width - 10);
      double y =
          (1 - t) * (1 - t) * (size.height - 10) +
          2 * (1 - t) * t * (-20) +
          t * t * (size.height - 10);
      return Offset(x, y);
    }

    final progressPath = Path();
    progressPath.moveTo(10, size.height - 10);
    for (double t = 0.0; t <= sunRatio; t += 0.05) {
      Offset pt = getBezierPoint(t);
      progressPath.lineTo(pt.dx, pt.dy);
    }
    canvas.drawPath(progressPath, progressPaint);

    // 3. Draw Sun indicator circle on the path apex location
    final sunOffset = getBezierPoint(sunRatio);
    final sunGlowPaint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..style = PaintingStyle.fill;
    // Outer sun glowing radius
    canvas.drawCircle(sunOffset, 10, sunGlowPaint);

    final sunCorePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(sunOffset, 5, sunCorePaint);
  }

  @override
  bool shouldRepaint(covariant SunriseSunsetArcPainter oldDelegate) {
    return oldDelegate.sunRatio != sunRatio;
  }
}
