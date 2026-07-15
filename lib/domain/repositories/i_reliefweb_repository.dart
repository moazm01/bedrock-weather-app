import '../models/domain_models.dart';

abstract class IReliefWebRepository {
  Future<List<ReliefWebReportModel>> getRecentReports();
  bool get isUsingServerCache;
}
