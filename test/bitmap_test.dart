import 'package:test/test.dart';
import 'dart:io' as Io;
import 'package:palette/src/bitmap.dart';

main() {
  test("Test scale down bmp", () async {
    var bytes = new Io.File('data/mat.png').readAsBytesSync();

    // Create a bitmap and copy resize.
    var bmp = await Bitmap.from(bytes);
    var cpy = Bitmap.copyResize(bmp, 387, 233);
    expect(cpy.width, equals(387));
    expect(cpy.height, equals(233));
  });

  test("Test RGBA to ARGB", () {
    var rgba = 0x11223344;
    var argb = Bitmap.rgbaToARGB(rgba);

    expect(0x44, equals(argb >> 24));
    expect(0x44112233, equals(argb));
  });
}
