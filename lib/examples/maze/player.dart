import 'package:flutter/material.dart';

class PlayerController {
  double playerX = 0;
  double playerY = 0;
  double playerRadius = 8;
  double gravity = 200;
  double velocityY = 0;
  double newPlayerY = 0;

  void placeBall(int x, int y) {
    playerX = 16 + x * 16 + playerRadius;
    playerY = 16 + y * 16 + playerRadius;
  }

  void applyGravity(double t) {
    velocityY += gravity * t;
    newPlayerY = playerY + velocityY * t;
  }

  void updatePlayerPosition() {
    playerY = newPlayerY;
  }

  void resetVelocity() {
    velocityY = 0;
  }

  void renderPlayer(Canvas c) {
    Paint playerPaint = Paint()..color = Colors.red;
    c.drawCircle(Offset(playerX, playerY), playerRadius, playerPaint);
  }
}