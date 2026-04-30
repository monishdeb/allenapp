import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../Env.dart';
import '../services/auth.dart';
import '../services/device_service.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/left_drawer.dart';

class DeviceManagementScreen extends StatefulWidget {
  final bool isEnglishUS;
  final String locale;
  final bool isOffline;

  const DeviceManagementScreen({
    super.key,
    required this.isEnglishUS,
    required this.locale,
    required this.isOffline,
  });

  @override
  State<DeviceManagementScreen> createState() => _DeviceManagementScreenState();
}

class _DeviceManagementScreenState extends State<DeviceManagementScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final String _baseUrl = 'https://${Env.DRUPAL_URL}';

  bool _isLoading = true;
  List<Map<String, dynamic>> _devices = [];
  String? _currentDeviceId;
  int _threshold = 3;
  String? _errorMessage;
  late bool _isAppOffline;
  late String _currentLocale;

  @override
  void initState() {
    super.initState();
    _isAppOffline = widget.isOffline;
    _currentLocale = widget.locale;
    _currentDeviceId = DeviceService().deviceId;
    _threshold = DeviceService().deviceThreshold;
    _loadDevices();
  }

  void _onChangeOffline(bool? isOffline) async {
    await setOfflineStatus(isOffline ?? false, false);
    await setOfflineDate(DateTime.now().millisecondsSinceEpoch);
    setState(() {
      _isAppOffline = isOffline ?? false;
    });
  }

  void _onLocaleChange(String newLocale) {
    setState(() {
      _currentLocale = newLocale;
    });
  }

  Future<void> _loadDevices() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = await getToken();
      if (token == null || token.isEmpty) {
        setState(() {
          _errorMessage = 'Not authenticated.';
          _isLoading = false;
        });
        return;
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/api/device/list'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
        setState(() {
          _devices = data.cast<Map<String, dynamic>>();
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load devices (${response.statusCode}).';
          _isLoading = false;
        });
      }
    } catch (_) {
      setState(() {
        _errorMessage = 'Could not reach the server. Check your connection.';
        _isLoading = false;
      });
    }
  }

  Future<void> _revokeDevice(String deviceId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Revoke device'),
        content: const Text('Are you sure you want to revoke this device?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Revoke'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final token = await getToken();
      if (token == null || token.isEmpty) return;

      final response = await http.delete(
        Uri.parse('$_baseUrl/api/device/$deviceId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Device revoked successfully.')),
        );
        await _loadDevices();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Failed to revoke device (${response.statusCode}).')),
        );
      }
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Network error. Please try again.')),
      );
    }
  }

  String _formatLastSeen(dynamic lastSeen) {
    if (lastSeen == null) return 'Never';
    try {
      final dt = DateTime.fromMillisecondsSinceEpoch(
          int.parse(lastSeen.toString()) * 1000);
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return lastSeen.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: CustomAppBar(
        scaffoldKey: _scaffoldKey,
        locale: _currentLocale,
        isEnglishUS: _currentLocale == 'EN',
        isOffline: _isAppOffline,
      ),
      drawer: LeftNavDrawer(
        locale: _currentLocale,
        isEnglishUS: _currentLocale == 'EN',
        isOffline: _isAppOffline,
      ),
      endDrawer: SettingsDrawer(
        locale: _currentLocale,
        isEnglishUS: _currentLocale == 'EN',
        isOffline: _isAppOffline,
        onOfflineChange: _onChangeOffline,
        onLocaleChange: _onLocaleChange,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Device Management',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Active devices: ${_devices.length} / $_threshold',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _buildBody(),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadDevices,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_devices.isEmpty) {
      return const Center(child: Text('No active devices found.'));
    }

    return RefreshIndicator(
      onRefresh: _loadDevices,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _devices.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final device = _devices[index];
          final deviceId = device['device_id']?.toString() ?? '';
          final isCurrentDevice = deviceId == _currentDeviceId;

          return ListTile(
            leading: Icon(
              _deviceIcon(device['device_type']?.toString()),
              size: 36,
              color: isCurrentDevice
                  ? const Color.fromRGBO(213, 31, 39, 1)
                  : Colors.grey,
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    device['device_type']?.toString().toUpperCase() ?? 'UNKNOWN',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                if (isCurrentDevice)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color.fromRGBO(213, 31, 39, 1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'This device',
                      style: TextStyle(color: Colors.white, fontSize: 11),
                    ),
                  ),
              ],
            ),
            subtitle: Text(
                'Last seen: ${_formatLastSeen(device['last_seen'])}'),
            trailing: isCurrentDevice
                ? null
                : IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    tooltip: 'Revoke device',
                    onPressed: () => _revokeDevice(deviceId),
                  ),
          );
        },
      ),
    );
  }

  IconData _deviceIcon(String? deviceType) {
    switch (deviceType?.toLowerCase()) {
      case 'android':
        return Icons.phone_android;
      case 'ios':
        return Icons.phone_iphone;
      case 'web':
        return Icons.web;
      case 'windows':
      case 'macos':
      case 'linux':
        return Icons.computer;
      default:
        return Icons.devices;
    }
  }
}

