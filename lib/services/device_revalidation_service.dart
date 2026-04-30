import 'dart:convert';
import 'package:http/http.dart' as http;
import '../Env.dart';
import 'auth.dart';
import 'device_service.dart';

class DeviceRevalidationService {
  static final DeviceRevalidationService _instance =
      DeviceRevalidationService._internal();
  factory DeviceRevalidationService() => _instance;
  DeviceRevalidationService._internal();

  final String _baseUrl = 'https://${Env.DRUPAL_URL}';

  /// Call this whenever the app comes back to the foreground or regains
  /// connectivity. Returns `true` when the device is still valid.
  Future<bool> revalidate() async {
    final deviceId = DeviceService().deviceId;
    if (deviceId == null || deviceId.isEmpty) {
      return true;
    }

    final token = await getToken();
    if (token == null || token.isEmpty) {
      return true;
    }

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/device/revalidate'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'device_id': deviceId}),
      );

      if (response.statusCode == 200) {
        return true;
      }

      if (response.statusCode == 403 || response.statusCode == 404) {
        // Device has been revoked – force logout.
        await _handleRevocation();
        return false;
      }
    } catch (_) {
      // Network unavailable – allow offline usage.
    }
    return true;
  }

  Future<void> _handleRevocation() async {
    await storage.delete(key: 'access_token');
    await storage.delete(key: 'refresh_token');
    await storage.delete(key: 'expires_in');
    navigatorKey.currentState
        ?.pushNamedAndRemoveUntil('/', (_) => false, arguments: {
      'forceLogin': true,
      'deviceRevoked': true,
    });
  }
}
