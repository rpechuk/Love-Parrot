import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_amazon_s3/flutter_amazon_s3.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

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
      home: MyHomePage(title: 'Emegency Ron'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}


class _MyHomePageState extends State<MyHomePage> {
  AudioPlayer audioPlayer = AudioPlayer();
  Random rand = new Random();
  var apiUrl = 'https://8ztjp43yjl.execute-api.us-east-2.amazonaws.com/prod';
  var httpClient = new HttpClient();
  int counter = 0;

  Map<String, dynamic> previous = {"RonTableID":"3","quote":"I love you!","link":"https://ronaudiobucket.s3.us-east-2.amazonaws.com/iLoveYou.mp3"};

  Future<Map<String, dynamic>> _getNextQuoteData() async{


    counter++;
    print("called api " + counter.toString() + " times");
    Map<String, dynamic> result;

    try {
      var request = await httpClient.getUrl(Uri.parse(apiUrl));
      var response = await request.close();
      if (response.statusCode == HttpStatus.ok) {
        var jsonString = await response.transform(utf8.decoder).join();
        Map<String, dynamic> data = json.decode(jsonString);
        result = data;
        previous = result;
      }
    } catch (exception) {
      result = previous;
      print(exception);
    }

    play(result['link']);
    return result;
  }

  play(url) async {
    int result = await audioPlayer.play(url);
    if (result == 1) {
      // success
    }
  }

  var images = [Image.asset('assets/images/Face.png'), Image.asset('assets/images/Face1.png'), Image.asset('assets/images/Face2.png'),
    Image.asset('assets/images/Face3.png'), Image.asset('assets/images/Face4.png'), Image.asset('assets/images/Face5.png'),
    Image.asset('assets/images/Face6.png'), Image.asset('assets/images/Face7.png')];



  Widget mainWidget() {
    return FutureBuilder(
      builder: (context, projectSnap) {
        if (projectSnap.connectionState == ConnectionState.waiting && projectSnap.hasData != null) {
          //print('project snapshot data is: ${projectSnap.data}');

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                IconButton(
                  icon: images[rand.nextInt(6) + 1],
                  iconSize: 400,
                ),
                Text(
                  '${previous['quote']}',
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
                      fontSize: 16
                  ),
                ),
              ],
            ),
          );
        }
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              IconButton(
                icon: images[0],
                iconSize: 400,
                onPressed: () {
                  setState(() {
                  });
                },
              ),
              Text(
                '${projectSnap.data['quote']}',
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
                    fontSize: 16
                ),
              ),
            ],
          ),
        );
      },
      future: _getNextQuoteData(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: mainWidget()
    );
  }
}
