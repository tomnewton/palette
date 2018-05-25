import 'dart:math' as Math;
import 'dart:ui';

class ColorUtils {
  static const int WHITE = 0xFFFFFF;
  static const int BLACK = 0x000000;

  static const int MIN_ALPHA_SEARCH_MAX_ITERATIONS = 10;
  static const int MIN_ALPHA_SEARCH_PRECISION = 10;

  static int calculateMinimumAlpha(
      int foreground, int background, double minContrastRatio) {
    if (Color(background).alpha != 255) {
      throw new ArgumentError("background can not be translucent");
    }
    // First lets check that a fully opaque foreground has sufficient contrast
    int testForeground = setAlphaComponent(foreground, 255);
    double testRatio = calculateContrast(testForeground, background);
    if (testRatio < minContrastRatio) {
      // Fully opaque foreground does not have sufficient contrast, return error
      return -1;
    }
    // Binary search to find a value with the minimum value which provides sufficient contrast
    int numIterations = 0;
    int minAlpha = 0;
    int maxAlpha = 255;
    while (numIterations <= MIN_ALPHA_SEARCH_MAX_ITERATIONS &&
        (maxAlpha - minAlpha) > MIN_ALPHA_SEARCH_PRECISION) {
      final int testAlpha = ((minAlpha + maxAlpha) / 2).round();
      testForeground = setAlphaComponent(foreground, testAlpha);
      testRatio = calculateContrast(testForeground, background);
      if (testRatio < minContrastRatio) {
        minAlpha = testAlpha;
      } else {
        maxAlpha = testAlpha;
      }
      numIterations++;
    }
    // Conservatively return the max of the range of possible alphas, which is known to pass.
    return maxAlpha;
  }

  static int setAlphaComponent(int color, int alpha) {
    if (alpha < 0 || alpha > 255) {
      throw new ArgumentError("alpha must be between 0 and 255.");
    }
    return (color & 0x00ffffff) | (alpha << 24);
  }

  /*
  * Returns the contrast ratio between {@code foreground} and {@code background}.
  * {@code background} must be opaque.
  * <p>
  * Formula defined
  * <a href="http://www.w3.org/TR/2008/REC-WCAG20-20081211/#contrast-ratiodef">here</a>.
  */
  static double calculateContrast(int foreground, int background) {
    if (Color(background).alpha != 255) {
      throw new ArgumentError("background can not be translucent");
    }
    if (Color(foreground).alpha < 255) {
      // If the foreground is translucent, composite the foreground over the background
      foreground = compositeColors(foreground, background);
    }
    final double luminance1 = calculateLuminance(foreground) + 0.05;
    final double luminance2 = calculateLuminance(background) + 0.05;
    // Now return the lighter luminance divided by the darker luminance
    return Math.max(luminance1, luminance2) / Math.min(luminance1, luminance2);
  }

  /*
  * Returns the luminance of a color.
  *
  * Formula defined here: http://www.w3.org/TR/2008/REC-WCAG20-20081211/#relativeluminancedef
  */
  static double calculateLuminance(int color) {
    double red = ColorUtils.red(color) / 255.0;
    red = red < 0.03928 ? red / 12.92 : Math.pow((red + 0.055) / 1.055, 2.4);
    double green = ColorUtils.green(color) / 255.0;
    green = green < 0.03928
        ? green / 12.92
        : Math.pow((green + 0.055) / 1.055, 2.4);
    double blue = ColorUtils.blue(color) / 255.0;
    blue =
        blue < 0.03928 ? blue / 12.92 : Math.pow((blue + 0.055) / 1.055, 2.4);
    return (0.2126 * red) + (0.7152 * green) + (0.0722 * blue);
  }

  /*
   * Composite two potentially translucent colors over each other and returns the result.
   */
  static int compositeColors(int foreground, int background) {
    int bgAlpha = ColorUtils.alpha(background);
    int fgAlpha = ColorUtils.alpha(foreground);
    int a = _compositeAlpha(fgAlpha, bgAlpha);
    int r = _compositeComponent(ColorUtils.red(foreground), fgAlpha,
        ColorUtils.red(background), bgAlpha, a);
    int g = _compositeComponent(ColorUtils.green(foreground), fgAlpha,
        ColorUtils.green(background), bgAlpha, a);
    int b = _compositeComponent(ColorUtils.blue(foreground), fgAlpha,
        ColorUtils.blue(background), bgAlpha, a);
    return new Color.fromARGB(a, r, g, b).value;
  }

