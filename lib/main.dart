import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/services.dart' show rootBundle;
import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

class ColorsDetector extends StatelessWidget{
  ColorsDetector ({Key? key}):super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: 'Colors Picker', theme: ThemeData(primarySwatch: Colors.blue),
      home: MyColorPicker(title:'Colors Picker'),
    );
  }
}

class MyColorPicker extends StatefulWidget{
  MyColorPicker({Key? key,required String title}) :super(key: key);
  @override
  State<MyColorPicker> createState() => _MyColorPickerState();


}

class _MyColorPickerState extends State<MyColorPicker>{
  String imagePath = 'assets/ND.jpg';
  GlobalKey imageKey = GlobalKey();
  GlobalKey paintKey = GlobalKey();

  bool useSnapshot = true;


  GlobalKey? currentKey;

  final StreamController<Color> _stateController = StreamController<Color>();
  img.Image? photo;

  @override
  void initState() {
    currentKey = useSnapshot ? paintKey : imageKey;
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Colors Picker"),),
      body: StreamBuilder(
          initialData: Colors.green[500],
          stream: _stateController.stream,
          builder: (buildContext, snapshot) {
            Object selectedColor = snapshot.data ?? Colors.green;
            return Stack(
              children: <Widget>[
                RepaintBoundary(
                  key: paintKey,
                  child: GestureDetector(

                    onPanDown: (details) {
                      searchPixel(details.globalPosition);
                    },
                    onPanUpdate: (details) {
                      searchPixel(details.globalPosition);
                    },
                    child: Center(
                      child: Image.asset(
                        imagePath,
                        key: imageKey,
                        fit: BoxFit.cover,
                        //scale: .8,
                      ),
                    ),
                  ),
                ),
                Container(
                  margin: EdgeInsets.only(left: 115,top: 100),
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: selectedColor as dynamic,
                      border: Border.all(width: 2.0, color: Colors.white),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black12,
                            blurRadius: 4,
                            offset: Offset(0, 2))
                      ]),
                ),
                Container(
                  height: 32,
                  margin: EdgeInsets.only(left: 170,top: 110),
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                      boxShadow: [new BoxShadow(
                          color:selectedColor as dynamic ,
                          blurRadius: 5.0,blurStyle: BlurStyle.outer
                      ),]
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text('${selectedColor}', style: TextStyle(color: Colors.black54,fontWeight: FontWeight.bold)),
                  ),
                ),
                Container(
                    margin: EdgeInsets.only(top: 450,left: 35),
                    child: Text("Please Select Color From Image",style: TextStyle(color: Colors.black54,fontSize: 20,fontWeight: FontWeight.bold),)),
              ],
            );
          }),
    );
  }
  void searchPixel(Offset globalPosition) async {
    if (photo == null) {
      await (useSnapshot ? loadSnapshotBytes() : loadImageBundleBytes());
    }
    _calculatePixel(globalPosition);
  }
  Future<void> loadSnapshotBytes() async {
    // RenderBox? boxPaint = paintKey.currentContext!.findRenderObject() as RenderBox?;
    final RenderRepaintBoundary boxPaint=paintKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    ui.Image capture = await boxPaint.toImage();
    ByteData? imageBytes =
    await capture.toByteData(format: ui.ImageByteFormat.png);
    setImageBytes(imageBytes!);
    capture.dispose();
  }
  Future<void> loadImageBundleBytes() async {
    ByteData imageBytes = await rootBundle.load(imagePath);
    setImageBytes(imageBytes);
  }
  void _calculatePixel(Offset globalPosition) {
    RenderBox? box = currentKey!.currentContext!.findRenderObject() as RenderBox;
    Offset localPosition = box.globalToLocal(globalPosition);

    double px = localPosition.dx;
    double py = localPosition.dy;

    if (!useSnapshot) {
      double widgetScale = box.size.width / photo!.width;
      print(py);
      px = (px / widgetScale);
      py = (py / widgetScale);
    }

    int pixel32 = photo!.getPixelSafe(px.toInt(), py.toInt()) as int;
    int hex = abgrToArgb(pixel32);

    _stateController.add(Color(hex));
  }
  void setImageBytes(ByteData imageBytes) {
    List<int> values = imageBytes.buffer.asUint8List();
    Uint8List uint8List = Uint8List.fromList(values);
    photo = img.decodeImage(uint8List)!;
  }

}
int abgrToArgb(int argbColor) {
  int r = (argbColor >> 16) & 0xFF;
  int b = argbColor & 0xFF;
  return (argbColor & 0xFF00FF00) | (b << 16) | r;
}
