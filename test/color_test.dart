import "package:test/test.dart";
import "package:palette/src/color_utils.dart";
import "package:palette/src/bitmap.dart";
import "dart:ui";


void main() {
  test("RGB - HSL", () {
    var rgb = 0xFF884422;
    var hsl = new List<double>(3);
    ColorUtils.rgbToHSL(ColorUtils.red(rgb), ColorUtils.green(rgb), ColorUtils.blue(rgb), hsl);
    var want = ColorUtils.hslToColor(hsl);
    expect(want, equals(rgb));
  });

  test('RGBA to ARGB', ()  {
    var rgba = 0xFF0000FF;
    var argb = Bitmap.rgbaToARGB(rgba);
    
    var colorOutput = new Color(argb);

    expect(255, equals(colorOutput.red));
    expect(255, equals(colorOutput.alpha));
    expect(0, equals(colorOutput.green));
    expect(0, equals(colorOutput.blue));
  });
}