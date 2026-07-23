// Clean Architecture: Domain models
class AdminAction {
  final String actionType;
  final String targetId;
  final String performedBy;
  final DateTime timestamp;

  const AdminAction({
    required this.actionType,
    required this.targetId,
    required this.performedBy,
    required this.timestamp,
  });
}

class SystemStats {
  final int totalUsers;
  final int totalReports;
  final int activeHazards;
  final int pendingReports;
  final double systemHealth;

  const SystemStats({
    required this.totalUsers,
    required this.totalReports,
    required this.activeHazards,
    required this.pendingReports,
    required this.systemHealth,
  });
}

class ModeratorPermissions {
  final bool canBanUsers;
  final bool canDeleteReports;
  final bool canApproveHazards;
  final bool canViewAnalytics;

  const ModeratorPermissions({
    required this.canBanUsers,
    required this.canDeleteReports,
    required this.canApproveHazards,
    required this.canViewAnalytics,
  });
}
