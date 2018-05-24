import 'dart:ui';
import 'dart:async';
import 'dart:math' as Math;
import 'rect.dart' as RECT;
import 'dart:typed_data';
import 'color_utils.dart';
import 'bitmap.dart';
import 'target.dart';
import 'color_cut_quantizer.dart';
import 'constants.dart';

class Palette {
  static const int DEFAULT_RESIZE_BITMAP_AREA = 112 * 112;
  static const int DEFAULT_CALCULATE_NUMBER_COLORS = 16;
  static const double MIN_CONTRAST_TITLE_TEXT = 3.0;
  static const double MIN_CONTRAST_BODY_TEXT = 4.5;

  static Builder from(Bitmap bmp) {
    return new Builder(bmp);
  }

  final List<Swatch> _swatches;
  final List<Target> _targets;
  final Map<Target, Swatch> _selectedSwatches = new Map<Target, Swatch>();
  final Map<int, bool> _usedColors = new Map<int, bool>();

  final Swatch _dominantSwatch;

  Palette(this._swatches, this._targets) : 
    _dominantSwatch = findDominantSwatch(_swatches);


  Future<Bitmap> render(int columnWidth, int height) async {
    List<Color> colors = new List<Color>();
    for(var swatch in _swatches) {
      colors.add(new Color(swatch.rgb));
    }

    var recorder = new PictureRecorder();
    var canvas = new Canvas(recorder);

    var rowWidth = columnWidth * colors.length;
    for ( var h = 0; h < height; h++ ){
      for(var i = 0; i < colors.length; i++ ){
        var color = colors[i];
        for ( var j = 0; j < columnWidth; j++ ){
          var y = h.toDouble();
          var x = (i*columnWidth) + j.toDouble();
          canvas.drawRawPoints(PointMode.points, new Float32List.fromList([x, y]), new Paint()..color = color);
        }
      }
    }
    var img = recorder.endRecording().toImage(rowWidth, height);

    return new Bitmap(img);
  }

  /*
   * Returns all of the swatches which make up the palette.
   */
  List<Swatch> getSwatches() {
      //return Collections.unmodifiableList(mSwatches);
      return new List.unmodifiable(_swatches);
  }
  /*
   * Returns the targets used to generate this palette.
   */
  List<Target> getTargets() {
      //return Collections.unmodifiableList(mTargets);
      return new List.unmodifiable(_targets);
  }
  /*
   * Returns the most vibrant swatch in the palette. Might be null.
   *
   * @see Target#VIBRANT
   */
  Swatch getVibrantSwatch() {
      //return getSwatchForTarget(Target.VIBRANT);
      return _selectedSwatches[Target.VIBRANT];
  }
  /*
   * Returns a light and vibrant swatch from the palette. Might be null.
   *
   * @see Target#LIGHT_VIBRANT
   */
  Swatch getLightVibrantSwatch() {
      return _selectedSwatches[Target.LIGHT_VIBRANT];
  }
  /*
   * Returns a dark and vibrant swatch from the palette. Might be null.
   *
   * @see Target#DARK_VIBRANT
   */
  Swatch getDarkVibrantSwatch() {
      return _selectedSwatches[Target.DARK_VIBRANT];
  }
  /*
   * Returns a muted swatch from the palette. Might be null.
   *
   * @see Target#MUTED
   */
  Swatch getMutedSwatch() {
      return _selectedSwatches[Target.MUTED];
  }
  /*
   * Returns a muted and light swatch from the palette. Might be null.
   *
   * @see Target#LIGHT_MUTED
   */
  Swatch getLightMutedSwatch() {
      return _selectedSwatches[Target.LIGHT_MUTED];
  }
  /*
   * Returns a muted and dark swatch from the palette. Might be null.
   *
   * @see Target#DARK_MUTED
   */
  Swatch getDarkMutedSwatch() {
      return _selectedSwatches[Target.DARK_MUTED];
  }
  /*
   * Returns the most vibrant color in the palette as an RGB packed int.
   *
   * @param defaultColor value to return if the swatch isn't available
   * @see #getVibrantSwatch()
   */
  int getVibrantColor(final int defaultColor) {
      return getColorForTarget(Target.VIBRANT, defaultColor);
  }
  /*
   * Returns a light and vibrant color from the palette as an RGB packed int.
   *
   * @param defaultColor value to return if the swatch isn't available
   * @see #getLightVibrantSwatch()
   */
  int getLightVibrantColor(final int defaultColor) {
      return getColorForTarget(Target.LIGHT_VIBRANT, defaultColor);
  }
  /*
   * Returns a dark and vibrant color from the palette as an RGB packed int.
   *
   * @param defaultColor value to return if the swatch isn't available
   * @see #getDarkVibrantSwatch()
   */
  int getDarkVibrantColor(final int defaultColor) {
      return getColorForTarget(Target.DARK_VIBRANT, defaultColor);
  }
  /*
   * Returns a muted color from the palette as an RGB packed int.
   *
   * @param defaultColor value to return if the swatch isn't available
   * @see #getMutedSwatch()
   */
  int getMutedColor(final int defaultColor) {
      return getColorForTarget(Target.MUTED, defaultColor);
  }
  /*
   * Returns a muted and light color from the palette as an RGB packed int.
   *
   * @param defaultColor value to return if the swatch isn't available
   * @see #getLightMutedSwatch()
   */
  int getLightMutedColor(final int defaultColor) {
      return getColorForTarget(Target.LIGHT_MUTED, defaultColor);
  }
  /*
   * Returns a muted and dark color from the palette as an RGB packed int.
   *
   * @param defaultColor value to return if the swatch isn't available
   * @see #getDarkMutedSwatch()
   */
  int getDarkMutedColor(final int defaultColor) {
      return getColorForTarget(Target.DARK_MUTED, defaultColor);
  }

