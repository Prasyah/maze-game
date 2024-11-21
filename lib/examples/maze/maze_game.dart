import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:FlameExamples/examples/maze/maze_renderer.dart';
import 'package:FlameExamples/examples/maze/player.dart';
import 'package:FlameExamples/examples/maze/recursive_maze.dart';

class MazeGame extends Game {
  late List walls;
  Vector2? screenSize;
  bool isMazeRendered = false;
  bool isBallPlaced = false;
  final PlayerController playerController = PlayerController();

  MazeGame() {
    walls = RecursiveMaze().build(21, 21, orientationType: OrientationType.randomized);
    Future.delayed(Duration(milliseconds: 2700), () {
      isMazeRendered = true;
    });
  }

  void placeBallInFreeSpace() {
    for (int y = 0; y < 21; y++) {
      for (int x = 0; x < 21; x++) {
        if (!MazeRenderer.isWall(x, y, walls)) {
          playerController.placeBall(x, y);
          isBallPlaced = true;
          return;
        }
      }
    }
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    screenSize = size;
  }

  @override
  void render(Canvas c) {
    if (screenSize == null) return;
    MazeRenderer.renderBackground(c, screenSize!);
    MazeRenderer.renderWalls(c, walls);
    if (isMazeRendered && !isBallPlaced) {
      placeBallInFreeSpace();
    }
    if (isBallPlaced) {
      playerController.renderPlayer(c);
    }
  }

  @override
  void update(double t) {
    if (!isBallPlaced) return;
    playerController.applyGravity(t);
    if (!MazeRenderer.isCollidingWithWall(playerController.playerX, playerController.newPlayerY, walls, playerController.playerRadius)) {
      playerController.updatePlayerPosition();
    } else {
      playerController.resetVelocity();
    }
  }
}