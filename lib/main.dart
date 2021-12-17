import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart' as shelf_router;
import 'package:shelf_static/shelf_static.dart' as shelf_static;

import 'package:flutter/material.dart';

import 'model/line.dart';
import 'model/sender_model.dart';

Future<void> main() async {

  runApp(const MyApp());
}



class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);



  // This widget is the root of your application.
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
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  List<Line> lines=[];
  List<SenderModel> senderModel=[];
  final router = shelf_router.Router();

  String? verb,ip,mask,port;
  bool modifier=false;


  Future<void> startServer() async {
    // If the "PORT" environment variable is set, listen to it. Otherwise, 8080.
    // https://cloud.google.com/run/docs/reference/container-contract#port
    final port = int.parse(Platform.environment['PORT'] ?? '8080');

    // See https://pub.dev/documentation/shelf/latest/shelf/Cascade-class.html
    final cascade = Cascade()
    // First, serve files from the 'public' directory
        .add(_staticHandler)
    // If a corresponding file is not found, send requests to a `Router`
        .add(router);

    // See https://pub.dev/documentation/shelf/latest/shelf_io/serve.html
    final server = await shelf_io.serve(
      // See https://pub.dev/documentation/shelf/latest/shelf/logRequests.html
      logRequests()
      // See https://pub.dev/documentation/shelf/latest/shelf/MiddlewareExtensions/addHandler.html
          .addHandler(cascade.handler),
      InternetAddress.anyIPv4, // Allows external connections
      port,
    );

    print('Serving at http://${server.address.host}:${server.port}');
  }


  // Serve files from the file system.
  final _staticHandler =
  shelf_static.createStaticHandler('public', defaultDocument: 'index.html');


  bool FireWallCore(SenderModel data){
    if(lines.isEmpty){
      data.ans=true;
      setState(() {
        senderModel.add(data);
      });
      return true;
    }
    List<Line> l= List.from(lines);
    if(data.flag == Flag.Continue){
      l=l.where((element) => element.modifier == true).toList();
    }else{
      l=l.skipWhile((element) => element.modifier == true).toList();
    }
    print(l.toString());
    if(l.isEmpty){
      data.ans=true;
      setState(() {
        senderModel.add(data);
      });
      return true;
    }
    l=l.map((e){
      if(e.allPorts == true){
        e.mask =data.mask;
        e.port =data.sourcePort;
      }
      if(e.allIp == true){
        e.ip =data.sourceIP;
      }
      return e;
    }).toList();
    l=l.where((element) => element.ip == data.sourceIP && element.port == data.sourcePort).toList();
    bool ans= l.isEmpty?false:l.first.verb == verbs.allow?true:false;
    data.ans=ans;
    setState(() {
      senderModel.add(data);
    });
    return ans;
  }

  Response _fireWallHandler(request, String ip, String mask,String port,String flag) {
    final maskNum = int.parse(mask);
    final portNum = int.parse(port);
    print(flag);
    final flagType= flag == "end"?Flag.End:flag == "continue"?Flag.Continue:Flag.Start;
    //call core
    bool fireWallCore=FireWallCore(
        SenderModel(
          mask: maskNum,
          flag: flagType,
          sourceIP: ip,
          sourcePort: portNum,
        )
    );
    if(fireWallCore){
      return Response.ok("Allowed");
    }else{
      return Response.forbidden("block");
    }
  }


  @override
  void initState() {
    // Router instance to handler requests.
    router.get('/fireWall/<ip>/<mask>/<port>/<flag>', _fireWallHandler);
    startServer();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: const Text("Firewall Emulator"),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 32,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: const [
                Text("stream"),
                SizedBox(width: 50,),
                Text("rules"),
              ],
            ),
          ),
          const Divider(
            height: 2,
          ),
          Row(
            children: [
              SizedBox(
                child:ListView.builder(
                  itemCount: senderModel.length,
                  itemBuilder: (context, index) {
                    senderModel=senderModel.reversed.toList();
                    return ListTile(
                      title: Container(
                        color: senderModel[index].ans?Colors.green:Colors.red,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 150,
                              child: Text("${senderModel[index].sourceIP!}/${senderModel[index].mask.toString()}"),

                            ),

                            SizedBox(
                              width: 150,
                              child: Text(senderModel[index].sourcePort.toString()),
                            ),

                            SizedBox(
                              width: 150,
                              child: Text(senderModel[index].flag.toString()),
                            ),
                          ],
                        ),
                      )
                    );
                  },
                ),
                height: MediaQuery.of(context).size.height-150,
                width: (MediaQuery.of(context).size.width/2)-5,
              ),

               Container(
                width: 3,
                height: MediaQuery.of(context).size.height-90,
                color: Colors.black,
              ),


              Container(
                color: Colors.white12,
                child:Column(
                  children: [
                    SizedBox(
                      height: 70,
                      width: (MediaQuery.of(context).size.width/2)-5,

                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children:  [
                           SizedBox(
                            child: TextField(
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                labelText: 'verb',
                                hintText: 'block/allow',
                              ),
                              onChanged: (String s){
                                setState(() {
                                  verb=s;
                                });
                              }
                            ),
                            width: 150,
                          ),
                           SizedBox(
                            child: TextField(
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                labelText: 'ip',
                                hintText: 'ip',
                              ),
                                onChanged: (String s){
                                  setState(() {
                                    ip=s;
                                  });
                                }
                            ),
                            width: 150,
                          ),
                           SizedBox(
                            child: TextField(
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                labelText: 'mask',
                                hintText: 'mask',
                              ),
                                onChanged: (String s){
                                  setState(() {
                                    mask=s;
                                  });
                                }
                            ),
                            width: 70,
                          ),
                           SizedBox(
                            child: TextField(
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                labelText: 'port',
                                hintText: 'port',
                              ),
                                onChanged: (String s){
                                  setState(() {
                                    port=s;
                                  });
                                }
                            ),
                            width: 70,
                          ),
                          InkWell(
                              onTap: ()=>setState(() {
                                modifier=!modifier;
                              }),
                              child: Container(
                                width: 60,
                                color: !modifier?Colors.grey:Colors.green,
                                child: const Text("modifier"),
                              )
                          ),
                          InkWell(
                              onTap: (){
                                if(ip != null && verb != null && mask != null && port != null){
                                  setState(() {
                                    lines.add(
                                        Line(
                                          modifier: modifier,
                                          ip: ip,
                                          allIp: ip == "*"?true:false,
                                          port: int.parse(port!),
                                          allPorts: port == "*"?true:false,
                                          verb: verb == "block"?verbs.block:verbs.allow,
                                          mask: int.parse(mask!),
                                        )
                                    );
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:  Text('added'),backgroundColor: Colors.green,));
                                }else{
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:  Text('add all values'),backgroundColor: Colors.red,));
                                }

                              },
                              child: Container(
                                width: 60,
                                height: 30,
                                color: Colors.red,
                                child: const Center(child:  Text("add"),)
                              )
                          )


                        ],
                      ),
                    ),
                    const Divider(
                      height: 3,
                    ),
                    SizedBox(
                      child: ListView.builder(
                        itemCount: lines.length,
                        itemBuilder: (context, index) {
                          return Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  SizedBox(
                                    width: 50,
                                    child: Text(lines[index].verb.index == 0 ?"block": "allow"),
                                  ),
                                  SizedBox(
                                    width: 150,
                                    child: lines[index].ip=="*"?Text(lines[index].ip!):Text("${lines[index].ip}/${lines[index].mask}"),
                                  ),
                                  SizedBox(
                                    width: 50,
                                    child: Text(lines[index].port.toString()),
                                  ),
                                  SizedBox(
                                    width: 150,
                                    child: Text(lines[index].modifier?"modifier":""),
                                  ),
                                ],
                              ),
                              const Divider(
                                height: 3,
                              ),
                            ],
                          );
                        },
                      ),
                      height: MediaQuery.of(context).size.height-204,
                      width: (MediaQuery.of(context).size.width/2)-5,
                    )

                  ],
                ),
                height: MediaQuery.of(context).size.height-103,
                width: (MediaQuery.of(context).size.width/2)-5,
              )


            ],
          ),
        ],
      )
    );
  }
}
