import 'package:FlameExamples/maze/recursive_maze.dart';
import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:sensors_plus/sensors_plus.dart'; // Import the sensors package
import 'package:flutter/services.dart'; // Import services for keeping the screen on
import 'dart:async'; // Import async package for better event handling

class Maze extends Game {
  late List walls;
  Paint p = Paint();

  double playerX = 0; // Initial X position of the player
  double playerY = 0; // Initial Y position of the player
  double playerRadius = 6; // Radius of the player (ball), reduced for smaller size

  double gravityX = 0; // Gravity acceleration in X direction
  double gravityY = 0; // Gravity acceleration in Y direction
  double velocityX = 0; // Horizontal velocity of the player
  double velocityY = 0; // Vertical velocity of the player
  double bounceFactor = -0.6; // Bounce factor to reverse velocity and reduce it

  Vector2? screenSize; // Store the size of the canvas
  bool isMazeRendered = false; // Flag to track if the maze is fully rendered
  bool isBallPlaced = false; // Flag to track if the ball has been placed

  double accelerometerX = 0; // Variable to store accelerometer X value
  double accelerometerY = 0; // Variable to store accelerometer Y value

  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;

  Maze() {
    // Build the maze and initiate the walls
    walls = RecursiveMaze().build(21, 21, orientationType: OrientationType.randomized);

    // Simulate a delay to indicate maze rendering has completed
    Future.delayed(Duration(milliseconds: 2700), () {
      isMazeRendered = true; // Set maze rendered flag to true after some time
    });

    // Keep the screen awake while the game is running
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(statusBarColor: Colors.transparent));
  }

  @override
  void onDetach() {
    // Cancel the accelerometer subscription when the game is detached
    _accelerometerSubscription?.cancel();
    super.onDetach();
  }

  void startAccelerometer() {
    // Listen to accelerometer events to update gravity direction
    _accelerometerSubscription = accelerometerEventStream().listen((AccelerometerEvent event) {
      gravityX = -event.x * 100; // Adjust gravity based on accelerometer X axis for horizontal movement
      gravityY = event.y * 100; // Adjust gravity based on accelerometer Y axis for vertical movement

      accelerometerX = event.x; // Update accelerometer X value for display
      accelerometerY = event.y; // Update accelerometer Y value for display
    });
  }

  void placeBallInFreeSpace() {
    // Find a free space in the upper left corner to place the ball
    for (int y = 0; y < 21; y++) {
      for (int x = 0; x < 21; x++) {
        if (!isWall(x, y)) {
          // Found a free spot
          playerX = 16 + x * 16 + playerRadius; // Center the ball in the cell
          playerY = 16 + y * 16 + playerRadius; // Center the ball in the cell
          isBallPlaced = true; // Set ball placed flag to true
          startAccelerometer(); // Start reading accelerometer once the ball is placed
          return;
        }
      }
    }
  }

  bool isWall(int gridX, int gridY) {
    // Check if there's a wall at the given grid position
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
    screenSize = size; // Capture the screen size when it changes
  }

  @override
  void render(Canvas c) {
    if (screenSize == null) return; // If the size isn't initialized yet, do nothing

    var bgPaint = Paint();
    bgPaint.color = Colors.black;

    // Draw the background
    c.drawRect(
      Rect.fromLTWH(0, 0, screenSize!.x, screenSize!.y),
      bgPaint,
    );

    // Set up the wall paint object
    Paint wallPaint = Paint();
    wallPaint.color = Colors.white;

    for (var wall in walls) {
      // Wall properties
      double wallX = 16 + double.parse(wall['x'].toString()) * 16;
      double wallY = 16 + double.parse(wall['y'].toString()) * 16;
      double wallSize = 16;

      // Define the wall rect
      Rect wallRect = Rect.fromLTWH(wallX, wallY, wallSize, wallSize);

      // Draw the wall
      c.drawRect(wallRect, wallPaint);
    }

    // Place the ball once the maze is rendered
    if (isMazeRendered && !isBallPlaced) {
      placeBallInFreeSpace();
    }

    // Draw the player (ball) if it has been placed
    if (isBallPlaced) {
      Paint playerPaint = Paint();
      playerPaint.color = Colors.blue;
      c.drawCircle(Offset(playerX, playerY), playerRadius, playerPaint);
    }

    // Draw accelerometer readings at the bottom of the screen
    if (screenSize != null) {
      TextPainter textPainter = TextPainter(
        text: TextSpan(
          text: 'Accelerometer X: ${accelerometerX.toStringAsFixed(2)}, Y: ${accelerometerY.toStringAsFixed(2)}',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(c, Offset(10, screenSize!.y - 30));
    }
  }

  @override
  void update(double t) {
    if (!isBallPlaced) return; // No updates needed if the ball isn't placed yet

    // Apply gravity to the velocity
    velocityX += gravityX * t;
    velocityY += gravityY * t;

    // Calculate the new player position based on the velocity
    double newPlayerX = playerX + velocityX * t;
    double newPlayerY = playerY + velocityY * t;

    // Handle collision with walls by stopping the movement in the direction of collision
    if (!isCollidingWithWall(newPlayerX, playerY)) {
      playerX = newPlayerX; // Update X position if no collision
    } else {
      velocityX = 0; // Stop horizontal movement on collision
    }

    if (!isCollidingWithWall(playerX, newPlayerY)) {
      playerY = newPlayerY; // Update Y position if no collision
    } else {
      velocityY = 0; // Stop vertical movement on collision
    }
  }

  bool isCollidingWithWall(double x, double y) {
    // Check collision of player (ball) with each wall
    for (var wall in walls) {
      double wallX = 16 + double.parse(wall['x'].toString()) * 16;
      double wallY = 16 + double.parse(wall['y'].toString()) * 16;
      double wallSize = 16;

      // Define wall rectangle
      Rect wallRect = Rect.fromLTWH(wallX, wallY, wallSize, wallSize);

      // Check if the ball intersects the wall
      Rect playerRect = Rect.fromCircle(center: Offset(x, y), radius: playerRadius);
      if (wallRect.overlaps(playerRect)) {
        return true; // Collision detected
      }
    }
    return false; // No collision
  }
}
