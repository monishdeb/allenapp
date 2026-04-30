import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:uuid/uuid.dart';

const _deviceStorage = FlutterSecureStorage();
const _deviceIdKey = 'device_id';
const _deviceTypeKey = 'device_type';
const _deviceNameKey = 'device_name';
const _deviceThresholdKey = 'device_threshold';

class DeviceService {
  static final DeviceService _instance = DeviceService._internal();
  factory DeviceService() => _instance;
  DeviceService._internal();

  String? _deviceId;
  String? _deviceType;
  String? _deviceName;
  int? _deviceThreshold;

  /// Initialises the device service, generating a device UUID on first launch.
  Future<void> init() async {
    _deviceId = await _deviceStorage.read(key: _deviceIdKey);
    if (_deviceId == null || _deviceId!.isEmpty) {
      _deviceId = const Uuid().v4();
      await _deviceStorage.write(key: _deviceIdKey, value: _deviceId);
    }
    await _loadDeviceInfo();
    _deviceThreshold = int.tryParse(
        await _deviceStorage.read(key: _deviceThresholdKey) ?? '3') ?? 3;
  }

  /// Returns the persistent device UUID for this installation.
  String? get deviceId => _deviceId;

  /// Returns the device type string (e.g. 'android', 'ios', 'web').
  String? get deviceType => _deviceType;

  /// Returns a human-readable device name.
  String? get deviceName => _deviceName;

  /// Returns the device threshold received from Drupal.
  int get deviceThreshold => _deviceThreshold ?? 3;

  /// Persists the device threshold received from Drupal.
  Future<void> setDeviceThreshold(int threshold) async {
    _deviceThreshold = threshold;
    await _deviceStorage.write(
        key: _deviceThresholdKey, value: threshold.toString());
  }

  /// Loads device type and name from the host platform.
  Future<void> _loadDeviceInfo() async {
    final cached = await _deviceStorage.read(key: _deviceTypeKey);
    if (cached != null && cached.isNotEmpty) {
      _deviceType = cached;
      _deviceName = await _deviceStorage.read(key: _deviceNameKey);
      return;
    }

    if (kIsWeb) {
      _deviceType = 'web';
      _deviceName = 'Web Browser';
    } else {
      final deviceInfoPlugin = DeviceInfoPlugin();
      try {
        if (Platform.isAndroid) {
          final info = await deviceInfoPlugin.androidInfo;
          _deviceType = 'android';
          _deviceName = '${info.manufacturer} ${info.model}';
        } else if (Platform.isIOS) {
          final info = await deviceInfoPlugin.iosInfo;
          _deviceType = 'ios';
          _deviceName = info.name;
        } else if (Platform.isLinux) {
          final info = await deviceInfoPlugin.linuxInfo;
          _deviceType = 'linux';
          _deviceName = info.prettyName;
        } else if (Platform.isMacOS) {
          final info = await deviceInfoPlugin.macOsInfo;
          _deviceType = 'macos';
          _deviceName = info.computerName;
        } else if (Platform.isWindows) {
          final info = await deviceInfoPlugin.windowsInfo;
          _deviceType = 'windows';
          _deviceName = info.computerName;
        } else {
          _deviceType = 'unknown';
          _deviceName = 'Unknown Device';
        }
      } catch (_) {
        _deviceType = 'unknown';
        _deviceName = 'Unknown Device';
      }
    }

    await _deviceStorage.write(key: _deviceTypeKey, value: _deviceType);
    await _deviceStorage.write(key: _deviceNameKey, value: _deviceName);
  }

  /// Clears all cached device info from secure storage (called on logout).
  Future<void> clearDeviceInfo() async {
    await _deviceStorage.delete(key: _deviceThresholdKey);
  }
}
