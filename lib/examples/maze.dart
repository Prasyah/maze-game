import 'package:FlameExamples/examples/maze/recursive_maze.dart';
import 'package:flutter/material.dart';
import 'package:flame/game.dart';

class Maze extends Game {
  late List walls;
  Paint p = Paint();

  double playerX = 0; // Initial X position of the player
  double playerY = 0; // Initial Y position of the player
  double playerRadius = 8; // Radius of the player (ball)

  double gravity = 200; // Gravity acceleration in pixels per second squared
  double velocityY = 0; // Vertical velocity of the player

  Vector2? screenSize; // Store the size of the canvas
  bool isMazeRendered = false; // Flag to track if the maze is fully rendered
  bool isBallPlaced = false; // Flag to track if the ball has been placed

  Maze() {
    // Build the maze and initiate the walls
    walls = RecursiveMaze().build(21, 21, orientationType: OrientationType.randomized);

    // Simulate a delay to indicate maze rendering has completed
    Future.delayed(Duration(milliseconds: 2700), () {
      isMazeRendered = true; // Set maze rendered flag to true after some time
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
  }

  @override
  void update(double t) {
    if (!isBallPlaced) return; // No updates needed if the ball isn't placed yet

    // Apply gravity to the vertical velocity
    velocityY += gravity * t;

    // Calculate the new player position based on the velocity
    double newPlayerY = playerY + velocityY * t;

    // Collision detection with walls
    if (!isCollidingWithWall(playerX, newPlayerY)) {
      playerY = newPlayerY; // Update position if no collision
    } else {
      velocityY = 0; // Stop falling when colliding with a wall
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
