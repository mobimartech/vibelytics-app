import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'app_logger.dart';

/// Service to monitor network connectivity
class ConnectivityService {
  ConnectivityService._() {
    _init();
  }
  static final ConnectivityService instance = ConnectivityService._();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  final _connectivityController = StreamController<bool>.broadcast();
  Stream<bool> get onConnectivityChanged => _connectivityController.stream;

  bool _isConnected = false;
  bool get isConnected => _isConnected;

  void _init() {
    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      final hasConnection = results.any((result) =>
          result == ConnectivityResult.wifi ||
          result == ConnectivityResult.mobile ||
          result == ConnectivityResult.ethernet);

      if (_isConnected != hasConnection) {
        _isConnected = hasConnection;
        _connectivityController.add(_isConnected);
        AppLogger.i('Connectivity changed: ${_isConnected ? "online" : "offline"}');
      }
    });
  }

  /// Await the first connectivity check and emit the initial state.
  /// Call this once at app startup before listeners rely on the value.
  Future<void> initialize() async {
    final connected = await checkConnectivity();
    _connectivityController.add(connected);
  }

  /// Check current connectivity status
  Future<bool> checkConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _isConnected = results.any((result) =>
          result == ConnectivityResult.wifi ||
          result == ConnectivityResult.mobile ||
          result == ConnectivityResult.ethernet);
      return _isConnected;
    } catch (e) {
      AppLogger.e('Error checking connectivity', error: e);
      return false;
    }
  }

  void dispose() {
    _subscription?.cancel();
    _connectivityController.close();
  }
}
