import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Helper class untuk handle connectivity dengan API compatibility
///
/// Kenapa dibutuhkan:
/// - connectivity_plus v5.0.2 returns single ConnectivityResult
/// - Newer versions return List of ConnectivityResult
/// - Helper ini provide consistent interface
class ConnectivityHelper {
  final Connectivity _connectivity;

  ConnectivityHelper({Connectivity? connectivity})
    : _connectivity = connectivity ?? Connectivity();

  /// Check if device is currently online
  Future<bool> isOnline() async {
    try {
      final result = await _connectivity.checkConnectivity();
      return _isConnected(result);
    } catch (e) {
      // Assume offline if error
      return false;
    }
  }

  /// Stream connectivity changes
  Stream<bool> get onConnectivityChanged {
    return _connectivity.onConnectivityChanged.map((result) {
      return _isConnected(result);
    });
  }

  /// Check if connectivity result indicates connection
  bool _isConnected(ConnectivityResult result) {
    return result == ConnectivityResult.mobile ||
        result == ConnectivityResult.wifi ||
        result == ConnectivityResult.ethernet ||
        result == ConnectivityResult.vpn;
  }

  /// Get current connectivity type
  Future<ConnectivityResult> getCurrentConnectivity() async {
    return await _connectivity.checkConnectivity();
  }

  /// Get readable connectivity status
  Future<String> getConnectivityStatus() async {
    final result = await getCurrentConnectivity();
    switch (result) {
      case ConnectivityResult.wifi:
        return 'WiFi';
      case ConnectivityResult.mobile:
        return 'Mobile Data';
      case ConnectivityResult.ethernet:
        return 'Ethernet';
      case ConnectivityResult.vpn:
        return 'VPN';
      case ConnectivityResult.none:
        return 'Offline';
      default:
        return 'Unknown';
    }
  }
}
