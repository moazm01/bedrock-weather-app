import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/bedrock_constants.dart';
import '../../core/theme/bedrock_theme.dart';
import '../ui_components/crowdsourcing_widgets.dart';
import '../../domain/models/domain_models.dart';
import '../../domain/enums/domain_enums.dart';
import '../../core/providers/hazard_feed_provider.dart';
import '../../core/providers/location_provider.dart';
import '../../core/providers/reliefweb_provider.dart';

class HazardFeedScreen extends StatefulWidget {
  const HazardFeedScreen({super.key});

  @override
  State<HazardFeedScreen> createState() => _HazardFeedScreenState();
}

class _HazardFeedScreenState extends State<HazardFeedScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final loc = Provider.of<LocationProvider>(context, listen: false);
      Provider.of<HazardFeedProvider>(
        context,
        listen: false,
      ).startStreaming(loc.latitude, loc.longitude);
      Provider.of<ReliefWebProvider>(context, listen: false).fetchReports();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<HazardDisplayModel> _getFilteredHazards(
    List<HazardDisplayModel> allHazards,
    int tabIndex,
  ) {
    if (tabIndex == 0) {
      return allHazards;
    }
    if (tabIndex == 1) {
      return allHazards
          .where(
            (h) =>
                h.type == HazardType.flood || h.type == HazardType.flashFlood,
          )
          .toList();
    }
    if (tabIndex == 2) {
      return allHazards
          .where(
            (h) =>
                h.type == HazardType.roadBlock ||
                h.type == HazardType.landslide,
          )
          .toList();
    }
    return allHazards;
  }

  @override
  Widget build(BuildContext context) {
    final feedProvider = Provider.of<HazardFeedProvider>(context);
    final locationProvider = Provider.of<LocationProvider>(context);
    final reliefWebProvider = Provider.of<ReliefWebProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Abbottabad Hazard Feed'),
        actions: [
          if (!reliefWebProvider.isUsingServerCache)
            IconButton(
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
                      'This UN ReliefWeb feed is being fetched directly from the ReliefWeb API.\n\n'
                      'To enable server-side caching and reduce device bandwidth, '
                      'deploy the getReliefWebReports Cloud Function (requires a Firebase Blaze Plan).',
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
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            height: 38,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C1E),
              borderRadius: BorderRadius.circular(10),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Theme.of(context).colorScheme.primary,
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.normal,
                fontSize: 12,
              ),
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(text: 'All Alerts'),
                Tab(text: 'Floods'),
                Tab(text: 'Road Blocks'),
                Tab(text: 'UN ReliefWeb'),
              ],
              onTap: (index) {
                setState(() {});
              },
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await locationProvider.updateLocation();
          if (context.mounted) {
            Provider.of<HazardFeedProvider>(
              context,
              listen: false,
            ).startStreaming(
              locationProvider.latitude,
              locationProvider.longitude,
            );
            await Provider.of<ReliefWebProvider>(
              context,
              listen: false,
            ).fetchReports();
          }
        },
        child: TabBarView(
          controller: _tabController,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            // Tab 0: All Alerts
            _buildHazardsList(
              feedProvider.hazards,
              0,
              feedProvider.isLoading,
              feedProvider.errorMessage,
            ),
            // Tab 1: Floods
            _buildHazardsList(
              feedProvider.hazards,
              1,
              feedProvider.isLoading,
              feedProvider.errorMessage,
            ),
            // Tab 2: Road Blocks
            _buildHazardsList(
              feedProvider.hazards,
              2,
              feedProvider.isLoading,
              feedProvider.errorMessage,
            ),
            // Tab 3: UN ReliefWeb
            _buildReliefWebList(reliefWebProvider),
          ],
        ),
      ),
    );
  }

  Widget _buildHazardsList(
    List<HazardDisplayModel> allHazards,
    int tabIndex,
    bool isLoading,
    String? errorMessage,
  ) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            'Error: $errorMessage',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.redAccent),
          ),
        ),
      );
    }
    final hazards = _getFilteredHazards(allHazards, tabIndex);
    if (hazards.isEmpty) {
      return const Center(child: Text('No active alerts in this category.'));
    }
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.symmetric(vertical: BedrockConstants.space16),
      itemCount: hazards.length,
      itemBuilder: (context, index) {
        final item = hazards[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: BedrockConstants.space16),
          child: HazardCard(
            hazard: item,
            onTap: () {
              Navigator.of(
                context,
              ).pushNamed('/hazard_detail', arguments: item);
            },
            onVote: (isUpvote) {
              final feedProvider = Provider.of<HazardFeedProvider>(
                context,
                listen: false,
              );
              feedProvider.vote(item.id, isUpvote);
            },
          ),
        );
      },
    );
  }

  Widget _buildReliefWebList(ReliefWebProvider provider) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            'Error: ${provider.errorMessage}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.redAccent),
          ),
        ),
      );
    }
    if (provider.reports.isEmpty) {
      return const Center(
        child: Text('No UN ReliefWeb situation reports found.'),
      );
    }
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.symmetric(vertical: BedrockConstants.space16),
      itemCount: provider.reports.length,
      itemBuilder: (context, index) {
        final report = provider.reports[index];
        return Card(
          color: BedrockTheme.cardDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: BedrockTheme.borderSubtle),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            title: Text(
              report.title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 14,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.source_rounded,
                      size: 12,
                      color: Colors.blueAccent,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        report.source,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_rounded,
                      size: 12,
                      color: Colors.white30,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      report.date.toLocal().toString().substring(0, 10),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            trailing: const Icon(
              Icons.open_in_new_rounded,
              color: Colors.white54,
            ),
            onTap: () async {
              final uri = Uri.parse(report.url);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
          ),
        );
      },
    );
  }
}
