import '../../domain/repositories/i_reliefweb_repository.dart';
import '../../domain/models/domain_models.dart';
import '../datasources/remote/reliefweb_datasource.dart';

class ReliefWebRepository implements IReliefWebRepository {
  final ReliefWebDataSource _reliefWebDataSource;

  ReliefWebRepository(this._reliefWebDataSource);

  @override
  Future<List<ReliefWebReportModel>> getRecentReports() async {
    final data = await _reliefWebDataSource.fetchReports();
    final List<ReliefWebReportModel> list = [];

    for (final item in data) {
      final id = item['id']?.toString() ?? '';
      final fields = item['fields'] as Map<String, dynamic>? ?? {};

      final String title = fields['title'] as String? ?? 'Disaster Report';
      final String url = fields['url'] as String? ?? '';

      final sources = fields['source'] as List<dynamic>? ?? [];
      final String source = (sources.isNotEmpty)
          ? (sources.first as Map<String, dynamic>)['name'] as String? ??
                'ReliefWeb'
          : 'ReliefWeb';

      final dateMap = fields['date'] as Map<String, dynamic>? ?? {};
      final String dateStr = dateMap['created'] as String? ?? '';
      final DateTime date = DateTime.tryParse(dateStr) ?? DateTime.now();

      list.add(
        ReliefWebReportModel(
          id: id,
          title: title,
          source: source,
          date: date,
          url: url,
        ),
      );
    }
    return list;
  }
}