  static void colorToHSL(int color, List<double> hsl) {
    Color c = Color(color);
    ColorUtils.rgbToHSL(c.red, c.green, c.blue, hsl);
  }

  static int colorWithRGB(int r, int g, int b) {
    return new Color.fromARGB(0xFF, r, g, b).value;
  }

  /*
  * Convert RGB components to HSL (hue-saturation-lightness).
  * <ul>
  * <li>hsl[0] is Hue [0 .. 360)</li>
  * <li>hsl[1] is Saturation [0...1]</li>
  * <li>hsl[2] is Lightness [0...1]</li>
  * </ul>
  *
  * @param r   red component value [0..255]
  * @param g   green component value [0..255]
  * @param b   blue component value [0..255]
  * @param hsl 3 element array which holds the resulting HSL components.
  */
  static void rgbToHSL(int r, int g, int b, List<double> hsl) {
    final double rf = r / 255.0;
    final double gf = g / 255.0;
    final double bf = b / 255.0;
    final double max = Math.max<double>(rf, Math.max<double>(gf, bf));
    final double min = Math.min<double>(rf, Math.min<double>(gf, bf));
    final double deltaMaxMin = max - min;
    double h, s;
    double l = (max + min) / 2;
    if (max == min) {
      // Monochromatic
      h = s = 0.0;
    } else {
      if (max == rf) {
        h = ((gf - bf) / deltaMaxMin); //% 6.0; // not sure what the %6 is for.
      } else if (max == gf) {
        h = ((bf - rf) / deltaMaxMin) + 2;
      } else {
        h = ((rf - gf) / deltaMaxMin) + 4;
      }
    }

    // changed calculation for "l" from android implementation based on
    // http://www.niwa.nu/2013/05/math-behind-colorspace-conversions-rgb-hsl/
    if ( l < 0.5 ){
      s = deltaMaxMin / (max + min);
    } else {
      s = deltaMaxMin / (2.0-max-min);
    }

    hsl[0] = (h * 60.0) % 360.0;
    hsl[1] = s;
    hsl[2] = l;
  }

  static int alpha(int color) {
    return Color(color).alpha;
  }

  static int red(int color) {
    return Color(color).red;
  }

  static int blue(int color) {
    return Color(color).blue;
  }

  static int green(int color) {
    return Color(color).green;
  }

  static int _compositeAlpha(int foregroundAlpha, int backgroundAlpha) {
    return (0xFF -
            (((0xFF - backgroundAlpha) * (0xFF - foregroundAlpha)) / 0xFF))
        .round();
  }

  static int _compositeComponent(int fgC, int fgA, int bgC, int bgA, int a) {
    if (a == 0) return 0;
    return (((0xFF * fgC * fgA) + (bgC * bgA * (0xFF - fgA))) / (a * 0xFF))
        .round();
  }

  /*
   * Convert from HSL values to a Color int in ARGB format.
   */
  static int hslToColor(List<double> hsl) {
    final double h = hsl[0];
    final double s = hsl[1];
    final double l = hsl[2];

    if ( h == 0.0 && s == 0.0 ) { // monochromatic
      var val = (l * 255).round();
      return new Color.fromARGB(255, val, val, val).value;
    }

    double temp_1;
    double temp_2;

    if ( l < 0.5 ) {
      temp_1 = l * ( 1.0 + s );
    } else {
      temp_1 = l + s - ( l * s );
    }

    temp_2 = 2 * l - temp_1;

    double hue = h / 360;

    double tempR = (hue + 0.333) % 1;
    double tempG = hue % 1;
    double tempB = (hue - 0.333) % 1;

    double eval(double tempVal) {
      // Tests
      double r;
      if ( 6 * tempVal < 1 ) {
        r = temp_2 + ( temp_1 - temp_2 ) * 6 * tempVal;
      } else if (2 * tempVal < 1 ) {
        r = temp_1;
      } else if ( 3 * tempVal < 2 ) {
        r = temp_2 + ( temp_1 - temp_2 ) * (0.666 - tempVal) * 6;
      } else {
        r = temp_2;
      }
      return r;
    }
    
    int red   = (eval(tempR) * 255).round();
    int green = (eval(tempG) * 255).round();
    int blue  = (eval(tempB) * 255).round();

    return new Color.fromARGB(255, red, green, blue).value;
  }
}
