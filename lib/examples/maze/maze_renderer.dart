import 'package:flame/game.dart';
import 'package:flutter/material.dart';

class MazeRenderer {
  static void renderBackground(Canvas c, Vector2 screenSize) {
    Paint bgPaint = Paint()..color = Colors.black;
    c.drawRect(Rect.fromLTWH(0, 0, screenSize.x, screenSize.y), bgPaint);
  }

  static void renderWalls(Canvas c, List walls) {
    Paint wallPaint = Paint()..color = Colors.white;
    for (var wall in walls) {
      double wallX = 16 + double.parse(wall['x'].toString()) * 16;
      double wallY = 16 + double.parse(wall['y'].toString()) * 16;
      Rect wallRect = Rect.fromLTWH(wallX, wallY, 16, 16);
      c.drawRect(wallRect, wallPaint);
    }
  }

  static bool isWall(int gridX, int gridY, List walls) {
    for (var wall in walls) {
      if (wall['x'] == gridX && wall['y'] == gridY) {
        return true;
      }
    }
    return false;
  }

  static bool isCollidingWithWall(double x, double y, List walls, double playerRadius) {
    for (var wall in walls) {
      double wallX = 16 + double.parse(wall['x'].toString()) * 16;
      double wallY = 16 + double.parse(wall['y'].toString()) * 16;
      Rect wallRect = Rect.fromLTWH(wallX, wallY, 16, 16);
      Rect playerRect = Rect.fromCircle(center: Offset(x, y), radius: playerRadius);
      if (wallRect.overlaps(playerRect)) {
        return true;
      }
    }
    return false;
  }
}
