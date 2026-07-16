import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

/// ═══════════════════════════════════════════════════════════════════
/// CONNECTIVITY CHECKER
/// ═══════════════════════════════════════════════════════════════════
/// Utility class to monitor network connectivity status.
/// Uses the connectivity_plus plugin to detect WiFi, mobile data,
/// or no connection at all.
/// ═══════════════════════════════════════════════════════════════════

class ConnectivityChecker {
  // Singleton instance
  static final ConnectivityChecker _instance = ConnectivityChecker._internal();
  factory ConnectivityChecker() => _instance;
  ConnectivityChecker._internal();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  /// Current connectivity state
  bool _isOnline = true;
  bool get isOnline => _isOnline;

  /// Stream controller for broadcasting connectivity changes
  final StreamController<bool> _controller = StreamController<bool>.broadcast();
  Stream<bool> get onConnectivityChanged => _controller.stream;

  /// Initialize and start listening to connectivity changes
  void initialize() {
    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      // In connectivity_plus v5+, onConnectivityChanged returns List<ConnectivityResult>
      final hasConnection = results.any(
        (r) => r == ConnectivityResult.wifi || r == ConnectivityResult.mobile,
      );
      _isOnline = hasConnection;
      _controller.add(hasConnection);
    });
  }

  /// Check current connectivity status (one-shot)
  Future<bool> checkNow() async {
    final results = await _connectivity.checkConnectivity();
    _isOnline = results.any(
      (r) => r == ConnectivityResult.wifi || r == ConnectivityResult.mobile,
    );
    return _isOnline;
  }

  /// Dispose resources
  void dispose() {
    _subscription?.cancel();
    _controller.close();
  }
}
