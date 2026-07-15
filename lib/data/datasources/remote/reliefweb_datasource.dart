import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_performance/firebase_performance.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../../../core/services/logger_service.dart';

class ReliefWebDataSource {
  bool lastRequestUsedServerCache = true;

  Future<List<Map<String, dynamic>>> fetchReports() async {
    final trace = FirebasePerformance.instance.newTrace('fetch_reliefweb_reports');
    await trace.start();
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('getReliefWebReports');
      final result = await callable.call();
      lastRequestUsedServerCache = true;
      final listData = result.data as List;
      final List<Map<String, dynamic>> data = listData.map((e) => _castMap(e as Map)).toList();
      await trace.stop();
      return data;
    } catch (_) {
      lastRequestUsedServerCache = false;
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
        LoggerService.logError(e, stack, context: 'fetchReliefWebReportsFallback');
        rethrow;
      }
    }
  }

  Map<String, dynamic> _castMap(Map<dynamic, dynamic> map) {
    return map.map((key, value) {
      final String stringKey = key.toString();
      if (value is Map) {
        return MapEntry(stringKey, _castMap(value));
      } else if (value is List) {
        return MapEntry(stringKey, value.map((item) {
          if (item is Map) {
            return _castMap(item);
          }
          return item;
        }).toList());
      }
      return MapEntry(stringKey, value);
    });
  }
}
