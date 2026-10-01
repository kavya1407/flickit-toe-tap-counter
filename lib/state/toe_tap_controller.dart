import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/ball_detection.dart';
import '../models/performance_metrics.dart';
import '../models/pose_detection.dart';
import '../models/tap_event.dart';
import '../services/ball_tracking_service.dart';
import '../services/camera_service.dart';
import '../services/toe_tap_detector.dart';
import '../services/yolo_pose_interpreter.dart';

/// Application state controller coordinating computer vision, camera stream,
/// state machine transitions, and UI metrics.
class ToeTapController extends ChangeNotifier with WidgetsBindingObserver {
  final CameraService cameraService;
  final YoloPoseInterpreter poseInterpreter;
  final BallTrackingService ballTracker;
  final ToeTapDetector tapDetector;

  // Session State
  bool _isRunning = false;
  bool _isInitialized = false;
  bool _isProcessingFrame = false;
  bool _debugOverlay = true;
  bool _hapticsEnabled = true;
  bool _isSimulatedMode = false;
  Timer? _simulationTimer;

  // Real-time Detection Data
  PoseDetection _latestPose = PoseDetection.empty();
  BallDetection _latestBall = BallDetection.empty();
  TapEvent? _latestTapEvent;
  String _statusMessage = 'Initializing camera and YOLO model...';

  // Metrics Tracking
  PerformanceMetrics _metrics = const PerformanceMetrics();
  final List<int> _cameraFrameTimestamps = [];
  final List<int> _inferenceFrameTimestamps = [];
  DateTime _lastMetricsUpdate = DateTime.now();

  ToeTapController({
    CameraService? cameraService,
    YoloPoseInterpreter? poseInterpreter,
    BallTrackingService? ballTracker,
    ToeTapDetector? tapDetector,
  })  : cameraService = cameraService ?? CameraService(),
        poseInterpreter = poseInterpreter ?? YoloPoseInterpreter(),
        ballTracker = ballTracker ?? BallTrackingService(),
        tapDetector = tapDetector ?? ToeTapDetector() {
    WidgetsBinding.instance.addObserver(this);
  }

  // Getters
  bool get isRunning => _isRunning;
  bool get isInitialized => _isInitialized;
  bool get debugOverlay => _debugOverlay;
  bool get hapticsEnabled => _hapticsEnabled;
  bool get isSimulatedMode => _isSimulatedMode;
  int get totalTaps => tapDetector.totalTaps;
  int get leftTaps => tapDetector.leftTaps;
  int get rightTaps => tapDetector.rightTaps;
  TapPhase get leftPhase => tapDetector.leftPhase;
  TapPhase get rightPhase => tapDetector.rightPhase;
  PoseDetection get latestPose => _latestPose;
  BallDetection get latestBall => _latestBall;
  TapEvent? get latestTapEvent => _latestTapEvent;
  String get statusMessage => _statusMessage;
  PerformanceMetrics get metrics => _metrics;

  /// Initializes camera hardware, TFLite model, and prepares stream.
  Future<void> initialize() async {
    _statusMessage = 'Loading Ultralytics YOLO Pose model...';
    notifyListeners();

    await poseInterpreter.initialize();

    _statusMessage = 'Connecting to camera hardware...';
    notifyListeners();

    final cameraReady = await cameraService.initialize();
    if (!cameraReady) {
      _statusMessage = 'No physical camera detected. Switched to Simulation Mode.';
      _isSimulatedMode = true;
    } else {
      _statusMessage = 'Camera active. Tap START to begin counting.';
    }

    _isInitialized = true;
    notifyListeners();
  }

  /// Starts or resumes the toe tap counting session.
  Future<void> startSession(Size previewSize) async {
    if (_isRunning) return;
    _isRunning = true;
    _statusMessage = 'Session running: Track ball & person';
    notifyListeners();

    if (_isSimulatedMode) {
      _startSimulationLoop(previewSize);
    } else {
      await cameraService.startStream((CameraImage image) {
        _onCameraFrameReceived(image, previewSize);
      });
    }
  }

  /// Pauses the current counting session.
  Future<void> pauseSession() async {
    if (!_isRunning) return;
    _isRunning = false;
    _statusMessage = 'Session paused.';
    if (_isSimulatedMode) {
      _simulationTimer?.cancel();
    } else {
      await cameraService.stopStream();
    }
    notifyListeners();
  }

  /// Resets the counter and tracking state.
  void resetSession() {
    tapDetector.reset();
    ballTracker.reset();
    _latestPose = PoseDetection.empty();
    _latestBall = BallDetection.empty();
    _latestTapEvent = null;
    _statusMessage = _isRunning ? 'Session reset. Ready to tap.' : 'Counter reset to 0.';
    notifyListeners();
  }

