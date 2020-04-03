import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_amazon_s3/flutter_amazon_s3.dart';
import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:loading/indicator/ball_pulse_indicator.dart';
import 'package:loading/loading.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nice_button/nice_button.dart';




void main() => runApp(MyApp());

class MyApp extends StatelessWidget {// This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.red,
      ),
      home: StartPage(title: 'Emegency Ron'),
    );
  }
}

var images = [Image.asset('assets/images/Face.png')];
var quotes = [];
var packs = new List<PopupMenuEntry>();
var packsLocation = [];

class loadingScreenState extends State<loadingScreen> {
  var httpClient = new HttpClient();

  //downloads file
  _downloadFile(String url, String name) async {
    print("starting download");
    String filename = name + '.zip';
    var request = await httpClient.getUrl(Uri.parse(url));
    print("request");
    var response = await request.close();
    print("response");
    var bytes = await consolidateHttpClientResponseBytes(response);
    print("bytes"); // takes a very long time ~ 1 min
    String dir = (await getApplicationDocumentsDirectory()).path;
//    File file = new File('$dir/$filename');
//    await file.writeAsBytes(bytes);
    Map<String, dynamic> packInfo = await unzip(bytes, name);
    packInfo['packPath'] = dir + "/" + name;
    await loadFaces(packInfo);
    await loadQuotes(packInfo);
    await updateList(packInfo);
    print("pushing context");
    await addBoolToSF(true);
    await loadList();
    Navigator.push(
      context,
      new MaterialPageRoute(builder: (context) => new MyHomePage(title: packInfo['name'])),
    );
  }

  loadAll() async {
    final directory = await getApplicationDocumentsDirectory();
    String packPath = directory.path + "/" + widget.title + '/';
    Map<String, dynamic> packInfo = json.decode(await File(packPath + 'packInfo.json').readAsString());
    packInfo['packPath'] = directory.path + "/" + widget.title;
    await loadFaces(packInfo);
    await loadQuotes(packInfo);
    loadList();
    Navigator.push(
      context,
      new MaterialPageRoute(builder: (context) => new MyHomePage(title: packInfo['name'])),
    );
  }
  
  void updateList(Map<String, dynamic> packInfo) async{
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var list = prefs.getStringList("list");
    var newList = new List<String>();
    
    if(list != null){
      for(int i = 0; i <list.length; i++){
        newList.add(list[i]);
      }
    }
    newList.add(packInfo['name']);
    prefs.setStringList("list", newList);
  }

  void loadList() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var list = prefs.getStringList("list");

    if(list != null) {
      packs.clear();
      packsLocation.clear();
      for(int i = 0; i < list.length; i++){
        packsLocation.add(list[i]);
        packs.add(
          new PopupMenuItem(
            value: i,
            child: Row(
              children: <Widget>[
                Text(list[i], style: TextStyle(fontWeight: FontWeight.bold),),
              ],
            )
        ),
        );
      }
    }

