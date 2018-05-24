import './palette.dart';
import 'dart:ui';
import 'dart:math' as Math;
import 'package:collection/collection.dart';
import '../colorutils.dart';
import 'constants.dart';

class ColorCutQuantizer {

  static const int COMPONENT_RED = -3;
  static const int COMPONENT_GREEN = -2;
  static const int COMPONENT_BLUE = -1;

  static final int __QUANTIZE_WORD_WIDTH = 5;
  static final int __QUANTIZE_WORD_MASK = ( 1 << __QUANTIZE_WORD_WIDTH ) - 1;

  List<int> _colors;
  List<Swatch> _quantizedColors;
  final List<IFilter> _filters;
  List<int> _histogram;

  final List<double> _temporaryHsl = new List<double>(3);

  ColorCutQuantizer(final List<int> pixels, final int maxColors, this._filters) {
    
    final List<int> hist = _histogram = new List<int>.filled((1 << (__QUANTIZE_WORD_WIDTH * 3)), 0);
    for ( var i = 0; i < pixels.length; i++ ){
      final int pixel = pixels[i];
      final int quantizedColor = quantizeFromRgb888(pixel);
      final int backAgainColor = approximateToRgb888(quantizedColor);
      pixels[i] = quantizedColor;
      hist[quantizedColor] += 1;
    }

    // How many distinct colours do we have?
    int distictColorCount = 0;
    for ( int color = 0; color < hist.length; color++ ) {
      if ( hist[color] > 0 && _shouldIgnoreColorInt(color) ) {
        hist[color] = 0; // set it to 0.
      }
      if ( hist[color] > 0 ) {
        distictColorCount++;
      }
    }

    // build an array of only the distict Colors.
    final List<int> colors = _colors = new List<int>(distictColorCount);
    int distinctColorIndex = 0;
    for ( int color = 0; color < hist.length; color++ ){
      if ( hist[color] > 0){
        colors[distinctColorIndex] = color;
        distinctColorIndex++;
      }
    }

    if ( distictColorCount <= maxColors ) {
      // this image has fewer colors, so just return the colors
      _quantizedColors = new List<Swatch>();
      for (int color in _colors ) {
        var rgb888 = approximateToRgb888(color);
        _quantizedColors.add(new Swatch(new Color(rgb888), hist[color]));
      }
    } else {
      // we need to reduce the colours through quantization
      _quantizedColors = _quantizePixels(maxColors);
    }

  }


  List<Swatch> get quantizedColors => _quantizedColors;


  List<Swatch> _quantizePixels(int maxColors) {

    // Create a priority queue whcih is sorted by volume descending. This means we always
    // split the largest box in the queue

    final PriorityQueue<VBox> queue = new PriorityQueue<VBox>((VBox a, VBox b){
      return b.volume - a.volume;
    });

    // a box whcih contains all of the colours
    queue.add(new VBox(0, _colors.length -1, _colors, _histogram));

    // Start going through the boxes, splitting them until we have reached maxColors, or there are no
    // more boxes to split
    _splitBoxes(queue, maxColors);

    // return the average colors of the color boxes
    return _generateAverageColors(queue);
  }

  void _splitBoxes(PriorityQueue queue, int maxSize) {
    while(queue.length < maxSize) {
      final VBox vbox = queue.removeFirst();

      if ( vbox != null && vbox.canSplit ) {
        // split the box and push the result into the queue
        queue.add(vbox.splitBox(_colors, _histogram));
        // put the box back in as it will be the other half of the split
        queue.add(vbox);
      } else {
        // no more boxes to split.
        return;
      }
    }
  }


  List<Swatch> _generateAverageColors(PriorityQueue<VBox> vboxes) {
    List<Swatch> colors = new List<Swatch>();
    for ( VBox vbox in vboxes.toList() ){
      Swatch swatch = vbox.getAverageColor(_colors, _histogram);
      if (!_shouldIgnoreSwatch(swatch)) {
        // As we're averaging a color box, we can still get colors which we do not want...
        colors.add(swatch);
      }
    }  
    return colors;
  }

  /*
   *  We are reducing the color depth in the image. 
   */
  static int quantizeFromRgb888(int color) {
    Color c = new Color(color);
    int r = _modifyWordWidth(c.red, 8, __QUANTIZE_WORD_WIDTH);
    int g = _modifyWordWidth(c.green, 8, __QUANTIZE_WORD_WIDTH);
    int b = _modifyWordWidth(c.blue, 8, __QUANTIZE_WORD_WIDTH);
    return r << (__QUANTIZE_WORD_WIDTH + __QUANTIZE_WORD_WIDTH) | g << __QUANTIZE_WORD_WIDTH | b;
  }

static int approximateToRgb888(int color) {
    return _approximateToRgb888(quantizedRed(color), quantizedGreen(color), quantizedBlue(color));
  }

