import 'dart:math' as math;
import 'dart:ui';

/// Pure, testable geometry used by Flame obstacle rows.
/// Touching rectangle edges is not a collision.
abstract final class CollisionGeometry {
  static List<Rect> blockedRects({
    required double totalWidth,
    required double rowTop,
    required double rowHeight,
    required int laneCount,
    required List<int> blockedLanes,
    required double laneGap,
  }) {
    assert(laneCount > 0);
    const sidePadding = 14.0;
    final laneWidth = (totalWidth - (sidePadding * 2)) / laneCount;

    return blockedLanes.map((lane) {
      final x = sidePadding + (lane * laneWidth) + (laneGap / 2);
      return Rect.fromLTWH(x, rowTop, laneWidth - laneGap, rowHeight);
    }).toList();
  }

  static bool rowIntersectsVertically({
    required Rect playerRect,
    required double rowTop,
    required double rowHeight,
  }) =>
      playerRect.bottom > rowTop &&
      playerRect.top < rowTop + rowHeight;

  static bool collidesWith(Rect playerRect, List<Rect> obstacles) =>
      obstacles.any((rect) => rect.overlaps(playerRect));

  static double? closestBlockedEdgeDistance(
    Rect playerRect,
    List<Rect> obstacles,
  ) {
    double? closest;

    for (final rect in obstacles) {
      if (playerRect.bottom <= rect.top ||
          playerRect.top >= rect.bottom) {
        continue;
      }

      if (playerRect.right <= rect.left) {
        final distance = rect.left - playerRect.right;
        closest = closest == null
            ? distance
            : math.min(closest, distance);
      } else if (playerRect.left >= rect.right) {
        final distance = playerRect.left - rect.right;
        closest = closest == null
            ? distance
            : math.min(closest, distance);
      } else {
        return 0;
      }
    }

    return closest;
  }
}
