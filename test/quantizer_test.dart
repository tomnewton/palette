import "package:test/test.dart";
import "package:palette/src/palette.dart";
import "dart:io" as Io;
import "dart:ui";
import "dart:typed_data";
import "package:palette/src/bitmap.dart";
//import "package:flutter/painting.dart";

void main() {
  test("Test palette generation", () async {
    var bytes = new Io.File('test/data/nba.jpeg')
      .readAsBytesSync();
    var codec = await instantiateImageCodec(bytes); 
    var frameInfo = await codec.getNextFrame();
    var image = frameInfo.image;
    var bmp = new Bitmap(image);

    // var recorder = new PictureRecorder();
    // var canvas = new Canvas(recorder);
    // const rowWidth = 1000;

    // canvas.drawRect(new Rect.fromLTRB(0.0, 0.0, 1000.0, 500.0), new Paint()..color = new Color(0xFFFF0000));
    // canvas.drawRect(new Rect.fromLTRB(0.0, 501.0, 1000.0, 1000.0), new Paint()..color = new Color(0xFF00FF00));
    // canvas.drawRect(new Rect.fromLTRB(0.0, 1001.0, 1000.0, 1500.0), new Paint()..color = new Color(0xFF0000FF));
   
    // Picture pic = recorder.endRecording();
    // var bmp = new Bitmap(pic.toImage(rowWidth, 1500));
    var palette = await Palette.from(bmp).generate();

    var paletteBmp = await palette.render(200, 500);

    var p = palette.getLightVibrantColor(0x000000);
    
    //var cpy = await Bitmap.getCopyAllPixels(bmp);
    //var paletteBmp = Bitmap.copyResize(bmp, 200, 500);

    ByteData png = await paletteBmp.getPNGData();
    
    var d = new DateTime.now().toIso8601String();
    var output = new Io.File('test/data/output/output-$d.png');
    output.writeAsBytesSync(png.buffer.asUint8List());

  }); 


  // test("Test scale down bmp", () async {
  //   var bytes = new Io.File('test/data/mat.png')
  //     .readAsBytesSync();
  //   var codec = await instantiateImageCodec(bytes); 
  //   var frameInfo = await codec.getNextFrame();
  //   var image = frameInfo.image;
  //   var bmp = new Bitmap(image);
  //   var cpy = Bitmap.copyResize(bmp, 387, 233);

  //   ByteData png = await cpy.getPixels(format: ImageByteFormat.png);
    
  //   var d = new DateTime.now().toIso8601String();
  //   var output = new Io.File('test/data/output/output-$d.png');
  //   output.writeAsBytesSync(png.buffer.asUint8List());
  // });

  // test("Test Generate RED GREEN BLUE rectangle and write to disk",  () async {
  //   var recorder = new PictureRecorder();
  //   var canvas = new Canvas(recorder);
  //   //var px = new Uint32List(500000);
  //   //var bdata = new ByteData.view(px.buffer);
  //   const rowWidth = 1000;

  //   for ( var i = 0; i < 500000; i++ ){
  //     var y = (i / rowWidth).floor().toDouble();
  //     var x = ( i % rowWidth ).floor().toDouble();
  //     if ( i < 200000 ){ //RGBA
  //       //px[i] = 0xFFFF0000;
  //       canvas.drawRawPoints(PointMode.points, new Float32List.fromList([x, y]), new Paint()..color = new Color.fromARGB(255, 255, 0, 0));
  //       //bdata.setUint32(i, 0xFFFF0000, Endian.little) ; //red 
  //       continue;
  //     }
  //     if ( i < 400000 ) {
  //       //px[i] = 0xFF00FF00; // green 
  //       canvas.drawRawPoints(PointMode.points, new Float32List.fromList([x, y]), new Paint()..color = new Color.fromARGB(255, 0, 255, 0));
  //       continue;
  //     }
  //     if ( i < 500000 ) {
  //       //px[i] = 0xFF0000FF; // blue
  //       canvas.drawRawPoints(PointMode.points, new Float32List.fromList([x, y]), new Paint()..color = new Color.fromARGB(255, 0, 0, 255));
  //       continue;
  //     }
  //   } 


  //   Picture pic = recorder.endRecording();

  //   var bmp = new Bitmap(pic.toImage(1000, 500));
  //   var cpy = Bitmap.copyResize(bmp, 387, 233);
  //   ByteData png = await cpy.getPixels(format: ImageByteFormat.png);
    
  //   var d = new DateTime.now().toIso8601String();
  //   var output = new Io.File('test/data/output/output-$d.png');
  //   output.writeAsBytesSync(png.buffer.asUint8List());
  // });

  

  /*test("Test quanization of a color", () {
    var color = 0xFFFF0000;

    var quant = ColorCutQuantizer.quantizeFromRgb888(color);
    var out = ColorCutQuantizer.approximateToRgb888(quant);

    expect(out, equals(color));
  });*/

  /*test("Test RGBA to ARGB", () {
    var RGBA = 0x11223344;
    var ARGB = Bitmap.rgbaToARGB(RGBA);

    expect(0x44, equals(ARGB >> 24));
    expect(0x44112233, equals(ARGB));
  });*/
}