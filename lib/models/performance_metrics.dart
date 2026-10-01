/// Telemetry and profiling metrics for real-time edge processing.
class PerformanceMetrics {
  final double cameraFps;
  final double inferenceFps;
  final int inferenceLatencyMs;
  final int preprocessLatencyMs;
  final int postprocessLatencyMs;

  const PerformanceMetrics({
    this.cameraFps = 0.0,
    this.inferenceFps = 0.0,
    this.inferenceLatencyMs = 0,
    this.preprocessLatencyMs = 0,
    this.postprocessLatencyMs = 0,
  });

  int get totalPipelineLatencyMs =>
      preprocessLatencyMs + inferenceLatencyMs + postprocessLatencyMs;

  PerformanceMetrics copyWith({
    double? cameraFps,
    double? inferenceFps,
    int? inferenceLatencyMs,
    int? preprocessLatencyMs,
    int? postprocessLatencyMs,
  }) {
    return PerformanceMetrics(
      cameraFps: cameraFps ?? this.cameraFps,
      inferenceFps: inferenceFps ?? this.inferenceFps,
      inferenceLatencyMs: inferenceLatencyMs ?? this.inferenceLatencyMs,
      preprocessLatencyMs: preprocessLatencyMs ?? this.preprocessLatencyMs,
      postprocessLatencyMs: postprocessLatencyMs ?? this.postprocessLatencyMs,
    );
  }
}