  /// Handles incoming high-frequency camera frame.
  Future<void> _onCameraFrameReceived(CameraImage image, Size previewSize) async {
    if (!_isRunning || _isProcessingFrame) return;
    _isProcessingFrame = true;

    final int nowMs = DateTime.now().millisecondsSinceEpoch;
    _recordCameraTimestamp(nowMs);

    try {
      final InferenceResult result = await poseInterpreter.processCameraImage(
        cameraImage: image,
        previewSize: previewSize,
      );

      _recordInferenceTimestamp(nowMs);

      _latestPose = result.pose;

      // Update ball tracker with candidate detection or coasting
      _latestBall = ballTracker.update(
        rawDetection: result.rawBall,
        previewSize: previewSize,
      );

      // Evaluate Toe Tap FSM
      final TapEvent? tap = tapDetector.processFrame(
        pose: _latestPose,
        ball: _latestBall,
        timestamp: DateTime.now(),
      );

      if (tap != null) {
        _latestTapEvent = tap;
        _triggerTapFeedback();
        _statusMessage = '${tap.footLabel} TAP #${tap.tapId}!';
      } else {
        _updateDynamicStatus();
      }

      // Update FPS & Latency metrics every 500ms
      _updateTelemetryMetrics(result);
      notifyListeners();
    } catch (e) {
      debugPrint('Frame processing error: $e');
    } finally {
      _isProcessingFrame = false;
    }
  }

  /// Simulation loop for emulators / tests without physical camera.
  void _startSimulationLoop(Size previewSize) {
    _simulationTimer?.cancel();
    _simulationTimer = Timer.periodic(const Duration(milliseconds: 33), (timer) {
      if (!_isRunning) {
        timer.cancel();
        return;
      }
      try {
        final nowMs = DateTime.now().millisecondsSinceEpoch;
        _recordCameraTimestamp(nowMs);
        _recordInferenceTimestamp(nowMs);

        // Run synthetic simulation frame
        final InferenceResult result = poseInterpreter.generateSimulationResult(previewSize);
        _latestPose = result.pose;
        _latestBall = ballTracker.update(
          rawDetection: result.rawBall,
          previewSize: previewSize,
        );

        final TapEvent? tap = tapDetector.processFrame(
          pose: _latestPose,
          ball: _latestBall,
          timestamp: DateTime.now(),
        );

        if (tap != null) {
          _latestTapEvent = tap;
          _triggerTapFeedback();
          _statusMessage = '${tap.footLabel} TAP #${tap.tapId}!';
        } else {
          _updateDynamicStatus();
        }

        _updateTelemetryMetrics(result);
        notifyListeners();
      } catch (e, stack) {
        debugPrint('Simulation loop error: $e\n$stack');
      }
    });
  }

  void _triggerTapFeedback() {
    if (_hapticsEnabled) {
      HapticFeedback.mediumImpact();
    }
    SystemSound.play(SystemSoundType.click);
  }

  void _updateDynamicStatus() {
    if (!_latestPose.personDetected && !_latestBall.isDetected) {
      _statusMessage = 'Searching for person and football...';
    } else if (!_latestPose.personDetected) {
      _statusMessage = 'Ball found. Waiting for player...';
    } else if (!_latestBall.isDetected) {
      _statusMessage = 'Player detected. Searching for football...';
    } else {
      _statusMessage = 'Ready! Tap the top of the ball.';
    }
  }

  void _recordCameraTimestamp(int nowMs) {
    _cameraFrameTimestamps.add(nowMs);
    while (_cameraFrameTimestamps.isNotEmpty &&
        nowMs - _cameraFrameTimestamps.first > 1000) {
      _cameraFrameTimestamps.removeAt(0);
    }
  }

  void _recordInferenceTimestamp(int nowMs) {
    _inferenceFrameTimestamps.add(nowMs);
    while (_inferenceFrameTimestamps.isNotEmpty &&
        nowMs - _inferenceFrameTimestamps.first > 1000) {
      _inferenceFrameTimestamps.removeAt(0);
    }
  }

  void _updateTelemetryMetrics(InferenceResult result) {
    final now = DateTime.now();
    if (now.difference(_lastMetricsUpdate).inMilliseconds >= 400) {
      _lastMetricsUpdate = now;
      _metrics = PerformanceMetrics(
        cameraFps: _cameraFrameTimestamps.length.toDouble(),
        inferenceFps: _inferenceFrameTimestamps.length.toDouble(),
        inferenceLatencyMs: result.inferenceTimeMs,
        preprocessLatencyMs: result.preprocessTimeMs,
        postprocessLatencyMs: result.postprocessTimeMs,
      );
    }
  }

  /// Flips camera (front / back).
  Future<void> toggleCamera(Size previewSize) async {
    final wasRunning = _isRunning;
    if (wasRunning) await pauseSession();

    await cameraService.toggleCamera(null);

    if (wasRunning) await startSession(previewSize);
    notifyListeners();
  }

  /// Toggles debug bounding boxes, skeleton, and contact ring overlays.
  void toggleDebugOverlay() {
    _debugOverlay = !_debugOverlay;
    notifyListeners();
  }

  /// Toggles simulation mode manually.
  void toggleSimulationMode(Size previewSize) {
    _isSimulatedMode = !_isSimulatedMode;
    if (_isRunning) {
      pauseSession().then((_) => startSession(previewSize));
    }
    notifyListeners();
  }

  /// Manually anchors ball on user tap.
  void manualAnchorBall(Offset position, double radius) {
    ballTracker.anchorBall(position, radius);
    _latestBall = ballTracker.currentBall;
    _statusMessage = 'Ball position manually anchored!';
    notifyListeners();
  }

  // App Lifecycle Handling (Bonus Requirement)
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      // Pause camera stream & save power
      if (_isRunning) pauseSession();
    } else if (state == AppLifecycleState.resumed) {
      debugPrint('App resumed: Camera ready.');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _simulationTimer?.cancel();
    cameraService.dispose();
    poseInterpreter.dispose();
    super.dispose();
  }
}
