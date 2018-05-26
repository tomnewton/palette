import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:palette/palette.dart';

void main() async {
  // Here is a basic example //

  // Before you start - have a look in the assets directory
  // at the two images. We load both and build palettes from them 
  // below. 

  // You can use the floating action button to swap between them.

  // You can load an arbitrary png / jpeg etc...
  //ByteData byteData = await rootBundle.load("assets/lol.png");
  ByteData byteData = await rootBundle.load("assets/habitat.png");

  // Pass it to the fromRawData method 
  var palette = await Palette.generateFromRawData(byteData.buffer.asUint8List());

  // There are other ways to do this if you want more control. 
  // See Palette.from(Bitmap bmp) which takes a Bitmap.
  // var bmp = await Bitmap.from(byteData.buffer.asUint8List());
  // var builder = Palette.from(bmp).setMaxColors(8);
  // then call generate() when ready.

  // Below we grab a swatch of the dominant color and apply it to the theme.
  // We also render a bunch of colors so you can see all of the swatch 
  // colors and also, the colors for the default 'Targets'. 


  // Targets put some constraints on the type of colour you're looking for 
  // in an image based on lightness, saturation, and population ( frequency in the image).
  // You can also weight the importance of each and define a range for each.

  // Creating a second for demo purposes.
  ByteData data = await rootBundle.load("assets/lol.png");
  var paletteTwo = await Palette.generateFromRawData(data.buffer.asUint8List());

  runApp(new MyApp(palette, paletteTwo));
}

class MyApp extends StatelessWidget {
  final Palette palette;
  final Palette paletteTwo;

  MyApp(this.palette, this.paletteTwo, {Key key}) : super(key:key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    var dominantSwatch = this.palette.getDominantSwatch();
    return new MaterialApp(
      title: 'Flutter Demo',
      theme: new ThemeData(
        // You can easily make a MaterialColor from a Swatch.
        primarySwatch: new MaterialColor(dominantSwatch.rgb.value, dominantSwatch.toMaterialSwatch()),
      ),
      home: new MyHomePage(title: 'Palette Demo', palette: palette, paletteTwo: paletteTwo),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title, this.palette, this.paletteTwo}) : super(key: key);

  final String title;
  final Palette palette;
  final Palette paletteTwo;

  @override
  _MyHomePageState createState() => new _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {


  Palette currentPalette;

  @override initState() {
    super.initState();
    currentPalette = widget.palette;
  }

  void _changePalette() {
    setState((){
      currentPalette = currentPalette == widget.palette ? widget.paletteTwo : widget.palette;
    });
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text(widget.title),
      ),
      body: new Center(
        child: new Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            new Text(
              'Colors extracted from the png.\n Common -> Less Common',
              style: Theme.of(context).textTheme.headline,
            ),
             new Row(
               mainAxisSize: MainAxisSize.max,
              children: _buildSwatches(),
            ),
            new Container(height:70.0),
            _buildTargets(),
          ],
        ),
      ),
      floatingActionButton: new FloatingActionButton(
        backgroundColor: Theme.of(context).accentColor,
        onPressed: _changePalette,
        tooltip: 'Increment',
        child: new Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  List<Widget> _buildSwatches() {
    var squares = <Widget>[];
    var swatches = currentPalette.getSwatches();
    for ( Swatch s in  swatches ) {
      squares.add(
        new Expanded(
          child: new Container(
            color: s.rgb,
            height: 50.0,
          ),
        )
      );
    }
    return squares;
  }


  Column _buildTargets() {
    var squares = <Widget>[];

    // For each image you won't necessarily have colours for each
    // target. 

    // In the asset bundle, habitat.png has a colour for each target except
    // it doesn't contain a darkMuted color as defined by the default Target.DARK_MUTED 
    // target.
    // 
    // If you load the lol.png instead, you'll see it is missing a few more
    // due to the nature of the image.

    // fallback if we don't have a color for the Target.
    var defaultColor = Colors.white; 

    // You'll always have a dominant color, because that is simply 
    // the most common color in the given image.
    var dominant = currentPalette.getDominantSwatch().rgb;

    // You can get shades of the dominant target by getting a
    // reference to the Swatch s; then use s[0:100] to change the luminosity
    // as done below, e.g. dominantSwatch[30].
    var dominantSwatch = currentPalette.getDominantSwatch();

    // You can also call swatch.toMaterialSwatch() which you can then use to make a 
    // MaterialColor(swatch.rgb, swatch.toMaterialSwatch());

    var lightVibrant = currentPalette.getLightVibrantColor(defaultColor);
    var vibrant = currentPalette.getVibrantColor(defaultColor);
    var darkVibrant = currentPalette.getDarkVibrantColor(defaultColor);
    
    var lightMuted = currentPalette.getLightMutedColor(defaultColor);
    var muted = currentPalette.getMutedColor(defaultColor);
    var dartkMuted = currentPalette.getDarkMutedColor(defaultColor);

    const height = 50.0;

    return new Column(
      children: <Widget>[
      new Text("Dominant Color",
        style: Theme.of(context).textTheme.headline,
      ),
      new Row(
        mainAxisSize: MainAxisSize.max,
        children: <Widget>[
          new Expanded(
            child: new Container(
              color: dominant,
              height: height,
            ), 
          )],
      ),
      new Text("Shades of the Dominant Swatch",
        style: Theme.of(context).textTheme.headline
      ),
      new Row(
        mainAxisSize: MainAxisSize.max,
        children: <Widget>[
          new Expanded(
            child: new Container(
              color: dominantSwatch[15],
              height: height,
            ), 
          ),
          new Expanded(
            child: new Container(
              color: dominantSwatch[30],
              height: height,
            ), 
          ),
          new Expanded(
            child: new Container(
              color: dominantSwatch[50],
              height: height,
            ), 
          ),
          new Expanded(
            child: new Container(
              color: dominantSwatch[65],
              height: height,
            ), 
          ),
          new Expanded(
            child: new Container(
              color: dominantSwatch[80],
              height: height,
            ), 
          ),
        ],
      ),
      new Text(
        "Vibrants",
        style: Theme.of(context).textTheme.headline,
      ),
      new Row(
        mainAxisSize: MainAxisSize.max,
        children: <Widget>[
          new Expanded(
            child: new Container(
              color: darkVibrant,
              height: height,
            ), 
          ),
          new Expanded(
            child: new Container(
              color: vibrant,
              height: height,
            ), 
          ),
          new Expanded(
            child: new Container(
              color: lightVibrant,
              height: height,
            ), 
          ),
        ],
      ),
      
      new Text("Muted",
        style: Theme.of(context).textTheme.headline,
      ),
      new Row(
        mainAxisSize: MainAxisSize.max,
        children: <Widget>[
          new Expanded(
            child: new Container(
              color: dartkMuted,
              height: height,
            ), 
          ),
          new Expanded(
            child: new Container(
              color: muted,
              height: height,
            ), 
          ),
          new Expanded(
            child: new Container(
              color: lightMuted,
              height: height,
            ), 
          ),
        ],
      )
    ]);
  }
}
