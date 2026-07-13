import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_performance/firebase_performance.dart';
import '../../../core/services/logger_service.dart';

class ReliefWebDataSource {
  Future<List<Map<String, dynamic>>> fetchReports() async {
    final trace = FirebasePerformance.instance.newTrace('fetch_reliefweb_reports');
    await trace.start();
    try {
      final uri = Uri.parse('https://api.reliefweb.int/v1/reports?appname=bedrock&filter[field]=country.iso3&filter[value]=PAK&limit=20&sort[]=date:desc');
      final response = await http.get(uri, headers: {'Accept': 'application/json'});
      if (response.statusCode != 200) throw Exception('ReliefWeb ${response.statusCode}');
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final data = (body['data'] as List? ?? []).cast<Map<String, dynamic>>();
      await trace.stop();
      return data;
    } catch (e, stack) {
      await trace.stop();
      LoggerService.logError(e, stack, context: 'fetchReliefWebReports');
      rethrow;
    }
  }
}
