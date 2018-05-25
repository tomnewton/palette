import "dart:ui";
import "dart:io" as Io;
import "package:palette/palette.dart";

main() async {
  const INPUT_IMAGE = "45th.png";

  var bytes = new Io.File(INPUT_IMAGE)
    .readAsBytesSync();

  var codec = await instantiateImageCodec(bytes); 
  var frameInfo = await codec.getNextFrame();
  var image = frameInfo.image;
  var bmp = new Bitmap(image);
  var palette = await Palette.from(bmp).generate();

  print(palette.toString());
}