class DeviceManagementScreen extends StatefulWidget {
  final bool isEnglishUS;
  final String locale;
  final bool isOffline;

  const DeviceManagementScreen({
    super.key,
    required this.isEnglishUS,
    required this.locale,
    required this.isOffline,
  });

  @override
  State<DeviceManagementScreen> createState() => _DeviceManagementScreenState();
}

class _DeviceManagementScreenState extends State<DeviceManagementScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final String _baseUrl = 'https://${Env.DRUPAL_URL}';

  bool _isLoading = true;
  List<Map<String, dynamic>> _devices = [];
  String? _currentDeviceId;
  int _threshold = 3;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _currentDeviceId = DeviceService().deviceId;
    _threshold = DeviceService().deviceThreshold;
    _loadDevices();
  }

  Future<void> _loadDevices() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = await getToken();
      if (token == null || token.isEmpty) {
        setState(() {
          _errorMessage = 'Not authenticated.';
          _isLoading = false;
        });
        return;
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/api/device/list'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
        setState(() {
          _devices = data.cast<Map<String, dynamic>>();
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load devices (${response.statusCode}).';
          _isLoading = false;
        });
      }
    } catch (_) {
      setState(() {
        _errorMessage = 'Could not reach the server. Check your connection.';
        _isLoading = false;
      });
    }
  }

  Future<void> _revokeDevice(String deviceId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Revoke device'),
        content: const Text('Are you sure you want to revoke this device?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Revoke'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final token = await getToken();
      if (token == null || token.isEmpty) return;

      final response = await http.delete(
        Uri.parse('$_baseUrl/api/device/$deviceId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Device revoked successfully.')),
        );
        await _loadDevices();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Failed to revoke device (${response.statusCode}).')),
        );
      }
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Network error. Please try again.')),
      );
    }
  }

  String _formatLastSeen(dynamic lastSeen) {
    if (lastSeen == null) return 'Never';
    try {
      final dt = DateTime.fromMillisecondsSinceEpoch(
          int.parse(lastSeen.toString()) * 1000);
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return lastSeen.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: CustomAppBar(
        scaffoldKey: _scaffoldKey,
        locale: widget.locale,
        isEnglishUS: widget.isEnglishUS,
        isOffline: widget.isOffline,
      ),
      drawer: LeftNavDrawer(
        locale: widget.locale,
        isEnglishUS: widget.isEnglishUS,
        isOffline: widget.isOffline,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Device Management',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Active devices: ${_devices.length} / $_threshold',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _buildBody(),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadDevices,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_devices.isEmpty) {
      return const Center(child: Text('No active devices found.'));
    }

    return RefreshIndicator(
      onRefresh: _loadDevices,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _devices.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final device = _devices[index];
          final deviceId = device['device_id']?.toString() ?? '';
          final isCurrentDevice = deviceId == _currentDeviceId;

          return ListTile(
            leading: Icon(
              _deviceIcon(device['device_type']?.toString()),
              size: 36,
              color: isCurrentDevice
                  ? const Color.fromRGBO(213, 31, 39, 1)
                  : Colors.grey,
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    device['device_type']?.toString().toUpperCase() ?? 'UNKNOWN',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                if (isCurrentDevice)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color.fromRGBO(213, 31, 39, 1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'This device',
                      style: TextStyle(color: Colors.white, fontSize: 11),
                    ),
                  ),
              ],
            ),
            subtitle: Text(
                'Last seen: ${_formatLastSeen(device['last_seen'])}'),
            trailing: isCurrentDevice
                ? null
                : IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    tooltip: 'Revoke device',
                    onPressed: () => _revokeDevice(deviceId),
                  ),
          );
        },
      ),
    );
  }

  IconData _deviceIcon(String? deviceType) {
    switch (deviceType?.toLowerCase()) {
      case 'android':
        return Icons.phone_android;
      case 'ios':
        return Icons.phone_iphone;
      case 'web':
        return Icons.web;
      case 'windows':
      case 'macos':
      case 'linux':
        return Icons.computer;
      default:
        return Icons.devices;
    }
  }
}
