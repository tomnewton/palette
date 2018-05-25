import "package:test/test.dart";
import "package:palette/src/color_utils.dart";
import "package:palette/src/bitmap.dart";
import "dart:ui";

void main() {
  test("RGB - HSL", () {
    var rgb = 0xFF884422;
    var hsl = new List<double>(3);

    // Compute the HSL
    ColorUtils.rgbToHSL(
        ColorUtils.red(rgb), ColorUtils.green(rgb), ColorUtils.blue(rgb), hsl);

    // Check they're what we'd expect. Values from https://www.w3schools.com/colors/colors_picker.asp
    expect(
        hsl,
        equals(new List<double>.from(
            [20.0, 0.6000000000000001, 0.3333333333333333])));

    var have = ColorUtils.hslToColor(hsl);

    // Hopefully we've got the original rgb colour back.
    expect(have, equals(rgb));

    // Try another for good luck.
    rgb = 0xfff07c0f;
    hsl = new List<double>(3);
    ColorUtils.rgbToHSL(
        ColorUtils.red(rgb), ColorUtils.green(rgb), ColorUtils.blue(rgb), hsl);
    have = ColorUtils.hslToColor(hsl);
    expect(have, equals(rgb));
  });

  test('RGBA to ARGB', () {
    var rgba = 0xFF0000FF;
    var argb = Bitmap.rgbaToARGB(rgba);

    var colorOutput = new Color(argb);

    expect(255, equals(colorOutput.red));
    expect(255, equals(colorOutput.alpha));
    expect(0, equals(colorOutput.green));
    expect(0, equals(colorOutput.blue));
  });
}
