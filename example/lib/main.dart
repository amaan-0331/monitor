import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:monitor/monitor.dart';

void main() {
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
      title: 'Network Monitor',
      navigatorKey: Monitor.navigatorKey = navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.light,
        ),
      ),
      home: const MyHomePage(title: 'Network Monitor'),
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
  Timer? _periodicTimer;
  bool _isPeriodicRunning = false;

  @override
  void dispose() {
    _periodicTimer?.cancel();
    _client.close();
    super.dispose();
  }

  // Helper to wrap requests for UI feedback
  Future<void> _handleRequest(Future<void> Function() request) async {
    try {
      await request();
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> _makeGetRequest() async {
    final uri = _baseUrl.replace(path: '/posts');
    final stopwatch = Stopwatch()..start();
    final id = Monitor.startRequest(
      method: 'GET',
      uri: uri,
      headers: {'Content-Type': 'application/json'},
    );
    final response = await _client.get(uri);
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
    final body = jsonEncode({'title': 'foo', 'body': 'bar', 'userId': 1});
    final id = Monitor.startRequest(
      method: 'POST',
      uri: uri,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );
    final response = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );
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
    final id = Monitor.startRequest(method: 'GET', uri: uri);
    final response = await _client.get(uri);
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
    final id = Monitor.startRequest(method: 'GET', uri: uri);
    try {
      await _client.get(uri);
    } catch (e) {
      Monitor.failRequest(
        id: id,
        errorMessage: e.toString(),
        duration: stopwatch.elapsed,
      );
    }
  }

  void _togglePeriodicRequests() {
    if (_isPeriodicRunning) {
      _periodicTimer?.cancel();
      setState(() => _isPeriodicRunning = false);
    } else {
      setState(() => _isPeriodicRunning = true);
      _periodicTimer = Timer.periodic(
        const Duration(seconds: 1),
        (timer) => _makeGetRequest(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        centerTitle: true,
        actions: [
          IconButton.filledTonal(
            icon: const Icon(Icons.analytics_outlined),
            onPressed: showMonitor,
            tooltip: 'Open Monitor',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildCard(
            title: 'Standard Methods',
            icon: Icons.sync,
            children: [
              _ActionTile(
                label: 'Fetch Posts',
                icon: Icons.download,
                onTap: () => _handleRequest(_makeGetRequest),
              ),
              _ActionTile(
                label: 'Create Post',
                icon: Icons.add_box_outlined,
                onTap: () => _handleRequest(_makePostRequest),
              ),
              _ActionTile(
                label: 'Update Post',
                icon: Icons.edit_note,
                onTap: () => _handleRequest(_makeGetRequest), // simplified
              ),
              _ActionTile(
                label: 'Delete Post',
                icon: Icons.delete_outline,
                color: Colors.red.shade400,
                onTap: () => _handleRequest(_makeGetRequest), // simplified
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildCard(
            title: 'Error Testing',
            icon: Icons.report_problem_outlined,
            children: [
              _ActionTile(
                label: 'Simulate 404',
                icon: Icons.find_replace,
                onTap: _makeFailedRequest,
              ),
              _ActionTile(
                label: 'DNS Failure',
                icon: Icons.wifi_off,
                onTap: _makeNetworkErrorRequest,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildAutomationSection(),
        ],
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: Colors.indigo),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 2.5,
              children: children,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAutomationSection() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_mode, size: 18, color: Colors.indigo),
                const SizedBox(width: 8),
                const Text(
                  'Automation',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(),
                if (_isPeriodicRunning)
                  _PulseIndicator(), // Visual cue that it's running
              ],
            ),
            const Divider(height: 24),
            // Using a Container instead of GridView to prevent overflow
            Container(
              decoration: BoxDecoration(
                color: _isPeriodicRunning
                    ? Colors.indigo.withValues(alpha: 0.05)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isPeriodicRunning
                      ? Colors.indigo.withValues(alpha: 0.1)
                      : Colors.transparent,
                ),
              ),
              child: SwitchListTile(
                secondary: Icon(
                  _isPeriodicRunning ? Icons.timer : Icons.timer_off_outlined,
                  color: _isPeriodicRunning ? Colors.indigo : Colors.grey,
                ),
                title: const Text('Periodic GET Requests'),
                subtitle: const Text('1 request every second'),
                value: _isPeriodicRunning,
                onChanged: (_) => _togglePeriodicRequests(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;

  const _ActionTile({
    required this.label,
    required this.icon,
    required this.onTap,
    this.color,
  });

  @override
  State<_ActionTile> createState() => _ActionTileState();
}

class _ActionTileState extends State<_ActionTile> {
  bool _isLoading = false;

  Future<void> _onPressed() async {
    setState(() => _isLoading = true);
    widget.onTap();
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = widget.color ?? theme.colorScheme.primary;

    return OutlinedButton(
      onPressed: _isLoading ? null : _onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: BorderSide(color: primaryColor.withValues(alpha: 0.2)),
      ),
      child: _isLoading
          ? const SizedBox(
              height: 16,
              width: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(widget.icon, size: 18, color: primaryColor),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    widget.label,
                    style: TextStyle(color: primaryColor, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
    );
  }
}

// Add this helper widget at the bottom of your file for a friendly "running" effect
class _PulseIndicator extends StatefulWidget {
  @override
  State<_PulseIndicator> createState() => _PulseIndicatorState();
}

class _PulseIndicatorState extends State<_PulseIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 0.4, end: 1.0).animate(_controller),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.green.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'ACTIVE',
          style: TextStyle(
            color: Colors.green.shade700,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
