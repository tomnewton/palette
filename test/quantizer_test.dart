import "package:test/test.dart";
import "dart:ui";
import "package:palette/src/color_cut_quantizer.dart";

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