  /*
   * Returns the selected color for the given target from the palette as an RGB packed int.
   *
   * @param defaultColor value to return if the swatch isn't available
   */
  int getColorForTarget(final Target target, final int defaultColor) {
      Swatch swatch = _selectedSwatches[target];
      return swatch != null ? swatch.rgb : defaultColor;
  }

  /*
   * Returns the dominant swatch from the palette.
   *
   * <p>The dominant swatch is defined as the swatch with the greatest population (frequency)
   * within the palette.</p>
   */
  Swatch getDominantSwatch() {
      return _dominantSwatch;
  }


  void generate() {
    // Need to make sure that scored targets are generated first. This is
    // so that inherited targets have something to inherit from.
    int count = _targets.length;
    for ( int i = 0; i < count; i++ ) {
      final Target target = _targets[i];
      target.normalizeWeights();
      _selectedSwatches[target] = _generateScoredTarget(target);
    }
    _usedColors.clear();
  }

  Swatch _generateScoredTarget(final Target target) {
    final Swatch maxScoreSwatch = _getMaxScoredSwatchForTarget(target);
    if (maxScoreSwatch != null && target.isExclusive() ) {
      _usedColors[maxScoreSwatch.rgb] = true;
    }
    return maxScoreSwatch;
  }

  Swatch _getMaxScoredSwatchForTarget(final Target target) {
    double maxScore = 0.0;
    Swatch maxScoreSwatch;
    for (int i = 0, count = _swatches.length; i < count; i++) {
        final Swatch swatch = _swatches[i];
        if (_shouldBeScoredForTarget(swatch, target)) {
            final double score = _generateScore(swatch, target);
            if (maxScoreSwatch == null || score > maxScore) {
                maxScoreSwatch = swatch;
                maxScore = score;
            }
        }
    }
    return maxScoreSwatch;
  }

  bool _shouldBeScoredForTarget(final Swatch swatch, final Target target) {
    // Check whether the HSL values are within the correct ranges, and this color hasn't
    // been used yet.
    final List<double> hsl = swatch.hsl;
    return hsl[1] >= target.getMinimumSaturation() && hsl[1] <= target.getMaximumSaturation()
            && hsl[2] >= target.getMinimumLightness() && hsl[2] <= target.getMaximumLightness()
            && !_usedColors.containsKey(swatch.rgb);
  }

  double _generateScore(Swatch swatch, Target target) {
    final List<double> hsl = swatch.hsl;
    double saturationScore = 0.0;
    double luminanceScore = 0.0;
    double populationScore = 0.0;
    final int maxPopulation = _dominantSwatch != null ? _dominantSwatch.population : 1;
    if (target.getSaturationWeight() > 0) {
        saturationScore = target.getSaturationWeight()
                * (1.0 - (hsl[1] - target.getTargetSaturation()).abs());
    }
    if (target.getLightnessWeight() > 0) {
        luminanceScore = target.getLightnessWeight()
                * (1.0 - (hsl[2] - target.getTargetLightness()).abs());
    }
    if (target.getPopulationWeight() > 0) {
        populationScore = target.getPopulationWeight()
                * (swatch.population / maxPopulation);
    }
    return saturationScore + luminanceScore + populationScore;
  }


  static Swatch findDominantSwatch(List<Swatch> swatches) {
    int maxPop = INTEGER_MIN_VALUE;
    Swatch maxSwatch;
    for (int i = 0, count = swatches.length; i < count; i++) {
        Swatch swatch = swatches[i];
        if (swatch.population > maxPop) {
            maxSwatch = swatch;
            maxPop = swatch.population;
        }
    }
    return maxSwatch;
  }

