import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:mask_detector/face_detection_camera.dart';
import 'package:tflite/tflite.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_share/flutter_share.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_admob/firebase_admob.dart';
void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mask detector',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
bool _loading;
List _outputs;
File _image;
int count=0;
InterstitialAd interstitialAd;
void initState() {
    super.initState();
    FirebaseAdMob.instance.initialize(appId: 'ca-app-pub-8295782880270632~3798840407');
    interstitialAd = myInterstitial()..load();
    _loading = true;
    loadModel().then((value) {
      setState(() {
        _loading = false;
      });
    });
}
static MobileAdTargetingInfo targetingInfo = MobileAdTargetingInfo(
  keywords: <String>['apps', 'games', 'news'], // or MobileAdGender.female, MobileAdGender.unknown
  testDevices: <String>[], // Android emulators are considered test devices
);

InterstitialAd myInterstitial() {
    return InterstitialAd(
      adUnitId: 'ca-app-pub-8295782880270632/9789533681',
      targetingInfo: targetingInfo,
      listener: (MobileAdEvent event) {
        if (event == MobileAdEvent.failedToLoad) {
          interstitialAd..load();
        } else if (event == MobileAdEvent.closed) {
          interstitialAd = myInterstitial()..load();
        }
      },
    );
  }
@override
void dispose() {
    interstitialAd?.dispose();
    super.dispose();
}
Future<void> share() async {
  await FlutterShare.share(
    title: 'Hey,I found out a great app!',
    text: 'Use this app to detect mask in photos/selfies. This app is really awesome.',
    linkUrl: 'https://insaniti.com/',
    chooserTitle: 'Hey,I found out a great app!'
  );
}
loadModel() async {
    await Tflite.loadModel(
      model: "assets/model_unquant.tflite",
      labels: "assets/labels.txt",
    );
}
pickImage() async {
      count++;
      print(count);
    var image = await ImagePicker.pickImage(source:ImageSource.gallery);
    if (image == null) return null;
    setState(() {
      _loading = true;
      //Declare File _image in the class which is used to display the image on the screen. 
      _image = image; 
    });
    classifyImage(image);
  }
classifyImage(File image) async {
    var output = await Tflite.runModelOnImage(
      path: image.path,
      numResults: 1,
      threshold: 0.5,
      imageMean: 127.5,
      imageStd: 127.5,
    );
    setState(() {
      _loading = false;
      //Declare List _outputs in the class which will be used to show the classified classs name and confidence
      _outputs = output;

        if(count.isOdd)
      { print('hey');
        interstitialAd
          ..load()
          ..show();
      }
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: Drawer(
       child: Container(
         decoration: new BoxDecoration(
             image: new DecorationImage(
               image: new AssetImage("assets/backapp.jpg"),
               fit: BoxFit.cover,
             )),
         child: ListView(
            padding: EdgeInsets.only(top:20),
            children: <Widget>[
              DrawerHeader(
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  image: DecorationImage(
                    image: AssetImage("assets/mask.jpg"),
                     fit: BoxFit.cover),
                ),

              ),
              ListTile(
               title: Text('View More',style: TextStyle(fontSize:20,color: Colors.black38),),
               leading: Icon(Icons.control_point,size: 40,color: Colors.redAccent,),
               onTap: () {
                 launch('https://insaniti.com/');
               },
              ),
            ],
          ),
       ),
      ),
      appBar: AppBar(
        title:Text("Mask detector"),
        centerTitle: true,
        backgroundColor: Colors.redAccent,),

        floatingActionButton: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            FloatingActionButton(
              heroTag: null,
              onPressed:()=> pickImage(),
              child: Icon(Icons.image),
            ),
            SizedBox(width:10),
            FloatingActionButton(
              heroTag: null,
              onPressed:(){Navigator.push(context, MaterialPageRoute(builder: (BuildContext context){return FaceDetectionFromLiveCamera();}));},
              child: Icon(Icons.camera),
            ),
          ],
        ),
      
      body: _loading
          ? Container(
        decoration: new BoxDecoration(
            image: new DecorationImage(
              image: new AssetImage("assets/backimage.jpg"),
              fit: BoxFit.cover,
            )),
              alignment: Alignment.center,
              child: CircularProgressIndicator(),
            )
          : Container(
    decoration: new BoxDecoration(
    image: new DecorationImage(
    image: new AssetImage("assets/backimage.jpg"),
    fit: BoxFit.cover,
    )),

              width: MediaQuery.of(context).size.width,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _image == null ? Container() : Image.file(_image,fit: BoxFit.contain,height:MediaQuery.of(context).size.height*0.6),
                  SizedBox(
                    height: 10,
                  ),
                  if (_outputs != null) Column(
                        children: <Widget>[
                          Text(
                              _outputs[0]["label"]=='0 with_mask'?"Mask detected":"Mask not detected",
                              style: TextStyle(
                                color: _outputs[0]["label"]=='0 with_mask'?Colors.green:Colors.red,
                                fontSize: 25.0,
                              ),
                            ),
                          Text("${(_outputs[0]["confidence"]*100).toStringAsFixed(0)}%",style: TextStyle(color:Colors.purpleAccent,fontSize:20),)
                        ],
                      ) else Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: <Widget>[
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text("Choose a photo from gallery or use the live camera feed to detect face mask",style: TextStyle(fontSize:20,fontWeight:FontWeight.w500,color: Colors.black),textAlign: TextAlign.center,),
                            ),

                            Container(
                                child:  Image( width: 190,
                                  height: 100,
                                  image: AssetImage("assets/insanityname.png"),
                                  )),
                            Container(
                                child:  Image(
                                  image: AssetImage("assets/logo.png"),
                                  width: 200,
                                  height: 200,)),
                            SizedBox(height:20),

                            Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: Text("Note:the input photo must have a CLOSE face & the model is not 100% correct",style:TextStyle(color: Colors.red,fontSize: 20),textAlign: TextAlign.center,),
                            )
                          ],
                        ),
                      )
                ],
              ),
            )

    );



  }


}