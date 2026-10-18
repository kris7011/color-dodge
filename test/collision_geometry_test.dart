import 'dart:ui';

import 'package:color_dodge/game/collision_geometry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final rectangles = CollisionGeometry.blockedRects(
    totalWidth: 330,
    rowTop: 100,
    rowHeight: 25,
    laneCount: 3,
    blockedLanes: [0, 2],
    laneGap: 8,
  );

  test('blocked geometry reserves the center safe lane', () {
    expect(rectangles, hasLength(2));
    expect(rectangles.first.left, closeTo(18, 0.0001));
    expect(rectangles.last.left, greaterThan(200));
  });

  test('a hit on a blocked lane counts as a collision', () {
    expect(
      CollisionGeometry.collidesWith(
        const Rect.fromLTWH(20, 105, 30, 15),
        rectangles,
      ),
      isTrue,
    );
  });

  test('safe lane does not collide', () {
    expect(
      CollisionGeometry.collidesWith(
        const Rect.fromLTWH(145, 105, 30, 15),
        rectangles,
      ),
      isFalse,
    );
  });

  test('touching vertical edges is not an overlap', () {
    expect(
      CollisionGeometry.rowIntersectsVertically(
        playerRect: const Rect.fromLTWH(20, 125, 20, 20),
        rowTop: 100,
        rowHeight: 25,
      ),
      isFalse,
    );
    expect(
      CollisionGeometry.collidesWith(
        const Rect.fromLTWH(20, 125, 20, 20),
        rectangles,
      ),
      isFalse,
    );
  });

  test('near miss distance reflects the closest obstacle', () {
    final nearMiss = CollisionGeometry.closestBlockedEdgeDistance(
      const Rect.fromLTWH(112, 105, 30, 15),
      rectangles,
    );
    expect(nearMiss, isNotNull);
    expect(nearMiss!, greaterThanOrEqualTo(0));
    expect(nearMiss, lessThan(8));
  });

  test('no vertical overlap means no near miss', () {
    expect(
      CollisionGeometry.closestBlockedEdgeDistance(
        const Rect.fromLTWH(112, 200, 30, 15),
        rectangles,
      ),
      isNull,
    );
  });
}
