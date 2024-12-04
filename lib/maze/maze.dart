import 'package:FlameExamples/maze/recursive_maze.dart';
import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:sensors_plus/sensors_plus.dart'; // Import the sensors package
import 'package:flutter/services.dart'; // Import services for keeping the screen on
import 'dart:async'; // Import async package for better event handling
import 'package:wakelock_plus/wakelock_plus.dart';

class Maze extends Game {
  late List walls;
  Paint p = Paint();

  double playerX = 0; // Initial X position of the player
  double playerY = 0; // Initial Y position of the player
  double playerRadius = 6; // Radius of the player (ball)

  double gravityX = 0; // Gravity acceleration in X direction
  double gravityY = 0; // Gravity acceleration in Y direction
  double velocityX = 0; // Horizontal velocity of the player
  double velocityY = 0; // Vertical velocity of the player

  Vector2? screenSize; // Store the size of the canvas
  bool isMazeRendered = false; // Flag to track if the maze is fully rendered
  bool isBallPlaced = false; // Flag to track if the ball has been placed
  bool hasWon = false; // Flag to indicate if the player has won
  bool isGeneratingMaze = true; // Flag for generating maze status

  double accelerometerX = 0; // Variable to store accelerometer X value
  double accelerometerY = 0; // Variable to store accelerometer Y value

  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;

  Maze() {
    WakelockPlus.enable();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(statusBarColor: Colors.transparent));
  }

  @override
  void onDetach() {
    _accelerometerSubscription?.cancel();
    WakelockPlus.disable();
    super.onDetach();
  }

  void startAccelerometer() {
    _accelerometerSubscription = accelerometerEvents.listen((AccelerometerEvent event) {
      gravityX = -event.x * 100;
      gravityY = event.y * 100;
      accelerometerX = event.x;
      accelerometerY = event.y;
    });
  }

  // Memanggil Maze Generator
  void generateMaze() async {
    walls = await RecursiveMaze().build(21, 21);
    isMazeRendered = true;
    isGeneratingMaze = false; // Maze selesai digenerate
    placeBallInFreeSpace();
    startAccelerometer();
  }

  void placeBallInFreeSpace() {
    for (int y = 0; y < 21; y++) {
      for (int x = 0; x < 21; x++) {
        if (!isWall(x, y)) {
          playerX = 16 + x * 16 + playerRadius;
          playerY = 16 + y * 16 + playerRadius;
          isBallPlaced = true;
          return;
        }
      }
    }
  }

  bool isWall(int gridX, int gridY) {
    for (var wall in walls) {
      if (wall['x'] == gridX && wall['y'] == gridY) {
        return true;
      }
    }
    return false;
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    screenSize = size;

    // Pastikan maze dibangun saat game dimulai
    if (screenSize != null && !isMazeRendered) {
      generateMaze();
    }
  }

  @override
  void render(Canvas c) {
    if (screenSize == null) return;

    var bgPaint = Paint();
    bgPaint.color = Colors.black;
    c.drawRect(Rect.fromLTWH(0, 0, screenSize!.x, screenSize!.y), bgPaint);

    // Jika maze masih sedang digenerate, tampilkan pesan loading
    if (isGeneratingMaze) {
      Paint textPaint = Paint()..color = Colors.white;
      TextPainter textPainter = TextPainter(
        text: TextSpan(
          text: 'Generating maze...',
          style: TextStyle(color: Colors.white, fontSize: 24),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(c, Offset(screenSize!.x / 2 - textPainter.width / 2, screenSize!.y / 2 - textPainter.height / 2));
      return; // Jangan lanjutkan render lainnya
    }

    // Jika maze sudah selesai digenerate, render maze dan bola
    double mazeWidth = 21 * 16;
    double mazeHeight = 21 * 16;
    double offsetX = (screenSize!.x - mazeWidth - 32) / 2;
    double offsetY = (screenSize!.y - mazeHeight - 32) / 2;

    Paint wallPaint = Paint();
    wallPaint.color = Colors.white;

    for (var wall in walls) {
      double wallX = offsetX + 16 + double.parse(wall['x'].toString()) * 16;
      double wallY = offsetY + 16 + double.parse(wall['y'].toString()) * 16;
      c.drawRect(Rect.fromLTWH(wallX, wallY, 16, 16), wallPaint);
    }

    if (isBallPlaced) {
      Paint playerPaint = Paint();
      playerPaint.color = Colors.blue;
      c.drawCircle(Offset(playerX + offsetX, playerY + offsetY), playerRadius, playerPaint);
    }

    // Draw win message if the player has won
    if (hasWon && screenSize != null) {
      WakelockPlus.disable();
      TextPainter winTextPainter = TextPainter(
        text: TextSpan(
          text: 'Alarm silenced!',
          style: TextStyle(color: Colors.green, fontSize: 32, fontWeight: FontWeight.bold),
        ),
        textDirection: TextDirection.ltr,
      );
      winTextPainter.layout();
      winTextPainter.paint(c, Offset(screenSize!.x / 2 - winTextPainter.width / 2, screenSize!.y - winTextPainter.height * 4));
    }
  }

  @override
  void update(double t) {
    if (!isBallPlaced || hasWon) return;
    velocityX += gravityX * t;
    velocityY += gravityY * t;

    double newPlayerX = playerX + velocityX * t;
    double newPlayerY = playerY + velocityY * t;

    if (!isCollidingWithWall(newPlayerX, playerY)) {
      playerX = newPlayerX;
    } else {
      velocityX = 0;
    }

    if (!isCollidingWithWall(playerX, newPlayerY)) {
      playerY = newPlayerY;
    } else {
      velocityY = 0;
    }

    if (playerX >= 16 + (20 * 16) && playerY >= 16 + (20 * 16)) {
      hasWon = true;
    }
  }

  bool isCollidingWithWall(double x, double y) {
    for (var wall in walls) {
      double wallX = 16 + double.parse(wall['x'].toString()) * 16;
      double wallY = 16 + double.parse(wall['y'].toString()) * 16;
      double wallSize = 16;

      Rect wallRect = Rect.fromLTWH(wallX, wallY, wallSize, wallSize);
      Rect playerRect = Rect.fromCircle(center: Offset(x, y), radius: playerRadius);
      if (wallRect.overlaps(playerRect)) {
        return true;
      }
    }
    return false;
  }
}
