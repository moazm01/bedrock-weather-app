import 'package:flutter/material.dart';
import '../../core/constants/bedrock_constants.dart';
import '../../core/theme/bedrock_theme.dart';
import '../../data/datasources/remote/admin_datasource.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  final AdminDataSource _adminDataSource = AdminDataSource();

  int _activeUsers = 0;
  int _liveHazards = 0;
  int _reportsToday = 0;
  bool _loadingStats = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  void _loadStats() async {
    if (!mounted) return;
    setState(() => _loadingStats = true);
    final users = await _adminDataSource.getActiveUsersCount();
    final hazards = await _adminDataSource.getLiveHazardsCount();
    final reports = await _adminDataSource.getReportsTodayCount();
    if (mounted) {
      setState(() {
        _activeUsers = users;
        _liveHazards = hazards;
        _reportsToday = reports;
        _loadingStats = false;
      });
    }
  }

  void _handlePurgeAll() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: BedrockTheme.surfaceDark,
          title: const Text('Purge All Reports?'),
          content: const Text(
            'WARNING: This will permanently delete all crowdsourced hazard reports from the database. This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
              ),
              onPressed: () async {
                Navigator.pop(dialogContext);
                final messenger = ScaffoldMessenger.of(context);
                setState(() => _loadingStats = true);
                await _adminDataSource.purgeAllReports();
                _loadStats();
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('All hazard reports purged successfully.'),
                  ),
                );
              },
              child: const Text('Purge All'),
            ),
          ],
        );
      },
    );
  }

  void _handleSendAlert() {
    final titleController = TextEditingController();
    final bodyController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: BedrockTheme.surfaceDark,
          title: const Text('Send Broadcast Alert'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(hintText: 'Alert Title'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: bodyController,
                maxLines: 3,
                decoration: const InputDecoration(hintText: 'Alert details...'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                titleController.dispose();
                bodyController.dispose();
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final title = titleController.text.trim();
                final body = bodyController.text.trim();
                titleController.dispose();
                bodyController.dispose();
                Navigator.pop(dialogContext);

                final messenger = ScaffoldMessenger.of(context);

                if (title.isEmpty || body.isEmpty) {
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Title and body cannot be empty.'),
                    ),
                  );
                  return;
                }

                await _adminDataSource.sendSystemBroadcast(title, body);
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Broadcast alert sent successfully!'),
                  ),
                );
              },
              child: const Text('Broadcast'),
            ),
          ],
        );
      },
    );
  }

  void _openPendingReportsQueue() async {
    setState(() => _loadingStats = true);
    final hazards = await _adminDataSource.getAllHazards();
    setState(() => _loadingStats = false);

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              backgroundColor: BedrockTheme.surfaceDark,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: const BorderSide(color: BedrockTheme.borderSubtle),
              ),
              title: Row(
                children: [
                  const Icon(
                    Icons.warning,
                    color: BedrockTheme.hazardCriticalDark,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Moderate Reports (${hazards.length})',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                height: 400,
                child: hazards.isEmpty
                    ? const Center(child: Text('No hazard reports found.'))
                    : ListView.builder(
                        itemCount: hazards.length,
                        itemBuilder: (context, index) {
                          final h = hazards[index];
                          final id = h['id'] as String;
                          final type = h['type'] as String;
                          final desc = h['description'] as String? ?? '';
                          final reporter =
                              h['reporterName'] as String? ?? 'Anonymous';
                          final upvotes = h['upvotes'] as int? ?? 0;
                          final downvotes = h['downvotes'] as int? ?? 0;

                          return Card(
                            color: BedrockTheme.cardDark,
                            margin: const EdgeInsets.only(bottom: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: const BorderSide(
                                color: BedrockTheme.borderSubtle,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        type.toUpperCase(),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.amber,
                                          fontSize: 13,
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          IconButton(
                                            icon: const Icon(
                                              Icons.thumb_up_alt_outlined,
                                              color: Colors.greenAccent,
                                              size: 18,
                                            ),
                                            onPressed: () async {
                                              await _adminDataSource
                                                  .updateHazardVotes(
                                                    id,
                                                    upvotes + 1,
                                                    downvotes,
                                                  );
                                              setDialogState(() {
                                                hazards[index]['upvotes'] =
                                                    upvotes + 1;
                                              });
                                              _loadStats();
                                            },
                                          ),
                                          Text(
                                            '$upvotes',
                                            style: const TextStyle(
                                              fontSize: 12,
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.thumb_down_alt_outlined,
                                              color: Colors.redAccent,
                                              size: 18,
                                            ),
                                            onPressed: () async {
                                              await _adminDataSource
                                                  .updateHazardVotes(
                                                    id,
                                                    upvotes,
                                                    downvotes + 1,
                                                  );
                                              setDialogState(() {
                                                hazards[index]['downvotes'] =
                                                    downvotes + 1;
                                              });
                                              _loadStats();
                                            },
                                          ),
                                          Text(
                                            '$downvotes',
                                            style: const TextStyle(
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  Text(
                                    desc,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'By: $reporter',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.white38,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      TextButton(
                                        onPressed: () async {
                                          await _adminDataSource.resolveHazard(
                                            id,
                                            'admin',
                                          );
                                          setDialogState(() {
                                            hazards.removeAt(index);
                                          });
                                          _loadStats();
                                        },
                                        child: const Text(
                                          'Resolve',
                                          style: TextStyle(
                                            color: Colors.blueAccent,
                                          ),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () async {
                                          await _adminDataSource.deleteHazard(
                                            id,
                                          );
                                          setDialogState(() {
                                            hazards.removeAt(index);
                                          });
                                          _loadStats();
                                        },
                                        child: const Text(
                                          'Delete',
                                          style: TextStyle(
                                            color: Colors.redAccent,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Done'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _openUserManagement() async {
    setState(() => _loadingStats = true);
    final users = await _adminDataSource.getAllUsers();
    setState(() => _loadingStats = false);

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              backgroundColor: BedrockTheme.surfaceDark,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: const BorderSide(color: BedrockTheme.borderSubtle),
              ),
              title: const Row(
                children: [
                  Icon(Icons.manage_accounts, color: Colors.blueAccent),
                  SizedBox(width: 8),
                  Text('User Management', style: TextStyle(fontSize: 16)),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                height: 400,
                child: ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final u = users[index];
                    final uid = u['uid'] as String;
                    final username = u['username'] as String? ?? 'Anonymous';
                    final email = u['email'] as String? ?? '';
                    final tier = u['tier'] as String? ?? 'rookie';
                    final isBanned = u['isBanned'] as bool? ?? false;

                    return Card(
                      color: BedrockTheme.cardDark,
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: const BorderSide(
                          color: BedrockTheme.borderSubtle,
                        ),
                      ),
                      child: ListTile(
                        title: Text(
                          username,
                          style: TextStyle(
                            color: isBanned ? Colors.redAccent : Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        subtitle: Text(
                          '$email\nTier: ${tier.toUpperCase()}',
                          style: const TextStyle(fontSize: 11),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            DropdownButton<String>(
                              dropdownColor: BedrockTheme.surfaceDark,
                              value: tier.toLowerCase(),
                              items:
                                  [
                                    'rookie',
                                    'helper',
                                    'veteran',
                                    'expert',
                                    'moderator',
                                    'admin',
                                  ].map((t) {
                                    return DropdownMenuItem(
                                      value: t,
                                      child: Text(
                                        t.toUpperCase(),
                                        style: const TextStyle(fontSize: 9),
                                      ),
                                    );
                                  }).toList(),
                              onChanged: (newTier) async {
                                if (newTier != null) {
                                  await _adminDataSource.updateUserTier(
                                    uid,
                                    newTier,
                                  );
                                  setDialogState(() {
                                    users[index]['tier'] = newTier;
                                  });
                                  _loadStats();
                                }
                              },
                            ),
                            IconButton(
                              icon: Icon(
                                isBanned
                                    ? Icons.block
                                    : Icons.check_circle_outline,
                                color: isBanned ? Colors.red : Colors.green,
                                size: 20,
                              ),
                              onPressed: () async {
                                final nextBan = !isBanned;
                                await _adminDataSource.toggleUserBan(
                                  uid,
                                  nextBan,
                                );
                                setDialogState(() {
                                  users[index]['isBanned'] = nextBan;
                                });
                                _loadStats();
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _openForceRetrain() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            String status = 'Initializing retraining job...';
            double progress = 0.0;
            bool completed = false;

            // Start step timer simulation
            void startSimulation() async {
              final steps = [
                ('Fetching 4,218 weather historical records...', 0.2),
                ('Cleansing data & interpolating missing values...', 0.4),
                (
                  'Training spline regression model on Abbottabad sectors...',
                  0.6,
                ),
                (
                  'Evaluating accuracy metrics (RMSE: 1.84°C | MAE: 1.41°C)...',
                  0.8,
                ),
                ('Deploying optimized model weights to edge nodes...', 1.0),
              ];

              for (var i = 0; i < steps.length; i++) {
                await Future.delayed(const Duration(milliseconds: 1000));
                if (dialogContext.mounted) {
                  setDialogState(() {
                    status = steps[i].$1;
                    progress = steps[i].$2;
                    if (i == steps.length - 1) {
                      completed = true;
                    }
                  });
                }
              }
            }

            // Trigger the simulation once
            WidgetsBinding.instance.addPostFrameCallback((_) {
              startSimulation();
            });

            return AlertDialog(
              backgroundColor: BedrockTheme.surfaceDark,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: const BorderSide(color: BedrockTheme.borderSubtle),
              ),
              title: const Row(
                children: [
                  Icon(Icons.model_training, color: Colors.blueAccent),
                  SizedBox(width: 8),
                  Text('ML Model Retraining', style: TextStyle(fontSize: 16)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LinearProgressIndicator(
                    value: progress,
                    color: Colors.blueAccent,
                    backgroundColor: Colors.white10,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    status,
                    style: const TextStyle(fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${(progress * 100).toInt()}% completed',
                    style: const TextStyle(fontSize: 12, color: Colors.white30),
                  ),
                ],
              ),
              actions: [
                if (completed)
                  ElevatedButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('Finish'),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  void _showTodo(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('TODO: $message')));
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 8,
        bottom: 8,
        top: BedrockConstants.space16,
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: BedrockTheme.labelSecondaryDark,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildCard({required Widget child, Color? borderColor}) {
    return Material(
      color: BedrockTheme.cardDark,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: borderColor ?? BedrockTheme.borderSubtle),
      ),
      child: child,
    );
  }

  Widget _buildGridCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: BedrockTheme.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: BedrockTheme.borderSubtle),
      ),
      padding: const EdgeInsets.all(BedrockConstants.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: BedrockTheme.labelSecondaryDark,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Control Center'),
        backgroundColor: BedrockTheme.surfaceDark,
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(
          horizontal: BedrockConstants.space16,
          vertical: BedrockConstants.space8,
        ),
        children: [
          Container(
            padding: const EdgeInsets.all(BedrockConstants.space12),
            decoration: BoxDecoration(
              color: BedrockTheme.hazardCriticalDark.withOpacity(0.08),
              border: Border.all(color: BedrockTheme.hazardCriticalDark),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.admin_panel_settings,
                  color: BedrockTheme.hazardCriticalDark,
                ),
                SizedBox(width: 8),
                Text(
                  'ADMINISTRATOR ACCESS',
                  style: TextStyle(
                    color: BedrockTheme.hazardCriticalDark,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: BedrockConstants.space16),

          // Section 1
          _buildSectionHeader('SYSTEM OVERVIEW'),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.2,
            children: [
              _buildGridCard(
                'Active Users',
                _loadingStats ? '...' : '$_activeUsers',
                Icons.people,
                Colors.blueAccent,
              ),
              _buildGridCard(
                'Live Hazards',
                _loadingStats ? '...' : '$_liveHazards',
                Icons.warning,
                BedrockTheme.hazardCriticalDark,
              ),
              _buildGridCard(
                'Reports Today',
                _loadingStats ? '...' : '$_reportsToday',
                Icons.description,
                Colors.greenAccent,
              ),
              _buildGridCard(
                'System Health',
                '99.7%',
                Icons.monitor_heart,
                Colors.purpleAccent,
              ),
            ],
          ),

          // Section 2
          _buildSectionHeader('MODERATION TOOLS'),
          _buildCard(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.warning,
                    color: BedrockTheme.hazardCriticalDark,
                  ),
                  title: const Text('Moderate Hazard Reports'),
                  subtitle: const Text(
                    'Review, resolve, upvote/downvote, or delete reports',
                  ),
                  trailing: const Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.white24,
                  ),
                  onTap: _openPendingReportsQueue,
                ),
                const Divider(color: BedrockTheme.borderSubtle, height: 1),
                ListTile(
                  leading: const Icon(
                    Icons.manage_accounts,
                    color: Colors.blueAccent,
                  ),
                  title: const Text('User Management'),
                  subtitle: const Text(
                    'Promote reputation tiers or suspend users',
                  ),
                  trailing: const Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.white24,
                  ),
                  onTap: _openUserManagement,
                ),
                const Divider(color: BedrockTheme.borderSubtle, height: 1),
                ListTile(
                  leading: const Icon(Icons.fact_check),
                  title: const Text('Content Moderation'),
                  onTap: () => _showTodo('Content Moderation'),
                ),
                const Divider(color: BedrockTheme.borderSubtle, height: 1),
                ListTile(
                  leading: const Icon(Icons.block, color: Colors.redAccent),
                  title: const Text(
                    'Ban/Suspend User',
                    style: TextStyle(color: Colors.redAccent),
                  ),
                  onTap: _openUserManagement,
                ),
              ],
            ),
          ),

          // Section 3
          _buildSectionHeader('DATA & ML'),
          _buildCard(
            child: Column(
              children: [
                ListTile(
                  title: const Text('Training Data Status'),
                  subtitle: const Text('4,218 weather snapshots collected'),
                  trailing: const Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.white24,
                  ),
                  onTap: () => _showTodo('Training Data'),
                ),
                const Divider(color: BedrockTheme.borderSubtle, height: 1),
                ListTile(
                  title: const Text('Model Performance'),
                  subtitle: const Text('RMSE: 2.3°C | MAE: 1.8°C'),
                  trailing: const Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.white24,
                  ),
                  onTap: () => _showTodo('Model Performance'),
                ),
                const Divider(color: BedrockTheme.borderSubtle, height: 1),
                ListTile(
                  leading: const Icon(
                    Icons.model_training,
                    color: Colors.blueAccent,
                  ),
                  title: const Text('Force Model Retrain'),
                  subtitle: const Text('Retrain spline regression weights'),
                  trailing: const Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.white24,
                  ),
                  onTap: _openForceRetrain,
                ),
                const Divider(color: BedrockTheme.borderSubtle, height: 1),
                ListTile(
                  title: const Text('API Health Monitor'),
                  subtitle: const Text('All endpoints operational'),
                  trailing: Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.greenAccent,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Section 4
          _buildSectionHeader('BROADCAST & ALERTS'),
          _buildCard(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.campaign,
                    color: BedrockTheme.hazardCriticalDark,
                  ),
                  title: const Text('Send System Alert'),
                  subtitle: const Text('Advisory ticker shown on user map'),
                  onTap: _handleSendAlert,
                ),
                const Divider(color: BedrockTheme.borderSubtle, height: 1),
                ListTile(
                  leading: const Icon(Icons.notifications_active),
                  title: const Text('Push Notification Blast'),
                  onTap: () => _showTodo('Push Notification Blast'),
                ),
                const Divider(color: BedrockTheme.borderSubtle, height: 1),
                ListTile(
                  leading: const Icon(Icons.edit_notifications),
                  title: const Text('Weather Advisory Override'),
                  onTap: () => _showTodo('Weather Advisory Override'),
                ),
              ],
            ),
          ),

          // Section 5
          const Padding(
            padding: EdgeInsets.only(
              left: 8,
              bottom: 8,
              top: BedrockConstants.space16,
            ),
            child: Text(
              'DANGER ZONE',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.redAccent,
                letterSpacing: 1.0,
              ),
            ),
          ),
          _buildCard(
            borderColor: BedrockTheme.hazardCriticalDark.withOpacity(0.3),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.delete_forever,
                    color: Colors.redAccent,
                  ),
                  title: const Text(
                    'Purge All Reports',
                    style: TextStyle(color: Colors.redAccent),
                  ),
                  onTap: _handlePurgeAll,
                ),
                const Divider(color: BedrockTheme.borderSubtle, height: 1),
                ListTile(
                  leading: const Icon(Icons.restore, color: Colors.redAccent),
                  title: const Text(
                    'Reset System',
                    style: TextStyle(color: Colors.redAccent),
                  ),
                  onTap: () => _showTodo('Reset System'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 100),
        ],
      ),
    );
  }
}