  static int _approximateToRgb888(int r, int g, int b) {
    return new Color.fromARGB(
      255, 
      _modifyWordWidth(r, __QUANTIZE_WORD_WIDTH, 8),
      _modifyWordWidth(g, __QUANTIZE_WORD_WIDTH, 8),
      _modifyWordWidth(b, __QUANTIZE_WORD_WIDTH, 8)
      ).value;
  }

  bool _shouldIgnoreColorInt(int color) {
    final int rgb = approximateToRgb888(color);
    ColorUtils.ColorToHSL(color, _temporaryHsl);
    var shouldIgnore = _shouldIgnoreColorRGBHSL(rgb, _temporaryHsl);
    return shouldIgnore;
  }

  bool _shouldIgnoreColorRGBHSL(int rgb, List<double> hsl) {
    if (_filters != null && _filters.length > 0) {
      for (int i = 0, count = _filters.length; i < count; i++) {
        if (!_filters[i].isAllowed(rgb, hsl)) {
          return true;
        }
      }
    }
    return false;
  }

  bool _shouldIgnoreSwatch(Swatch s) {
    return _shouldIgnoreColorRGBHSL(s.rgb, s.hsl);
  }

  /*
   * @return red component of the quantized color
   */
  static int quantizedRed(int color) {
    return (color >> (__QUANTIZE_WORD_WIDTH + __QUANTIZE_WORD_WIDTH)) & __QUANTIZE_WORD_MASK;
  }
  /*
   * @return green component of a quantized color
   */
  static int quantizedGreen(int color) {
    return (color >> __QUANTIZE_WORD_WIDTH) & __QUANTIZE_WORD_MASK;
  }
  /*
   * @return blue component of a quantized color
   */
  static int quantizedBlue(int color) {
    return color & __QUANTIZE_WORD_MASK;
  }


  static int _modifyWordWidth(int value, int currentWidth, int targetWidth) {
    int newValue;

    if ( targetWidth > currentWidth ) {
      // if we are aprroximating up in word width, we'll shift up
      newValue = value << ( targetWidth - currentWidth );
    } else { 
      // Else, we will shift and keep the most significant bit
      newValue = value >> ( currentWidth - targetWidth );
    }

    return newValue & ((1 << targetWidth) - 1);
  }

  /*static void modifySignificantOctet(final List<int> a, final int dimension, final int lower, final int upper) {
    switch (dimension) {
      case COMPONENT_RED:
        // We are already in RGB
        break;
      case COMPONENT_GREEN:
        // need to go from RGB to 
    }
  }*/
}




class VBox {
  int _lowerIndex;
  int _upperIndex;
  int _population;

  int _minRed;
  int _maxRed;
  int _minGreen;
  int _maxGreen;
  int _minBlue;
  int _maxBlue;

  VBox(this._lowerIndex, this._upperIndex, final List<int> colors, final List<int> histogram) {
    fitBox(colors, histogram);
  }

  void fitBox(final List<int> colors, final List<int> histogram) {
    int minRed, minGreen, minBlue;
    minRed = minGreen = minBlue = INTEGER_MAX_VALUE;
    int maxRed, maxGreen, maxBlue;
    maxRed = maxGreen = maxBlue = INTEGER_MIN_VALUE;

    int count = 0;

    for ( int i = _lowerIndex; i <= _upperIndex; i++ ) {
      final int color = colors[i];
      count += histogram[color];

      final int r = ColorCutQuantizer.quantizedRed(color);
      final int g = ColorCutQuantizer.quantizedGreen(color);
      final int b = ColorCutQuantizer.quantizedBlue(color);

      maxRed = Math.max(maxRed, r);
      maxGreen = Math.max(maxGreen, g);
      maxBlue = Math.max(maxBlue, b);

      minRed = Math.min(minRed, r);
      minGreen = Math.min(minGreen, g);
      minBlue = Math.min(minBlue, b);
    }

    _maxRed = maxRed;
    _maxGreen = maxGreen;
    _maxBlue = maxBlue;
    _minRed = minRed;
    _minGreen = minGreen;
    _minBlue = minBlue;
    _population = count;
  }

  bool get canSplit => this.colorCount > 1;

  int get colorCount => 1 + _upperIndex - _lowerIndex;
  
