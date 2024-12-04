import 'dart:math';

class RecursiveMaze {
  late int width, height;
  late OrientationType mOrientationType;

  RecursiveMaze() {
    //
  }

  // Update build method to be asynchronous
  Future<List> buildAsync(int width, int height,
      {OrientationType orientationType = OrientationType.symmetrical}) async {
    mOrientationType = orientationType;
    List wallList = [];

    // Call synchronous functions to initialize walls
    getSquare(width, height, wallList);

    // Await the asynchronous divideChamber call
    await divideChamber(0, 0, width, height, wallList, true);

    return wallList;
  }

  // Function to initialize the border walls
  void getSquare(int width, int height, List wallList) {
    for (int y = 0; y < height + 2; y++) {
      wallList.add({'x': -1, 'y': y - 1});
    }
    for (int y = 0; y < height + 2; y++) {
      wallList.add({'x': height, 'y': y - 1});
    }
    for (int x = 0; x < width; x++) {
      wallList.add({'x': x, 'y': -1});
    }
    for (int x = 0; x < width; x++) {
      wallList.add({'x': x, 'y': width});
    }
  }

  // Recursive async function to divide chambers and add walls
  Future<void> divideChamber(int posX, int posY, int width, int height, List wallList,
      bool isVertical) async {
    if (width <= 1 || height <= 1) return;

    var halfWallX = (width / 2).floor();
    var halfWallY = (height / 2).floor();

    if ((posX + halfWallX) % 2 == 0) halfWallX--;
    if ((posY + halfWallY) % 2 == 0) halfWallY--;

    if (isVertical) {
      var r = Random().nextInt(height);
      while (r % 2 != 0) r = Random().nextInt(height);
      for (int y = 0; y < height; y++) {
        if (r != y) {
          wallList.add({'x': posX + halfWallX, 'y': posY + y});
          await Future.delayed(Duration(milliseconds: 10)); // Simulate async delay
        }
      }
    } else {
      var r = Random().nextInt(width);
      while (r % 2 != 0) r = Random().nextInt(width);
      for (int x = 0; x < width; x++) {
        if (r != x) {
          wallList.add({'x': posX + x, 'y': posY + halfWallY});
          await Future.delayed(Duration(milliseconds: 10)); // Simulate async delay
        }
      }
    }

    var nextWidth = width;
    var nextHeight = height;

    if (isVertical) {
      nextWidth = halfWallX;
    } else {
      nextHeight = halfWallY;
    }

    // Recursive calls
    if (halfWallX >= 1 || halfWallY >= 2) {
      var orientation =
          isVerticalOrientation(nextWidth, nextHeight, isVertical);
      await divideChamber(
          posX, posY, nextWidth, nextHeight, wallList, orientation);

      orientation = isVerticalOrientation(nextWidth, nextHeight, isVertical);
      if (!isVertical) {
        await divideChamber(
          posX,
          posY + nextHeight + 1,
          nextWidth,
          height - nextHeight - 1,
          wallList,
          orientation,
        );
      } else {
        await divideChamber(
          posX + nextWidth + 1,
          posY,
          width - nextWidth - 1,
          nextHeight,
          wallList,
          orientation,
        );
      }
    }
  }

  bool isVerticalOrientation(int width, int height, bool previousOrientation) {
    if (mOrientationType == OrientationType.randomized) {
      if (width < height) {
        return false;
      } else if (height < width) {
        return true;
      } else {
        return Random().nextInt(2) == 0;
      }
    } else {
      return !previousOrientation;
    }
  }
}

enum OrientationType {
  symmetrical,
  randomized,
}
