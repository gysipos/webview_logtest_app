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
  List<String> logs = [];
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
          addToLogs('onPageStarted: $url');
        },
        onUrlChange: (change) {
          addToLogs('onUrlChange: ${change.url}');
        },
        onProgress: (progress) {
          addToLogs('onProgress: $progress');
        },
        onWebResourceError: (error) {
          addToLogs('onWebResourceError: ${error.description}');
        },
        onPageFinished: (url) async {
          addToLogs('onPageFinished: $url');
        },
        onNavigationRequest: (request) async {
          addToLogs('onNavigationRequest: ${request.url}');
          return NavigationDecision.navigate;
        },
      ));
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          bottom: const TabBar(tabs: [
            Tab(
              text: 'Webview',
            ),
            Tab(
              text: 'Logs',
            ),
          ]),
        ),
        body: TabBarView(
          children: [
            WebViewWidget(
              controller: _webViewController,
            ),
            ListView.builder(
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.all(4.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(logs[index], style: TextStyle(fontSize: 18),),
                    Divider(thickness: 3,)
                  ],
                ),
              ),
              itemCount: logs.length,
            )
          ],
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
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: TextField(
                                    decoration: const InputDecoration(
                                        hintText: 'url',
                                        border: OutlineInputBorder()),
                                    controller: _textEditingController,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: ElevatedButton(
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
                                ),
                              ]),
                            ),
                            SliverList(
                                delegate: SliverChildBuilderDelegate(
                                    childCount: history.length,
                                    (context, index) {
                              return TextButton(
                                  onPressed: () {
                                    _webViewController.loadRequest(Uri.parse(
                                        addHttpStuff(history[index])));
                                    Navigator.pop(context);
                                  },
                                  child: Text(history[index]));
                            })),
                            SliverList(
                                delegate: SliverChildListDelegate([
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: ElevatedButton(
                                    onPressed: () {
                                      sp.clear();
                                      setState(() {
                                        history = [];
                                      });
                                    },
                                    child: const Text('elfelejtsed!')),
                              )
                            ]))
                          ],
                        ),
                      ),
                    ));
          },
          child: const Icon(Icons.send),
        ), // This trailing comma makes auto-formatting nicer for build methods.
      ),
    );
  }

  void addToLogs(String log) {
    /// If you filer '//wwapp' in logcat, you'll see only these logs
    print(log + ' //wwapp');
    setState(() {
      logs = [log, ...logs];
    });
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
