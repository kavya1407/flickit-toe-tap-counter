import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Manages camera lifecycle, switching, permissions, and high-frequency frame streaming.
class CameraService {
  List<CameraDescription> _availableCameras = [];
  CameraController? _controller;
  int _selectedCameraIndex = 0;
  bool _isStreaming = false;

  CameraController? get controller => _controller;
  bool get isInitialized => _controller != null && _controller!.value.isInitialized;
  bool get isStreaming => _isStreaming;
  List<CameraDescription> get cameras => _availableCameras;
  int get selectedCameraIndex => _selectedCameraIndex;

  /// Discovers device cameras and initializes the default (back-facing) camera.
  Future<bool> initialize() async {
    try {
      _availableCameras = await availableCameras();
      if (_availableCameras.isEmpty) {
        debugPrint('No cameras detected on this device.');
        return false;
      }

      // Default to back camera for sports tracking
      _selectedCameraIndex = _availableCameras.indexWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
      );
      if (_selectedCameraIndex == -1) _selectedCameraIndex = 0;

      return await _initController(_availableCameras[_selectedCameraIndex]);
    } catch (e) {
      debugPrint('CameraService initialization error: $e');
      return false;
    }
  }

  /// Internal initializer for a specific camera descriptor.
  Future<bool> _initController(CameraDescription camera) async {
    await _controller?.dispose();

    _controller = CameraController(
      camera,
      ResolutionPreset.medium, // 720p optimal balance of latency & resolution
      enableAudio: false,
      imageFormatGroup: defaultTargetPlatform == TargetPlatform.android
          ? ImageFormatGroup.yuv420
          : ImageFormatGroup.bgra8888,
    );

    try {
      await _controller!.initialize();
      return true;
    } catch (e) {
      debugPrint('Failed to initialize CameraController: $e');
      return false;
    }
  }

  /// Starts streaming camera frames for computer vision inference.
  Future<void> startStream(Function(CameraImage image) onFrame) async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (_isStreaming) return;

    try {
      await _controller!.startImageStream((CameraImage image) {
        onFrame(image);
      });
      _isStreaming = true;
    } catch (e) {
      debugPrint('Failed to start camera image stream: $e');
    }
  }

  /// Pauses/stops the frame stream.
  Future<void> stopStream() async {
    if (_controller == null || !_isStreaming) return;
    try {
      await _controller!.stopImageStream();
    } catch (e) {
      debugPrint('Error stopping camera stream: $e');
    } finally {
      _isStreaming = false;
    }
  }

  /// Switches between front and back cameras.
  Future<bool> toggleCamera(Function(CameraImage image)? onFrame) async {
    if (_availableCameras.length < 2) return false;

    await stopStream();
    _selectedCameraIndex = (_selectedCameraIndex + 1) % _availableCameras.length;
    final success = await _initController(_availableCameras[_selectedCameraIndex]);

    if (success && onFrame != null) {
      await startStream(onFrame);
    }
    return success;
  }

  /// Disposes camera controller and releases hardware resources.
  Future<void> dispose() async {
    await stopStream();
    await _controller?.dispose();
    _controller = null;
    _isStreaming = false;
  }
}