  int get volume => (_maxRed - _minRed + 1) * (_maxGreen - _minGreen + 1) * (_maxBlue - _minBlue +1 );

  Swatch getAverageColor(final List<int> colors, final List<int> histogram) {
    int redSum = 0;
    int greenSum = 0;
    int blueSum = 0;
    int totalPopulation = 0;

    for (int i = _lowerIndex; i <= _upperIndex; i++ ){
      final int color = colors[i];
      final colorPopulation = histogram[color];

      totalPopulation += colorPopulation;
      redSum += colorPopulation * ColorCutQuantizer.quantizedRed(color);
      greenSum += colorPopulation * ColorCutQuantizer.quantizedGreen(color);
      blueSum += colorPopulation * ColorCutQuantizer.quantizedBlue(color);
    }

    final int redMean = (redSum ~/ totalPopulation);
    final int greenMean = (greenSum ~/ totalPopulation);
    final int blueMean = (blueSum ~/ totalPopulation);
    int rgb888 = ColorCutQuantizer._approximateToRgb888(redMean, greenMean, blueMean);
    return new Swatch(new Color(rgb888), totalPopulation);
  }


  /*
   * @return the dimension which this box is largest in
   */
  int getLongestColorDimension() {
    final int redLength = _maxRed - _minRed;
    final int greenLength = _maxGreen - _minGreen;
    final int blueLength = _maxBlue - _minBlue;
    if (redLength >= greenLength && redLength >= blueLength) {
        return ColorCutQuantizer.COMPONENT_RED;
    } else if (greenLength >= redLength && greenLength >= blueLength) {
        return ColorCutQuantizer.COMPONENT_GREEN;
    } else {
        return ColorCutQuantizer.COMPONENT_BLUE;
    }
  }

  VBox splitBox(final List<int> colors, final List<int> histogram) {
    if ( !this.canSplit ) {
      throw new ArgumentError("Can not split a box with only 1 color.");
    }

    // find the split point along the longest dimension
    final int splitPoint = findSplitPoint(colors, histogram);

    // create one of the two resulting boxes...
    VBox newBox = new VBox(splitPoint+1, _upperIndex, colors, histogram);

    // now alter this VBox to become the other of the two split boxes.
    _upperIndex = splitPoint;
    fitBox(colors, histogram);

    return newBox;
  }


  int findSplitPoint(final List<int> colors, final List<int> histogram) {
    final int longestDimension = getLongestColorDimension();
    

    // We need to sort the colors in this box based on the longest color dimension.
    // As we can't use a Comparator to define the sort logic, we modify each color so that
    // its most significant is the desired dimension
    colors.sort((int a, int b){
      switch(longestDimension) {
        case ColorCutQuantizer.COMPONENT_RED:
          return redComparator(a, b);
        case ColorCutQuantizer.COMPONENT_GREEN:
          return greenComparator(a, b);
        case ColorCutQuantizer.COMPONENT_BLUE:
          return blueComparator(a, b);
        default:
          throw new ArgumentError("Bad long dimension");
      }
    });

    final int midPoint = _population ~/ 2;
    int count = 0;
    for ( int i = _lowerIndex; i <= _upperIndex; i++ ) {
      count += histogram[colors[i]];
      if ( count >= midPoint ) {
        // dont split a box on the  upperIndex, as you'll just return the same box
        return Math.min(_upperIndex -1, i);
      }
    }

    return _lowerIndex;
  }

  int redComparator(int a, int b) {
    return a.compareTo(b);
  }

  int greenComparator(int a, int b) {
    Function swizzle = (int val) {
      return ColorCutQuantizer.quantizedGreen(val) << (ColorCutQuantizer.__QUANTIZE_WORD_WIDTH + ColorCutQuantizer.__QUANTIZE_WORD_WIDTH)
              | ColorCutQuantizer.quantizedRed(val) << ColorCutQuantizer.__QUANTIZE_WORD_WIDTH
              | ColorCutQuantizer.quantizedBlue(val);
    };

    var aa = swizzle(a);
    var bb = swizzle(b);
    return aa.compareTo(bb);
  }

  int blueComparator(int a, int b) {
    Function swizzle = (int val) {
      return ColorCutQuantizer.quantizedBlue(val) << (ColorCutQuantizer.__QUANTIZE_WORD_WIDTH + ColorCutQuantizer.__QUANTIZE_WORD_WIDTH)
              | ColorCutQuantizer.quantizedGreen(val) << ColorCutQuantizer.__QUANTIZE_WORD_WIDTH
              | ColorCutQuantizer.quantizedRed(val);
    };

    return swizzle(a).compareTo(swizzle(b));
  }

}