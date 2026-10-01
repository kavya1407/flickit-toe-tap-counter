# YOLO Pose Models & Setup Guide

This directory holds the machine learning weights used by the Flutter application for real-time computer vision inference.

## Primary Model: `yolov8n-pose.tflite`
- **Architecture**: Ultralytics YOLOv8 Nano Pose (Pose Estimation)
- **Input Dimensions**: `1 x 640 x 640 x 3` (Float32 or Uint8, RGB normalized to `[0.0, 1.0]`)
- **Output Tensor**: `1 x 56 x 8400`
  - **4 Box channels**: `[cx, cy, w, h]`
  - **1 Class confidence**: `person_score`
  - **51 Keypoint channels**: 17 anatomical keypoints × 3 (`[x, y, confidence]`)
- **Keypoints Tracked (COCO 17 Keypoints)**:
  1. Nose
  2. Left Eye / 3. Right Eye
  4. Left Ear / 5. Right Ear
  6. Left Shoulder / 7. Right Shoulder
  8. Left Elbow / 9. Right Elbow
  10. Left Wrist / 11. Right Wrist
  12. Left Hip / 13. Right Hip
  14. Left Knee / 15. Right Knee
  16. **Left Ankle** (Lower leg anchor for left foot/toe tap)
  17. **Right Ankle** (Lower leg anchor for right foot/toe tap)

---

## How to Export from Ultralytics Python CLI

If you have custom trained weights or wish to re-export the standard YOLOv8 pose model:

```bash
# 1. Install Ultralytics
pip install ultralytics

# 2. Export to TensorFlow Lite (Float32)
yolo export model=yolov8n-pose.pt format=tflite imgsz=640

# 3. (Optional) Export to INT8 Quantized for 3x speedup on mobile NPU
yolo export model=yolov8n-pose.pt format=tflite int8=True imgsz=640
```

Once exported, place `yolov8n-pose_float32.tflite` (or `yolov8n-pose_int8.tflite`) into this folder as `yolov8n-pose.tflite`.

---

## Companion Ball Detection / Dual Detection Support

The application's `YoloPostprocessor` natively handles:
1. **Unified Dual-Class Models**: If your custom-trained YOLO model includes both `person` (with keypoints) and `sports_ball` bounding boxes.
2. **COCO Class 32 Extractor**: Automatically decodes sports ball candidates if using a multi-class YOLO model.
3. **Adaptive Temporal Tracking & Coasting**: Smooths the ball's center position across frames with Exponential Moving Average (EMA) and maintains position during partial foot occlusion.
4. **Touch-to-Anchor Fallback**: If lighting or ball contrast is poor, tapping the screen instantly anchors the ball coordinate with continuous adaptive tracking.