  /*static List<double> _copyHslValues(Swatch color) {
    final List<double> newHsl = new List<double>(3);
    //System.arraycopy(color.hsl, 0, newHsl, 0, 3);
    List.copyRange(newHsl, 0, color.hsl);
    return newHsl;
  }*/
}


class Swatch {
  final int _red;
  final int _green;
  final int _blue;
  final Color _rgb;
  final int _population;

  bool _generatedTextColors;
  int _titleTextColor;
  int _bodyTextColor;


  List<double> _hsl;

  Swatch(this._rgb, this._population) :
    _red = _rgb.red,
    _green = _rgb.green,
    _blue = _rgb.blue;

  Swatch.fromRgb(this._red, this._green, this._blue, this._population) :
  _rgb = new Color.fromARGB(255, _red, _green, _blue);

  factory Swatch.fromHSL(List<double> hsl, int population) {
    Color color = new Color( ColorUtils.hslToColor(hsl) );
    return new Swatch(color, population);
  }

  int get rgb => _rgb.value;

  List<double> get hsl {
    if ( _hsl != null ){
      return _hsl;
    }
   if ( _rgb != null ) {
      _hsl = new List<double>.filled(3, 0.0);
      ColorUtils.colorToHSL(_rgb.value, _hsl);
      return _hsl;
    }
    return new List<double>.filled(3, 0.0);
  }

  int get population => _population;

  int get titleTextColor {
    _ensureTextColorsGenerated();
    return _titleTextColor; 
  }

  int get bodyTextColor {
    _ensureTextColorsGenerated();
    return _bodyTextColor;
  }


  void _ensureTextColorsGenerated() {
    if (_generatedTextColors == true ) {
      return;
    }
    
    // First check white, as most colors will be dark
    final int lightBodyAlpha = ColorUtils.calculateMinimumAlpha(
            ColorUtils.WHITE, _rgb.value, Palette.MIN_CONTRAST_BODY_TEXT);
    final int lightTitleAlpha = ColorUtils.calculateMinimumAlpha(
            ColorUtils.WHITE, _rgb.value, Palette.MIN_CONTRAST_TITLE_TEXT);
    if (lightBodyAlpha != -1 && lightTitleAlpha != -1) {
        // If we found valid light values, use them and return
        _bodyTextColor = ColorUtils.setAlphaComponent(ColorUtils.WHITE, lightBodyAlpha);
        _titleTextColor = ColorUtils.setAlphaComponent(ColorUtils.WHITE, lightTitleAlpha);
        _generatedTextColors = true;
        return;
    }

    final int darkBodyAlpha = ColorUtils.calculateMinimumAlpha(
            ColorUtils.BLACK, _rgb.value, Palette.MIN_CONTRAST_BODY_TEXT);
    final int darkTitleAlpha = ColorUtils.calculateMinimumAlpha(
            ColorUtils.BLACK, _rgb.value, Palette.MIN_CONTRAST_TITLE_TEXT);
    if (darkBodyAlpha != -1 && darkTitleAlpha != -1) {
        // If we found valid dark values, use them and return
        _bodyTextColor = ColorUtils.setAlphaComponent(ColorUtils.BLACK, darkBodyAlpha);
        _titleTextColor = ColorUtils.setAlphaComponent(ColorUtils.BLACK, darkTitleAlpha);
        _generatedTextColors = true;
        return;
    }
    
    // If we reach here then we can not find title and body values which use the same
    // lightness, we need to use mismatched values
    _bodyTextColor = lightBodyAlpha != -1
            ? ColorUtils.setAlphaComponent(ColorUtils.WHITE, lightBodyAlpha)
            : ColorUtils.setAlphaComponent(ColorUtils.BLACK, darkBodyAlpha);
    _titleTextColor = lightTitleAlpha != -1
            ? ColorUtils.setAlphaComponent(ColorUtils.WHITE, lightTitleAlpha)
            : ColorUtils.setAlphaComponent(ColorUtils.BLACK, darkTitleAlpha);
    _generatedTextColors = true;

  }

  String toString() {
    return " [RGB: 0x${this.rgb.toRadixString(16)} ]" + 
    " [HSL: ${this.hsl.toString()}" +
    " [Population: ${this.population} ]" +
    " [Title Text Color: 0x${this.titleTextColor.toRadixString(16)} ]" +
    " [Body Text Color: 0x${this.bodyTextColor.toRadixString(16)} ]";
  }

  @override
  int get hashCode => 31 * _rgb.value + _population;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is Swatch &&
              _population == other.population &&
              _rgb.value == other.rgb;

}


class Builder {

  List<Swatch> _swatches;
  final Bitmap _bitmap; 

  final List<Target> _targets = new List<Target>();

  int _maxColors = Palette.DEFAULT_CALCULATE_NUMBER_COLORS;
  int _resizeArea = Palette.DEFAULT_RESIZE_BITMAP_AREA;

