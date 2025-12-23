import 'package:flutter/material.dart';

import 'services/shake_detector.dart';
import 'services/anomaly_api.dart';

void main() {
  runApp(const EdgeShakeApp());
}

class EdgeShakeApp extends StatelessWidget {
  const EdgeShakeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Edge Shake Anomaly',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.grey[100],
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  late ShakeDetector _shakeDetector;
  final AnomalyApiService _apiService = AnomalyApiService(
    // Placeholder - requires user configuration
    backendUrl:
        'https://qbhq7dmug5.execute-api.us-east-1.amazonaws.com/staging',
  );

  bool _isDetectionEnabled = false;
  double _currentThreshold = 15.0;
  String _lastStatus = 'Ready';
  String _lastTimestamp = '-';
  bool _isBusy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _shakeDetector = ShakeDetector(threshold: _currentThreshold);
    _shakeDetector.shakeStream.listen(_onShakeDetected);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _shakeDetector.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Stop listening if app goes to background
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      if (_shakeDetector.isListening) {
        _shakeDetector.stopListening();
        setState(() {}); // Update UI to show paused state if needed
      }
    } else if (state == AppLifecycleState.resumed) {
      // Resume listening if it was enabled
      if (_isDetectionEnabled && !_shakeDetector.isListening) {
        _shakeDetector.startListening();
        setState(() {});
      }
    }
  }

  void _onShakeDetected(double magnitude) {
    _sendAnomaly(magnitude);
  }

  Future<void> _sendAnomaly(double magnitude) async {
    if (_isBusy) return; // Prevent overlapping API calls if one is stuck

    setState(() {
      _isBusy = true;
      _lastStatus = 'Sending anomaly... (Mag: ${magnitude.toStringAsFixed(1)})';
    });

    final result = await _apiService.sendShakeEvent(magnitude);

    if (!mounted) return;

    setState(() {
      _isBusy = false;
      if (result['success']) {
        _lastStatus = 'Success: ${result['statusCode']}';
      } else {
        _lastStatus = 'Failed: ${result['statusCode']}';
      }
      _lastTimestamp = result['timestamp'] ?? DateTime.now().toString();
    });
  }

  void _toggleDetection(bool value) {
    setState(() {
      _isDetectionEnabled = value;
      if (_isDetectionEnabled) {
        // Re-initialize with current threshold just in case
        _shakeDetector.stopListening();
        // Note: Creating a new instance cleanly updates threshold if we wanted to
        // strictly enforce immutable props, but for now we just restart.
        // Actually ShakeDetector threshold is final, so we SHOULD recreate or make it mutable.
        // Let's recreate to be safe and clean.
        _shakeDetector.dispose();
        _shakeDetector = ShakeDetector(threshold: _currentThreshold);
        _shakeDetector.shakeStream.listen(_onShakeDetected);

        _shakeDetector.startListening();
      } else {
        _shakeDetector.stopListening();
      }
    });
  }

  void _updateSensitivity(double value) {
    setState(() {
      _currentThreshold = value;
      // If active, restart to apply new threshold
      if (_isDetectionEnabled) {
        _toggleDetection(true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isListening = _shakeDetector.isListening;
    final statusColor = isListening ? Colors.green : Colors.orange;
    final statusText = isListening ? 'LISTENING' : 'PAUSED';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edge Shake Anomaly'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Card
            Card(
              elevation: 0,
              color: statusColor.withValues(alpha: 0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: statusColor.withValues(alpha: 0.3)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  children: [
                    Icon(
                      isListening ? Icons.sensors : Icons.sensors_off,
                      size: 48,
                      color: statusColor,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Move device to trigger',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Controls
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Detection',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                Switch(value: _isDetectionEnabled, onChanged: _toggleDetection),
              ],
            ),

            const SizedBox(height: 24),

            Text(
              'Sensitivity Threshold: ${_currentThreshold.toStringAsFixed(1)}',
              style: TextStyle(fontSize: 16, color: Colors.grey[800]),
            ),
            Slider(
              value: _currentThreshold,
              min: 5.0,
              max: 30.0,
              divisions: 25,
              label: _currentThreshold.toStringAsFixed(1),
              onChanged: _updateSensitivity,
            ),

            const Spacer(),

            // Log Area
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Last Event',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                      Text(
                        _lastTimestamp,
                        style: TextStyle(color: Colors.grey[400], fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _lastStatus,
                    style: TextStyle(
                      fontFamily: 'Courier',
                      fontWeight: FontWeight.bold,
                      color: _lastStatus.startsWith('Success')
                          ? Colors.green[700]
                          : Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            ElevatedButton.icon(
              onPressed: _isBusy
                  ? null
                  : () => _sendAnomaly(99.9), // Test trigger
              icon: const Icon(Icons.cloud_upload_outlined),
              label: const Text('TEST API CALL'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.black87,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
