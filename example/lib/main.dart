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
    final uri = _baseUrl.replace(path: '/posts');
    final stopwatch = Stopwatch()..start();

    // Start tracking the request - returns an ID for completion
    final id = Monitor.startRequest(
      method: 'GET',
      uri: uri,
      headers: {'Content-Type': 'application/json'},
    );

    final response = await _client.get(uri);

    // Complete the request with response data
    Monitor.completeRequest(
      id: id,
      statusCode: response.statusCode,
      duration: stopwatch.elapsed,
      responseBody: response.body,
    );
  }

  Future<void> _makePostRequest() async {
    final uri = _baseUrl.replace(path: '/posts');
    final stopwatch = Stopwatch()..start();
    final requestBody = jsonEncode({
      'title': 'foo',
      'body': 'bar',
      'userId': 1,
    });

    // Start tracking the request with body
    final id = Monitor.startRequest(
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

    // Complete with response
    Monitor.completeRequest(
      id: id,
      statusCode: response.statusCode,
      duration: stopwatch.elapsed,
      responseBody: response.body,
    );
  }

  Future<void> _makeFailedRequest() async {
    final uri = _baseUrl.replace(path: '/posts/999999999');
    final stopwatch = Stopwatch()..start();

    final id = Monitor.startRequest(
      method: 'GET',
      uri: uri,
      headers: {'Content-Type': 'application/json'},
    );

    final response = await _client.get(uri);

    // This will be marked as error due to 404 status
    Monitor.completeRequest(
      id: id,
      statusCode: response.statusCode,
      duration: stopwatch.elapsed,
      responseBody: response.body,
    );
  }

  Future<void> _makeNetworkErrorRequest() async {
    final uri = Uri.parse('https://invalid-domain-that-does-not-exist.com/api');
    final stopwatch = Stopwatch()..start();

    final id = Monitor.startRequest(
      method: 'GET',
      uri: uri,
      headers: {'Content-Type': 'application/json'},
    );

    try {
      await _client.get(uri);
    } catch (e) {
      // Fail the request with error message
      Monitor.failRequest(
        id: id,
        errorMessage: e.toString(),
        duration: stopwatch.elapsed,
      );
    }
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
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _makePostRequest,
              child: const Text('Make POST Request'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _makeFailedRequest,
              child: const Text('Make 404 Request'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _makeNetworkErrorRequest,
              child: const Text('Make Network Error Request'),
            ),
          ],
        ),
      ),
    );
  }
}
