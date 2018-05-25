import "package:test/test.dart";
import "package:palette/src/palette.dart";
import "dart:ui";
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
    /*var bytes = new Io.File('test/data/nba.jpeg')
      .readAsBytesSync();
    var codec = await instantiateImageCodec(bytes); 
    var frameInfo = await codec.getNextFrame();
    var image = frameInfo.image;
    var bmp = new Bitmap(image);*/

    var recorder = new PictureRecorder();
    var canvas = new Canvas(recorder);
    const rowWidth = 1000;

    canvas.drawRect(new Rect.fromLTRB(0.0, 0.0, 1000.0, 500.0), new Paint()..color = new Color(0xFFFF0000));
    canvas.drawRect(new Rect.fromLTRB(0.0, 501.0, 1000.0, 1000.0), new Paint()..color = new Color(0xFF00FF00));
    canvas.drawRect(new Rect.fromLTRB(0.0, 1001.0, 1000.0, 1500.0), new Paint()..color = new Color(0xFF0000FF));
   
    Picture pic = recorder.endRecording();
    var bmp = new Bitmap(pic.toImage(rowWidth, 1500));
    var palette = await Palette.from(bmp).generate();


    expect(palette.getSwatches().length, equals(3));

    // Uncomment the blew to render the palette swatch rgb values 
    // rendered to PNG format so and written to disk. 
    // helpful for visually debugging. 

    /*var paletteBmp = await palette.render(200, 500);
    ByteData png = await paletteBmp.getPNGData();
    var d = new DateTime.now().toIso8601String();
    var output = new Io.File('test/data/output/output-$d.png');
    output.writeAsBytesSync(png.buffer.asUint8List());*/

  }); 
}