  int _resizeMaxDimension = -1;

  final List<Filter> _filters = new List<Filter>();
  RECT.Rect _region;

  Builder(this._bitmap) {
    if( _bitmap == null  ) {  //|| _bitmap.isRecycled
      throw new ArgumentError("Bitmap is not valid.");
    }
  
    _filters.add(new Filter()); // add default filter;
    _swatches = null;

    // add default set of targets
    _targets.addAll([
      Target.MUTED,
      Target.VIBRANT,
      Target.DARK_MUTED,
      Target.LIGHT_MUTED,
      Target.DARK_VIBRANT,
      Target.LIGHT_VIBRANT,
    ]);
  }

  Builder maximumColorCount(int colors) {
    _maxColors = colors;
    return this;
  }

  Future<Palette> generate() async {
    
    List<Swatch> swatches;

    if (_bitmap == null){
      throw new ArgumentError("Called generate on a Builder with a null bitmap.");
    }

    final Bitmap bitmap = _scaleBitmapDown(_bitmap);
    final RECT.Rect region = _region;

    if( bitmap != _bitmap && region != null ) {
      // If we have a scaled bitmap, we need to scale down the region to match the new scale...
      final double scale = bitmap.width / _bitmap.width;
      region.left = (region.left * scale).floor();
      region.top = (region.top * scale).floor();
      region.right = Math.min((region.right * scale).ceil(),
              bitmap.width);
      region.bottom = Math.min((region.bottom * scale).ceil(),
              bitmap.height);
    }

    var pixelsFromBitmap = await Bitmap.getCopyAllPixels(bitmap); //await getPixelsFromBitmap(bitmap);
    
    ColorCutQuantizer quantizer = new ColorCutQuantizer(
      pixelsFromBitmap,
      _maxColors,
      _filters.isEmpty ? null : _filters.toList()
    );

    swatches = quantizer.quantizedColors;


    final Palette p = new Palette(swatches, _targets);

    p.generate();

    return p;
  }

  Future<List<int>> getPixelsFromBitmap(Bitmap bitmap) async {
    final int bitmapWidth = bitmap.width;
    final List<int> pixels = await Bitmap.getCopyAllPixels(bitmap);
    
    if ( _region == null ){
      return pixels;
    }

    final int regionWidth = _region.width;
    final int regionHeight = _region.height;
    // pixels contains all of the pixels, so we need to iterate through each row and
    // copy the regions pixels into a new smaller array
    final List<int> subsetPixels = new List<int>(regionWidth * regionHeight);
    for (int row = 0; row < regionHeight; row++) {
        //System.arraycopy(pixels, ((row + mRegion.top) * bitmapWidth) + mRegion.left,
        //        subsetPixels, row * regionWidth, regionWidth);
        List.copyRange(subsetPixels, row * regionWidth, pixels, ((row + _region.top) * bitmapWidth) + _region.left);        
    }
    return subsetPixels;
  }

  /*
   * Scale the bitmap down as needed.
   */
  Bitmap _scaleBitmapDown(final Bitmap bitmap) {
      double scaleRatio = -1.0;
      if (_resizeArea > 0) {
          final int bitmapArea = bitmap.width * bitmap.height;
          if (bitmapArea > _resizeArea) {
              scaleRatio = Math.sqrt(_resizeArea /bitmapArea);
          }
      } else if (_resizeMaxDimension > 0) {
          final int maxDimension = Math.max(bitmap.width, bitmap.height);
          if (maxDimension > _resizeMaxDimension) {
              scaleRatio = _resizeMaxDimension / maxDimension;
          }
      }
      if (scaleRatio <= 0) {
          // Scaling has been disabled or not needed so just return the Bitmap
          return bitmap;
      }
      return Bitmap.createScaledBitmap(bitmap,
              (bitmap.width * scaleRatio).ceil(),
              (bitmap.height * scaleRatio).ceil());
  }

}




abstract class IFilter {
  bool isAllowed(int rgb, List<double> hsl);
}

class Filter implements IFilter {
  static const double _BLACK_MAX_LIGHTNESS = 0.05;
  static const double _WHITE_MIN_LIGHTNESS = 0.95;

  Filter();

  @override
  bool isAllowed(int rgb, List<double> hsl) {
    return !_isWhite(hsl) && !_isBlack(hsl) && !_isNearRedILine(hsl);
  }

  bool _isBlack(List<double> hsl) {
    return hsl[2] <= _BLACK_MAX_LIGHTNESS;
  }

  bool _isWhite(List<double> hsl) {
    return hsl[2] >= _WHITE_MIN_LIGHTNESS;
  }

  bool _isNearRedILine(List<double> hsl) {
    return hsl[0] >= 10.0 && hsl[0] <= 37.0 && hsl[1] <= 0.82;
  }
}