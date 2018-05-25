class Target {
  static const double TARGET_DARK_LUMA = 0.26;
  static const double MAX_DARK_LUMA = 0.45;
  static const double MIN_LIGHT_LUMA = 0.55;
  static const double TARGET_LIGHT_LUMA = 0.74;
  static const double MIN_NORMAL_LUMA = 0.3;
  static const double TARGET_NORMAL_LUMA = 0.5;
  static const double MAX_NORMAL_LUMA = 0.7;
  static const double TARGET_MUTED_SATURATION = 0.3;
  static const double MAX_MUTED_SATURATION = 0.4;
  static const double TARGET_VIBRANT_SATURATION = 1.0;
  static const double MIN_VIBRANT_SATURATION = 0.35;
  static const double WEIGHT_SATURATION = 0.24;
  static const double WEIGHT_LUMA = 0.52;
  static const double WEIGHT_POPULATION = 0.24;
  static const int INDEX_MIN = 0;
  static const int INDEX_TARGET = 1;
  static const int INDEX_MAX = 2;
  static const int INDEX_WEIGHT_SAT = 0;
  static const int INDEX_WEIGHT_LUMA = 1;
  static const int INDEX_WEIGHT_POP = 2;


  /*
   * A target which has the characteristics of a vibrant color which is light in luminance.
  */
  static final Target LIGHT_VIBRANT = new Target.lightVibrant();
  /*
   * A target which has the characteristics of a vibrant color which is neither light or dark.
   */
  static final Target VIBRANT = new Target.vibrant();
  /*
   * A target which has the characteristics of a vibrant color which is dark in luminance.
   */
  static final Target DARK_VIBRANT = new Target.darkVibrant();
  /*
   * A target which has the characteristics of a muted color which is light in luminance.
   */
  static final Target LIGHT_MUTED = new Target.lightMuted();
  /*
   * A target which has the characteristics of a muted color which is neither light or dark.
   */
  static final Target MUTED = new Target.muted();
  /*
   * A target which has the characteristics of a muted color which is dark in luminance.
   */
  static final Target DARK_MUTED = new Target.darkMuted();

  final List<double> mSaturationTargets = new List<double>(3);
  final List<double> mLightnessTargets = new List<double>(3);
  final List<double> mWeights = new List<double>(3);
  bool mIsExclusive = false; // default to true

  Target(){
    _setTargetDefaultValues(mSaturationTargets);
    _setTargetDefaultValues(mLightnessTargets);
    _setDefaultWeights();
  }

  factory Target.lightVibrant(){
    Target target = new Target();
    _setDefaultLightLightnessValues(target);
    _setDefaultVibrantSaturationValues(target);
    return target;
  }

  factory Target.vibrant(){
    Target target = new Target();
    _setDefaultNormalLightnessValues(target);
    _setDefaultVibrantSaturationValues(target);
    return target;
  }

  factory Target.darkVibrant(){
      Target target = new Target();
      _setDefaultDarkLightnessValues(target);
      _setDefaultVibrantSaturationValues(target);
      return target;
  }

  factory Target.lightMuted(){
    Target target = new Target();
    _setDefaultLightLightnessValues(target);
    _setDefaultMutedSaturationValues(target);
    return target;
  }

  factory Target.muted(){
    Target target = new Target();
    _setDefaultNormalLightnessValues(target);
    _setDefaultMutedSaturationValues(target);
    return target;
  }

  factory Target.darkMuted(){
    Target target = new Target();
    _setDefaultDarkLightnessValues(target);
    _setDefaultMutedSaturationValues(target);
    return target;
  }

  /*
    * The minimum saturation value for this target.
    */
  ////@doubleRange(from = 0, to = 1)
  double getMinimumSaturation() {
      return mSaturationTargets[INDEX_MIN];
  }
  /*
    * The target saturation value for this target.
    */
  //@doubleRange(from = 0, to = 1)
  double getTargetSaturation() {
      return mSaturationTargets[INDEX_TARGET];
  }
  /*
    * The maximum saturation value for this target.
    */
  //@doubleRange(from = 0, to = 1)
  double getMaximumSaturation() {
      return mSaturationTargets[INDEX_MAX];
  }
  /*
    * The minimum lightness value for this target.
    */
  //@doubleRange(from = 0, to = 1)
  double getMinimumLightness() {
      return mLightnessTargets[INDEX_MIN];
  }
  /*
    * The target lightness value for this target.
    */
  //@doubleRange(from = 0, to = 1)
  double getTargetLightness() {
      return mLightnessTargets[INDEX_TARGET];
  }
  /*
    * The maximum lightness value for this target.
    */
  //@doubleRange(from = 0, to = 1)
  double getMaximumLightness() {
      return mLightnessTargets[INDEX_MAX];
  }
  /*
    * Returns the weight of importance that this target places on a color's saturation within
    * the image.
    *
    * <p>The larger the weight, relative to the other weights, the more important that a color
    * being close to the target value has on selection.</p>
    *
    * @see #getTargetSaturation()
    */
  double getSaturationWeight() {
      return mWeights[INDEX_WEIGHT_SAT];
  }
  /*
    * Returns the weight of importance that this target places on a color's lightness within
    * the image.
    *
    * <p>The larger the weight, relative to the other weights, the more important that a color
    * being close to the target value has on selection.</p>
    *
    * @see #getTargetLightness()
    */
  double getLightnessWeight() {
      return mWeights[INDEX_WEIGHT_LUMA];
  }
  /*
    * Returns the weight of importance that this target places on a color's population within
    * the image.
    *
    * <p>The larger the weight, relative to the other weights, the more important that a
    * color's population being close to the most populous has on selection.</p>
    */
  double getPopulationWeight() {
      return mWeights[INDEX_WEIGHT_POP];
  }
  /*
    * Returns whether any color selected for this target is exclusive for this target only.
    *
    * <p>If false, then the color can be selected for other targets.</p>
    */
  bool isExclusive() {
      return mIsExclusive;
  }
  static void _setTargetDefaultValues(final List<double> values) {
      values[INDEX_MIN] = 0.0;
      values[INDEX_TARGET] = 0.5;
      values[INDEX_MAX] = 1.0;
  }
  void _setDefaultWeights() {
      mWeights[INDEX_WEIGHT_SAT] = WEIGHT_SATURATION;
      mWeights[INDEX_WEIGHT_LUMA] = WEIGHT_LUMA;
      mWeights[INDEX_WEIGHT_POP] = WEIGHT_POPULATION;
  }
  void normalizeWeights() {
      double sum = 0.0;
      for (int i = 0, z = mWeights.length; i < z; i++) {
          double weight = mWeights[i];
          if (weight > 0) {
              sum += weight;
          }
      }
      if (sum != 0) {
          for (int i = 0, z = mWeights.length; i < z; i++) {
              if (mWeights[i] > 0) {
                  mWeights[i] /= sum;
              }
          }
      }
  }

  static void _setDefaultDarkLightnessValues(Target target) {
      target.mLightnessTargets[INDEX_TARGET] = TARGET_DARK_LUMA;
      target.mLightnessTargets[INDEX_MAX] = MAX_DARK_LUMA;
  }
  static void _setDefaultNormalLightnessValues(Target target) {
      target.mLightnessTargets[INDEX_MIN] = MIN_NORMAL_LUMA;
      target.mLightnessTargets[INDEX_TARGET] = TARGET_NORMAL_LUMA;
      target.mLightnessTargets[INDEX_MAX] = MAX_NORMAL_LUMA;
  }
  static void _setDefaultLightLightnessValues(Target target) {
      target.mLightnessTargets[INDEX_MIN] = MIN_LIGHT_LUMA;
      target.mLightnessTargets[INDEX_TARGET] = TARGET_LIGHT_LUMA;
  }
  static void _setDefaultVibrantSaturationValues(Target target) {
      target.mSaturationTargets[INDEX_MIN] = MIN_VIBRANT_SATURATION;
      target.mSaturationTargets[INDEX_TARGET] = TARGET_VIBRANT_SATURATION;
  }
  static void _setDefaultMutedSaturationValues(Target target) {
      target.mSaturationTargets[INDEX_TARGET] = TARGET_MUTED_SATURATION;
      target.mSaturationTargets[INDEX_MAX] = MAX_MUTED_SATURATION;
  }
}