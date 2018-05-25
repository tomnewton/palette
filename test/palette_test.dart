import "package:test/test.dart";
import "package:palette/src/palette.dart";
import "dart:ui";

main(){
  test("Test lighter/darker", (){
    var testColor = new Color( 0xfff07c0f );
    var swatch = new Swatch(testColor, 1000);
    expect(swatch[100], equals(0xFFFFFFFF));
    expect(swatch[95], equals(0xfffdf2e7));
    expect(swatch[65], equals(0xfff4a357));
    expect(swatch[45], equals(0xffd86f0e));
    expect(swatch[30], equals(0xff904a09));
    expect(swatch[0], equals(0xFF000000));
  });
}