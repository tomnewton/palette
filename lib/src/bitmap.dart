import "dart:typed_data";
import "dart:ui";
import "dart:async";

class Bitmap {
  Image _sourceImg;

  int _width;
  int _height;

  Bitmap(this._sourceImg)
      : _width = _sourceImg.width,
        _height = _sourceImg.height;

  static Future<Bitmap> from(Uint8List data) async {
    var codec = await instantiateImageCodec(data);
    var frameInfo = await codec.getNextFrame();
    var image = frameInfo.image;
    var bmp = new Bitmap(image);
    return bmp;
  }

  Image get source => _sourceImg;

  int get height => _height;

  int get width => _width;

  Future<ByteData> getPNGData() async {
    return await _sourceImg.toByteData(format: ImageByteFormat.png);
  }

  static Future<List<int>> getCopyAllPixels(Bitmap source) async {
    ByteData data =
        await source._sourceImg.toByteData(format: ImageByteFormat.rawRgba);
    var argbByteData = new List<int>(data.lengthInBytes ~/ 4);
    // The f***ing Image class returns pixels in RGBA format... while everything else
    // in dart:ui expects 32-bit integers in ARGB format...
    for (var i = 0; i < data.lengthInBytes; i += 4) {
      var color = data.getUint32(i);
      var argb = Bitmap.rgbaToARGB(color);
      argbByteData[i ~/ 4] = argb;
    }
    return argbByteData;
  }

  static Bitmap createScaledBitmap(Bitmap bitmap, int width, int height) {
    return copyResize(bitmap, width, height);
  }

  static Bitmap copyResize(Bitmap bitmap, int dstWidth, int dstHeight) {
    final int width = bitmap.width;
    final int height = bitmap.height;
    final double sx = dstWidth / width;
    final double sy = dstHeight / height;

    var recorder = new PictureRecorder();

    var canvas = new Canvas(recorder);
    canvas.scale(sx, sy);
    canvas.drawImage(bitmap.source, new Offset(0.0, 0.0), new Paint());

    Picture pic = recorder.endRecording();
    Image img = pic.toImage(dstWidth, dstHeight);
    pic.dispose();
    return new Bitmap(img);
  }

  static int rgbaToARGB(int input) {
    var red = input >> 24;
    var green = input >> 16 & 0x00FF;
    var blue = input >> 8 & 0x0000FF;
    var alpha = input & 0x000000FF;
    return alpha << 24 | red << 16 | green << 8 | blue;
  }
}
