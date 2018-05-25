import "package:test/test.dart";
import "package:palette/src/palette.dart";
import "dart:io" as Io;
import "dart:ui";
import "dart:typed_data";
import "package:palette/src/bitmap.dart";
import "package:palette/src/color_cut_quantizer.dart";
//import "package:flutter/painting.dart";

void main() {
  test("Test quanization of a color and approximation back...", () {
    var color = new Color(0xFF112233);

    var quant = ColorCutQuantizer.quantizeFromRgb888(color.value);
    var out = new Color(ColorCutQuantizer.approximateToRgb888(quant));

    var dr = color.red - out.red;
    var dg = color.green - out.green;
    var db = color.blue - out.blue;

    expect(dr, lessThan(10));
    expect(dg, lessThan(10));
    expect(db, lessThan(10));
  });
}