    packs.add(PopupMenuItem(
        value: 10000000,
        child: Row(
          children: <Widget>[
            Icon(Icons.arrow_back, color: Colors.black, size: 20,),
            Text("Return", style: TextStyle(fontWeight: FontWeight.bold),),
          ],
        )
    )
    );
  }

  void loadFaces(Map<String, dynamic> packInfo) async {
    images.clear();
    for (final file in packInfo['faces']) {
      images.add(Image.file(new File(packInfo['packPath'] + file)));
    }
  }

  void loadQuotes(Map<String, dynamic> packInfo) async {
    quotes.clear();
    for (final file in packInfo['quotes']) {
      print(await new File(packInfo['packPath'] + file[0]).readAsString());
      quotes.add(new Quote(await new File(packInfo['packPath'] + file[0]).readAsString(), packInfo['packPath'] + file[1]));
    }
  }


  Future<Map<String, dynamic>> unzip(List<int> bytes, String name) async {
    final directory = await getApplicationDocumentsDirectory();

    String packPath = directory.path + "/" + name + '/';

    final archive = ZipDecoder().decodeBytes(bytes);
    for (final file in archive) {
      final filename = file.name;
      if (file.isFile) {
        final data = file.content as List<int>;
        File(packPath + filename)
          ..createSync(recursive: true)
          ..writeAsBytesSync(data);
      } else {
        Directory(packPath + filename)
          ..create(recursive: true);
      }
    }
    return json.decode(await File(packPath + 'packInfo.json').readAsString());
  }

  Future<bool> getBoolValuesSF() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    //Return bool
    print('isPackDownloaded ' + widget.title);
    bool boolValue = prefs.getBool('isPackDownloaded ' + widget.title);
    return boolValue;
  }

  addBoolToSF(bool isPackDownloaded) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    print("adding "+ isPackDownloaded.toString() + "to");
    print('isPackDownloaded ' + widget.title);
    prefs.setBool('isPackDownloaded ' + widget.title, isPackDownloaded);
  }

  bool isDone = false;

  @override
  void initState () {
    super.initState();
    Future<bool> future = Future.delayed(
      Duration(seconds: 1),
          () => getBoolValuesSF(),
    );

    future.then((future) {
      print(future.toString());
      if (future == null) {
        _downloadFile("https://guid-bucket.s3.us-east-2.amazonaws.com/" + widget.title +".zip", widget.title);
      }
      else {
        loadAll();
      }
    });
  }

  @override
  Widget build (BuildContext context) {
    return new Scaffold(
        body: Container(
            color: Colors.white,
            child: Center(
                child: Column(
                  children: <Widget>[
                    Loading(indicator: BallPulseIndicator(), size: 100.0, color: Colors.red,),
                    Text("Loading . . .", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 35),),
                  ],
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                )
            )
        )
    );
  }
}

class loadingScreen extends StatefulWidget {
  loadingScreen({Key key, this.title}) : super(key: key);

  final String title;
  @override
  loadingScreenState createState() => loadingScreenState();
}

class StartPageState extends State<StartPage> {
  Future<String> getStringValuesSF() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    //Return String
    String stringValue = prefs.getString('guid');
    return stringValue;
  }
  @override
  void initState (){
    super.initState();
    Future<String> future = Future.delayed(
      Duration(seconds: 2),
          () => getStringValuesSF(),
    );

    future.then((future) {
      if(future == null) {
        Navigator.push(
          context,
          new MaterialPageRoute(builder: (context) => new CreatePage(title: 'Emegency Ron')),
        );
        //push to create
        //TODO
      }
      else {
        Navigator.push(
          context,
          new MaterialPageRoute(builder: (context) => new loadingScreen(title: future)),
        );
      }
    });
  }

  Widget build (BuildContext context) {
    return new Scaffold(
        body: Container(
            color: Colors.white,
            child: Center(
                child: Column(
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Text("L", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 80, color: Colors.redAccent),),
                        Icon(Icons.favorite, color: Colors.pink, size: 80),
                        Text("VE", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 80, color: Colors.redAccent),),
                      ],
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                    ),
                    Text("PARROT", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 80, color: Colors.redAccent),),
                    Loading(indicator: BallPulseIndicator(), size: 35.0, color: Colors.red,),
                  ],
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                )
            )
        )
    );
  }
}

class StartPage extends StatefulWidget {
  StartPage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  StartPageState createState() => StartPageState();
}


