import 'dart:async';
import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';

class ShakeDetector {
  final double threshold;
  final Duration cooldown;

  DateTime? _lastShakeTime;
  StreamSubscription<AccelerometerEvent>? _subscription;
  final _shakeController = StreamController<double>.broadcast();

  Stream<double> get shakeStream => _shakeController.stream;

  bool get isListening => _subscription != null;

  ShakeDetector({
    this.threshold = 15.0,
    this.cooldown = const Duration(milliseconds: 1500),
  });

  void startListening() {
    if (_subscription != null) return;

    _subscription = accelerometerEventStream().listen((event) {
      double magnitude = sqrt(
        pow(event.x, 2) + pow(event.y, 2) + pow(event.z, 2),
      );

      if (magnitude > threshold) {
        final now = DateTime.now();
        if (_lastShakeTime == null ||
            now.difference(_lastShakeTime!) > cooldown) {
          _lastShakeTime = now;
          _shakeController.add(magnitude);
        }
      }
    });
  }

  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
  }

  void dispose() {
    stopListening();
    _shakeController.close();
  }
}
