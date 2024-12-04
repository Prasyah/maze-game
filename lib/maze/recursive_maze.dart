import 'dart:math';

class RecursiveMaze {
  late int width, height;
  late OrientationType mOrientationType;

  RecursiveMaze() {}

  // Modifikasi: build() mengembalikan Future
  Future<List> build(int width, int height,
      {OrientationType orientationType = OrientationType.symmetrical}) async {
    mOrientationType = orientationType;
    List wallList = [];

    // Bangun dinding luar terlebih dahulu
    getSquare(width, height, wallList);

    // Menunggu divisi chamber selesai sebelum mengembalikan hasil
    await divideChamber(0, 0, width, height, wallList, true);

    return wallList; // Mengembalikan wallList setelah maze selesai
  }

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

  Future divideChamber(int posX, int posY, int width, int height, List wallList,
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
          await Future.delayed(Duration(milliseconds: 10)); // Menunggu sedikit di antara wall placement
        }
      }
    } else {
      var r = Random().nextInt(width);
      while (r % 2 != 0) r = Random().nextInt(width);
      for (int x = 0; x < width; x++) {
        if (r != x) {
          wallList.add({'x': posX + x, 'y': posY + halfWallY});
          await Future.delayed(Duration(milliseconds: 10)); // Menunggu sedikit di antara wall placement
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

  bool isVerticalOrientation(width, height, previousOrientation) {
    if (mOrientationType == OrientationType.randomized) {
      if (width < height) {
        return false;
      } else if (height < width)
        return true;
      else {
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
