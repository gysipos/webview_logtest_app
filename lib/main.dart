import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late final WebViewController _webViewController;
  late final TextEditingController _textEditingController;
  List<String> history = [];
  late final SharedPreferences sp;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((value) {
      sp = value;
      setState(() {
        history = sp.getStringList(historyKey) ?? [];
      });
    });
    _textEditingController = TextEditingController();
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (url) {
          /// If you filer '//wwapp' in logcat, you'll see only these logs
          print('onPageStarted: $url //wwapp');
        },
        onUrlChange: (change) {
          /// If you filer '//wwapp' in logcat, you'll see only these logs
          print('onUrlChange: ${change.url} //wwapp');
        },
        onProgress: (progress) {
          /// If you filer '//wwapp' in logcat, you'll see only these logs
          print('onProgress: $progress //wwapp');
        },
        onWebResourceError: (error) {
          /// If you filer '//wwapp' in logcat, you'll see only these logs
          print('onWebResourceError: $error //wwapp');
        },
        onPageFinished: (url) async {
          /// If you filer '//wwapp' in logcat, you'll see only these logs
          print('onPageFinished: $url //wwapp');
        },
        onNavigationRequest: (request) async {
          /// If you filer '//wwapp' in logcat, you'll see only these logs
          print('onNavigationRequest: ${request.url} //wwapp');
          return NavigationDecision.navigate;
        },
      ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox(
        height: MediaQuery.sizeOf(context).height,
        child: WebViewWidget(
          controller: _webViewController,
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
              context: context,
              builder: (context) => Dialog(
                    child: SizedBox(
                      height: 600,
                      child: CustomScrollView(
                        slivers: [
                          SliverList(
                            delegate: SliverChildListDelegate([
                              TextField(
                                decoration: InputDecoration(
                                    hintText: 'url',
                                    border: OutlineInputBorder()),
                                controller: _textEditingController,
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  history = [
                                    _textEditingController.text,
                                    ...history
                                  ];
                                  sp.setStringList(historyKey, history);
                                  Navigator.pop(context);
                                  _webViewController.loadRequest(Uri.parse(
                                      addHttpStuff(
                                          _textEditingController.text)));
                                },
                                child: const Text('tőccsed'),
                              ),
                            ]),
                          ),
                          SliverList(
                              delegate: SliverChildBuilderDelegate(
                                  childCount: history.length, (context, index) {
                            return TextButton(
                                onPressed: () {
                                  _webViewController.loadRequest(
                                      Uri.parse(addHttpStuff(history[index])));
                                  Navigator.pop(context);
                                },
                                child: Text(history[index]));
                          })),
                          SliverList(
                              delegate: SliverChildListDelegate([
                            ElevatedButton(
                                onPressed: () {
                                  sp.clear();
                                  setState(() {
                                    history = [];
                                  });
                                },
                                child: const Text('elfelejtsed!'))
                          ]))
                        ],
                      ),
                    ),
                  ));
        },
        child: const Icon(Icons.send),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

String addHttpStuff(String url) {
  if (url.startsWith('http://') || url.startsWith('https://')) {
    return url;
  } else {
    return 'https://$url';
  }
}

const historyKey = 'history';
