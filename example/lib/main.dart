import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:monitor/monitor.dart';

void main() {
  // Initialize the monitor service
  Monitor.init(
    baseUrl: 'https://jsonplaceholder.typicode.com',
    appVersion: '1.0.0',
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static final navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Monitor Example',
      // Set the navigatorKey to allow the monitor to be opened from anywhere
      navigatorKey: Monitor.navigatorKey = navigatorKey,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Monitor Example'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _client = http.Client();
  final _baseUrl = Uri.parse('https://jsonplaceholder.typicode.com');

  Future<void> _makeGetRequest() async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final uri = _baseUrl.replace(path: '/posts/1');
    final stopwatch = Stopwatch()..start();

    Monitor.requestDetail(
      id: id,
      method: 'GET',
      uri: uri,
      headers: {'Content-Type': 'application/json'},
    );

    final response = await _client.get(uri);

    Monitor.responseDetail(
      id: id,
      uri: uri,
      status: response.statusCode,
      elapsed: stopwatch.elapsed,
      bodyRaw: response.body,
    );
  }

  Future<void> _makePostRequest() async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final uri = _baseUrl.replace(path: '/posts');
    final stopwatch = Stopwatch()..start();
    final requestBody = jsonEncode({
      'title': 'foo',
      'body': 'bar',
      'userId': 1,
    });

    Monitor.requestDetail(
      id: id,
      method: 'POST',
      uri: uri,
      headers: {'Content-Type': 'application/json'},
      body: requestBody,
    );

    final response = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: requestBody,
    );

    Monitor.responseDetail(
      id: id,
      uri: uri,
      status: response.statusCode,
      elapsed: stopwatch.elapsed,
      bodyRaw: response.body,
    );
  }

  Future<void> _makeFailedRequest() async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final uri = _baseUrl.replace(path: '/posts/999999999');
    final stopwatch = Stopwatch()..start();

    Monitor.requestDetail(
      id: id,
      method: 'GET',
      uri: uri,
      headers: {'Content-Type': 'application/json'},
    );

    final response = await _client.get(uri);

    Monitor.responseDetail(
      id: id,
      uri: uri,
      status: response.statusCode,
      elapsed: stopwatch.elapsed,
      bodyRaw: response.body,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.monitor),
            onPressed: () {
              // Open the monitor
              showMonitor();
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: _makeGetRequest,
              child: const Text('Make GET Request'),
            ),
            ElevatedButton(
              onPressed: _makePostRequest,
              child: const Text('Make POST Request'),
            ),
            ElevatedButton(
              onPressed: _makeFailedRequest,
              child: const Text('Make Failed Request'),
            ),
          ],
        ),
      ),
    );
  }
}
