import "package:test/test.dart";
import "package:palette/src/palette.dart";
import "dart:ui";
import "dart:typed_data";
import "dart:io" as Io;
import "package:palette/src/color_utils.dart";
import "package:palette/src/bitmap.dart";

main(){
  test("Test lighter/darker", (){
    var testColor = new Color( 0xfff07c0f );
    var swatch = new Swatch(testColor, 1000);

    var tempHsl = new List<double>.filled(3, 0.0);
    ColorUtils.colorToHSL(testColor.value, tempHsl);

    // Test we get roughly the colours we're looking for. 
    expect(swatch[100].value, equals(0xFFFFFFFF));
    expect(swatch[65].value, equals(0xfff4a357));
    expect(swatch[30].value, equals(0xff904a09));
    expect(swatch[0].value, equals(0xFF000000));
  });


  test("Test palette generation", () async {
    var recorder = new PictureRecorder();
    var canvas = new Canvas(recorder);
    const rowWidth = 1000;

    canvas.drawRect(new Rect.fromLTRB(0.0, 0.0, 1000.0, 500.0), new Paint()..color = new Color(0xFFFF0000));
    canvas.drawRect(new Rect.fromLTRB(0.0, 501.0, 1000.0, 1000.0), new Paint()..color = new Color(0xFF00FF00));
    // paint more blue to make our dominant swatch blue, and test below.
    canvas.drawRect(new Rect.fromLTRB(0.0, 1001.0, 1000.0, 1600.0), new Paint()..color = new Color(0xFF0000FF)); 
   
    Picture pic = recorder.endRecording();
    var bmp = new Bitmap(pic.toImage(rowWidth, 1600));
    var palette = await Palette.from(bmp).generate();

    expect(palette.getSwatches().length, equals(3));

    var blueSwatch = palette.getSwatches()[0];
    var greenSwatch = palette.getSwatches()[1];
    var redSwatch = palette.getSwatches()[2];

    var blueColor = new Color(blueSwatch.rgb);
    expect(blueColor.blue, greaterThan(247)); // we apprixmate back to rgb888, so there is some loss.
    expect(blueColor.red, equals(0));
    expect(blueColor.green, equals(0));

    var greenColor = new Color(greenSwatch.rgb);
    expect(greenColor.green, greaterThan(247));
    expect(greenColor.red, equals(0));
    expect(greenColor.blue, equals(0));

    var redColor = new Color(redSwatch.rgb);
    expect(redColor.red, greaterThan(247));
    expect(redColor.green, equals(0));
    expect(redColor.blue, equals(0));

    // get the dominant swatch - it should be blue, because we 
    // have painted more blue pixels in the image above.
    var dominant = palette.getDominantSwatch();
    // should be blue
    expect(new Color(dominant.rgb).blue, greaterThan(247));
  }); 

  test('Output colors to disk', () async {
    const OUTPUT_FOLDER = "test/data/output/";
    const INPUT_IMAGE = "test/data/crimetown.jpeg";

    var bytes = new Io.File(INPUT_IMAGE)
      .readAsBytesSync();
    var codec = await instantiateImageCodec(bytes); 
    var frameInfo = await codec.getNextFrame();
    var image = frameInfo.image;
    var bmp = new Bitmap(image);
    var palette = await Palette.from(bmp).generate();
    var paletteBmp = await palette.render(200, 500);
    ByteData png = await paletteBmp.getPNGData();
    
    var filename = "SwatchColors-${new DateTime.now().toIso8601String()}.png";
    var output = new Io.File('$OUTPUT_FOLDER$filename');
    output.writeAsBytesSync(png.buffer.asUint8List());
  }, skip: "This is for visually debugging generated Swatches of a Palette from an image.");
}