class CreatePageState extends State<CreatePage> {
  getStringValuesSF() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    //Return String
    String stringValue = prefs.getString('guid');
    return stringValue;
  }

  String name = "";

  addStringToSF(guid) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('guid', guid);
  }

  Widget build (BuildContext context) {
    return new Scaffold(
        body: Container(
            color: Colors.white,
            child: Center(
                child: ListView(
                  children: <Widget>[
                    Padding(
                      padding: EdgeInsets.only(
                        top: 100
                      ),
                    ),
                    Row(
                      children: <Widget>[
                        Text(
                          "L",
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 80,
                              color: Colors.redAccent
                          ),
                        ),
                        Icon(
                            Icons.favorite,
                            color: Colors.pink,
                            size: 80
                        ),
                        Text(
                          "VE",
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 80,
                              color: Colors.redAccent
                          ),
                        ),
                      ],
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                    ),
                    Text(
                      "PARROT",
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 80,
                          color: Colors.redAccent
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 30,
                        right: 30,
                      ),
                      child: TextField(
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Input Key',
                        ),
                        expands: false,
                        onChanged: (val) {
                          name = val;
                        },
                        cursorColor: Colors.red,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(5),
                      child: NiceButton(
                        radius: 40,
                        padding: const EdgeInsets.all(15),
                        text: "Use Existing\t \t",
                        icon: Icons.assignment_turned_in,
                        gradientColors: [Colors.red[200], Colors.red[800]],
                        elevation: 5,
                        onPressed: () {
                          addStringToSF(name);
                          Navigator.push(
                            context,
                            new MaterialPageRoute(builder: (context) => new loadingScreen(title: name)),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: NiceButton(
                        radius: 40,
                        padding: const EdgeInsets.all(15),
                        text: "Create New\t \t",
                        icon: Icons.create,
                        gradientColors: [Colors.red[200], Colors.red[800]],
                        elevation: 5,
                        onPressed: () {

                        },
                      ),
                    ),                  ],
//                  crossAxisAlignment: CrossAxisAlignment.center,
//                  mainAxisAlignment: MainAxisAlignment.center,
                )
            )
        )
    );
  }
}

class CreatePage extends StatefulWidget {
  CreatePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  CreatePageState createState() => CreatePageState();
}

class Quote {
  String _quote;
  String _audioPath;
  Quote(String quote, String audioPath) {
    _quote = quote;
    _audioPath = audioPath;
  }
  String getQuote(){
    return _quote;
  }

  String getAudioPath(){
    return _audioPath;
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var httpClient = new HttpClient();

  AudioPlayer audioPlayer = AudioPlayer();
  Random rand = new Random();
  var apiUrl = 'https://8ztjp43yjl.execute-api.us-east-2.amazonaws.com/prod';
  int counter = 0;

  Map<String, dynamic> previous = {"RonTableID":"3","quote":"I love you!","link":"https://ronaudiobucket.s3.us-east-2.amazonaws.com/iLoveYou.mp3"};

  playLocal(localPath) async {
    int result = await audioPlayer.play(localPath, isLocal: true);
    print(result.toString());
  }

  Quote q = quotes[quotes.length - 1];

  Widget mainWidget() {
    return Builder(
      builder: (context) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              IconButton(
                icon: images[rand.nextInt(images.length)],
                iconSize: 400,
                onPressed: () {
                  setState(() {
                    q = quotes[rand.nextInt(quotes.length)];
                    playLocal(q.getAudioPath());
                  });
                },
              ),
              Text(
                q.getQuote(),
                style: TextStyle(
                    color: Colors.grey[800],
                    fontWeight: FontWeight.bold,
                    fontSize: 30
                ),
              ),
              Text(
                "-Ron",
                style: TextStyle(
                    color: Colors.grey[800],
                    fontStyle: FontStyle.italic,
                    fontSize: 16,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: new PopupMenuButton(
          icon: Icon(Icons.menu),
          offset: Offset(0, 30),
          itemBuilder: (context) => packs,
          onSelected: (value) {
            if(value == 10000000){
              Navigator.push(
                context,
                new MaterialPageRoute(builder: (context) => new CreatePage(title: 'Emegency Ron')),
              );
            } else {
              Navigator.push(
                context,
                new MaterialPageRoute(builder: (context) => new loadingScreen(title: packsLocation[value])),
              );
            }
          },
        ),
        title: Text(widget.title),
      ),
      body: mainWidget(),
    );
  }
}
