import 'dart:convert';
import 'package:edge_shake_anomaly_app/secrets.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class AnomalyApiService {
  final String backendUrl;
  final String _endpoint = '';

  AnomalyApiService({required this.backendUrl});

  Future<String> _getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    String? deviceId = prefs.getString('device_id');
    if (deviceId == null) {
      deviceId = const Uuid().v4();
      await prefs.setString('device_id', deviceId);
    }
    return deviceId;
  }

  Future<Map<String, dynamic>> sendShakeEvent(double magnitude) async {
    final cleanBaseUrl = backendUrl.endsWith('/')
        ? backendUrl.substring(0, backendUrl.length - 1)
        : backendUrl;
    final uri = Uri.parse('$cleanBaseUrl$_endpoint');

    String severity = 'low';
    if (magnitude > 20) severity = 'medium';
    if (magnitude > 30) severity = 'high';

    final deviceId = await _getDeviceId();

    final payload = {
      'deviceId': deviceId,
      'email': 'staging@yopmail.com',
      'log': {
        'timestamp': DateTime.now().toUtc().toIso8601String(),
        'anomalyType': 'SHAKE_ANOMALY',
        'source': 'mobile_edge_app',
        'severity': severity,
        'magnitude': magnitude,
      },
    };

    print('API Call to: $uri');
    print('Headers: ${{'x-api-key': apiKey}}');
    print('Payload: ${jsonEncode(payload)}');
    try {
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json', 'x-api-key': apiKey},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 10));

      return {
        'success': response.statusCode >= 200 && response.statusCode < 300,
        'statusCode': response.statusCode,
        'body': response.body,
        'timestamp': DateTime.now().toString(),
      };
    } catch (e) {
      return {
        'success': false,
        'statusCode': 0,
        'body': e.toString(),
        'timestamp': DateTime.now().toString(),
      };
    }
  }
}
