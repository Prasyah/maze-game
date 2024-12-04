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
  double playerRadius = 6; // Radius of the player (ball), reduced for smaller size

  double gravityX = 0; // Gravity acceleration in X direction
  double gravityY = 0; // Gravity acceleration in Y direction
  double velocityX = 0; // Horizontal velocity of the player
  double velocityY = 0; // Vertical velocity of the player

  Vector2? screenSize; // Store the size of the canvas
  bool isMazeRendered = false; // Flag to track if the maze is fully rendered
  bool isBallPlaced = false; // Flag to track if the ball has been placed
  bool hasWon = false; // Flag to indicate if the player has won

  double accelerometerX = 0; // Variable to store accelerometer X value
  double accelerometerY = 0; // Variable to store accelerometer Y value

  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;

  // Timer-related variables
  late Timer _timer;
  int _elapsedSeconds = 0;

  String getFormattedTime() {
    int minutes = _elapsedSeconds ~/ 60;
    int seconds = _elapsedSeconds % 60;
    String minutesStr = minutes.toString().padLeft(2, '0');
    String secondsStr = seconds.toString().padLeft(2, '0');
    return "$minutesStr:$secondsStr";
  }

  Maze() {
    // Make the screen to stay awake
    WakelockPlus.enable();

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
    _timer.cancel();
    WakelockPlus.disable();
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
          
          // Start the timer when the ball is placed
          _startTimer();

          return;
        }
      }
    }
  }

  void _startTimer() {
    _elapsedSeconds = 0;
    // Start the timer with 1-second intervals
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      _elapsedSeconds++;
      // You can add any logic to stop the timer when the game ends
    });
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

  // Draw the formatted timer above the maze
  String formattedTime = getFormattedTime();
  TextPainter timerTextPainter = TextPainter(
    text: TextSpan(
      text: 'Elapsed Time: $formattedTime',
      style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
    ),
    textDirection: TextDirection.ltr,
  );
  timerTextPainter.layout();
  timerTextPainter.paint(c, Offset(screenSize!.x / 2 - timerTextPainter.width / 2, timerTextPainter.height * 2));

  // Calculate the center offset for the maze
  double mazeWidth = 21 * 16;  // Width of the maze (21 cells * 16 pixels per cell)
  double mazeHeight = 21 * 16; // Height of the maze (21 cells * 16 pixels per cell)
  double offsetX = (screenSize!.x - mazeWidth - 32) / 2; // Horizontal offset to center maze
  double offsetY = (screenSize!.y - mazeHeight - 32) / 2; // Vertical offset to center maze

  // Set up the wall paint object
  Paint wallPaint = Paint();
  wallPaint.color = Colors.white;

  // Draw the walls
  for (var wall in walls) {
    // Wall properties
    double wallX = offsetX + 16 + double.parse(wall['x'].toString()) * 16; // Wall's X position with offset
    double wallY = offsetY + 16 + double.parse(wall['y'].toString()) * 16; // Wall's Y position with offset
    double wallSize = 16; // Wall size

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
    if (!isBallPlaced || hasWon) return; // No updates needed if the ball isn't placed or player has won

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

    // Check if the player has reached the lower right corner of the maze
    if (playerX >= 16 + (20 * 16) && playerY >= 16 + (20 * 16)) {
      hasWon = true; // Set win flag to true
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