import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toe_tap_counter/core/utils/math_utils.dart';

void main() {
  group('MathUtils Tests', () {
    test('euclideanDistance calculates correct distance', () {
      const p1 = Offset(0, 0);
      const p2 = Offset(3, 4);
      expect(MathUtils.euclideanDistance(p1, p2), equals(5.0));
    });

    test('estimateToePosition projects downward/forward from knee-ankle vector', () {
      const knee = Offset(100, 200);
      const ankle = Offset(100, 300); // Shank length = 100

      final toe = MathUtils.estimateToePosition(
        knee: knee,
        ankle: ankle,
        footLengthRatio: 0.20, // 20 units
      );

      // Toe should be at or below ankle (dy > 300)
      expect(toe.dy, greaterThan(ankle.dy));
      expect(toe.dx, closeTo(ankle.dx, 1.0));
    });

    test('calculateIoU returns 1.0 for identical rects and 0.0 for disjoint rects', () {
      const r1 = Rect.fromLTWH(0, 0, 100, 100);
      const r2 = Rect.fromLTWH(0, 0, 100, 100);
      const r3 = Rect.fromLTWH(200, 200, 50, 50);

      expect(MathUtils.calculateIoU(r1, r2), equals(1.0));
      expect(MathUtils.calculateIoU(r1, r3), equals(0.0));
    });

    test('applyEma smooths continuous coordinates', () {
      const pOld = Offset(100, 100);
      const pNew = Offset(120, 120);

      final smoothed = MathUtils.applyEma(pOld, pNew, 0.5);
      expect(smoothed.dx, equals(110.0));
      expect(smoothed.dy, equals(110.0));
    });
  });
}
