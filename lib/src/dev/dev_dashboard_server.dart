/// Dev Dashboard Web Server
///
/// Provides HTTP server for the developer dashboard web UI.
/// Serves real-time event data and statistics via REST API.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'dev_dashboard.dart';

/// Web server for Dev Dashboard
class DevDashboardServer {
  DevDashboardServer._();
  static DevDashboardServer? _instance;
  static DevDashboardServer get instance => _instance ??= DevDashboardServer._();

  HttpServer? _server;
  bool _isRunning = false;
  int _port = 8080;
  final DevDashboard _dashboard = DevDashboard.instance;

  /// Start the web server
  Future<void> start({int port = 8080}) async {
    if (_isRunning) {
      if (kDebugMode) {
        print('DevDashboardServer: Already running on port $_port');
      }
      return;
    }

    _port = port;
    try {
      _server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
      _isRunning = true;

      if (kDebugMode) {
        print('DevDashboardServer: Started on http://localhost:$port');
      }

      _server!.listen(_handleRequest);
    } catch (e) {
      if (kDebugMode) {
        print('DevDashboardServer: Failed to start: $e');
      }
      rethrow;
    }
  }

  /// Stop the web server
  Future<void> stop() async {
    if (!_isRunning) return;

    await _server?.close(force: true);
    _server = null;
    _isRunning = false;

    if (kDebugMode) {
      print('DevDashboardServer: Stopped');
    }
  }

  /// Check if server is running
  bool get isRunning => _isRunning;

  /// Get server URL
  String get url => 'http://localhost:$_port';

  void _handleRequest(HttpRequest request) {
    final path = request.uri.path;
    final method = request.method;

    try {
      if (method == 'GET') {
        if (path == '/' || path == '/dashboard') {
          _serveDashboard(request);
        } else if (path == '/api/events') {
          _serveEvents(request);
        } else if (path == '/api/stats') {
          _serveStats(request);
        } else if (path == '/api/events/stream') {
          _serveEventStream(request);
        } else {
          _serve404(request);
        }
      } else if (method == 'DELETE' && path == '/api/events') {
        _clearEvents(request);
      } else {
        _serve404(request);
      }
    } catch (e) {
      _serveError(request, e);
    }
  }

  void _serveDashboard(HttpRequest request) {
    final html = _getDashboardHTML();
    request.response
      ..statusCode = HttpStatus.ok
      ..headers.contentType = ContentType.html
      ..write(html)
      ..close();
  }

  void _serveEvents(HttpRequest request) {
    final events = _dashboard.getEvents();
    final json = jsonEncode(events.map((e) => e.toJson()).toList());
    
    request.response
      ..statusCode = HttpStatus.ok
      ..headers.contentType = ContentType.json
      ..headers.add('Access-Control-Allow-Origin', '*')
      ..write(json)
      ..close();
  }

  void _serveStats(HttpRequest request) {
    final stats = _dashboard.getStats();
    final json = jsonEncode(stats.toJson());
    
    request.response
      ..statusCode = HttpStatus.ok
      ..headers.contentType = ContentType.json
      ..headers.add('Access-Control-Allow-Origin', '*')
      ..write(json)
      ..close();
  }

  void _serveEventStream(HttpRequest request) {
    request.response
      ..statusCode = HttpStatus.ok
      ..headers.contentType = ContentType('text', 'event-stream')
      ..headers.add('Access-Control-Allow-Origin', '*')
      ..headers.add('Cache-Control', 'no-cache')
      ..headers.add('Connection', 'keep-alive');

    final subscription = _dashboard.onEvent.listen((event) {
      final data = jsonEncode(event.toJson());
      request.response.write('data: $data\n\n');
    });

    request.response.done.then((_) {
      subscription.cancel();
    });
  }

  void _clearEvents(HttpRequest request) {
    _dashboard.clearEvents();
    request.response
      ..statusCode = HttpStatus.ok
      ..write(jsonEncode({'success': true}))
      ..close();
  }

  void _serve404(HttpRequest request) {
    request.response
      ..statusCode = HttpStatus.notFound
      ..write('Not Found')
      ..close();
  }

  void _serveError(HttpRequest request, dynamic error) {
    request.response
      ..statusCode = HttpStatus.internalServerError
      ..write(jsonEncode({'error': error.toString()}))
      ..close();
  }

  String _getDashboardHTML() {
    return '''
<!DOCTYPE html>
<html>
<head>
  <title>Flutter Unify Dev Dashboard</title>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      background: #0a0e27;
      color: #e0e0e0;
      padding: 20px;
    }
    .header {
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
      padding: 30px;
      border-radius: 12px;
      margin-bottom: 30px;
      box-shadow: 0 8px 32px rgba(0,0,0,0.3);
    }
    .header h1 {
      font-size: 32px;
      margin-bottom: 10px;
      color: white;
    }
    .header p { color: rgba(255,255,255,0.9); }
    .stats {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
      gap: 20px;
      margin-bottom: 30px;
    }
    .stat-card {
      background: #1a1f3a;
      padding: 20px;
      border-radius: 8px;
      border-left: 4px solid #667eea;
    }
    .stat-card h3 {
      font-size: 14px;
      color: #888;
      margin-bottom: 10px;
      text-transform: uppercase;
    }
    .stat-card .value {
      font-size: 32px;
      font-weight: bold;
      color: #667eea;
    }
    .events {
      background: #1a1f3a;
      border-radius: 8px;
      padding: 20px;
      max-height: 600px;
      overflow-y: auto;
    }
    .events h2 {
      margin-bottom: 20px;
      color: #667eea;
    }
    .event {
      background: #0f1422;
      padding: 15px;
      margin-bottom: 10px;
      border-radius: 6px;
      border-left: 4px solid #667eea;
      transition: transform 0.2s;
    }
    .event:hover {
      transform: translateX(5px);
    }
    .event-header {
      display: flex;
      justify-content: space-between;
      margin-bottom: 8px;
    }
    .event-type {
      padding: 4px 12px;
      border-radius: 4px;
      font-size: 12px;
      font-weight: bold;
      text-transform: uppercase;
    }
    .event-type.network { background: #4CAF50; color: white; }
    .event-type.auth { background: #2196F3; color: white; }
    .event-type.error { background: #f44336; color: white; }
    .event-type.ai { background: #9C27B0; color: white; }
    .event-type.performance { background: #FF9800; color: white; }
    .event-time {
      color: #888;
      font-size: 12px;
    }
    .event-title {
      font-weight: bold;
      margin-bottom: 5px;
    }
    .event-description {
      color: #aaa;
      font-size: 14px;
    }
    .controls {
      margin-bottom: 20px;
      display: flex;
      gap: 10px;
    }
    button {
      background: #667eea;
      color: white;
      border: none;
      padding: 10px 20px;
      border-radius: 6px;
      cursor: pointer;
      font-weight: bold;
      transition: background 0.2s;
    }
    button:hover {
      background: #5568d3;
    }
    button.danger {
      background: #f44336;
    }
    button.danger:hover {
      background: #d32f2f;
    }
    .status {
      display: inline-block;
      width: 10px;
      height: 10px;
      border-radius: 50%;
      background: #4CAF50;
      margin-right: 8px;
      animation: pulse 2s infinite;
    }
    @keyframes pulse {
      0%, 100% { opacity: 1; }
      50% { opacity: 0.5; }
    }
  </style>
</head>
<body>
  <div class="header">
    <h1>🚀 Flutter Unify Dev Dashboard</h1>
    <p><span class="status"></span>Live monitoring active</p>
  </div>

  <div class="stats" id="stats">
    <div class="stat-card">
      <h3>Total Events</h3>
      <div class="value" id="totalEvents">0</div>
    </div>
    <div class="stat-card">
      <h3>Network Events</h3>
      <div class="value" id="networkEvents">0</div>
    </div>
    <div class="stat-card">
      <h3>Auth Events</h3>
      <div class="value" id="authEvents">0</div>
    </div>
    <div class="stat-card">
      <h3>Errors</h3>
      <div class="value" id="errorEvents">0</div>
    </div>
  </div>

  <div class="controls">
    <button onclick="refreshStats()">Refresh Stats</button>
    <button onclick="clearEvents()" class="danger">Clear Events</button>
  </div>

  <div class="events">
    <h2>Recent Events</h2>
    <div id="eventsList"></div>
  </div>

  <script>
    let eventSource;

    function updateStats() {
      fetch('/api/stats')
        .then(r => r.json())
        .then(data => {
          document.getElementById('totalEvents').textContent = data.totalEvents || 0;
          document.getElementById('networkEvents').textContent = data.networkEvents || 0;
          document.getElementById('authEvents').textContent = data.authEvents || 0;
          document.getElementById('errorEvents').textContent = data.errorEvents || 0;
        });
    }

    function loadEvents() {
      fetch('/api/events')
        .then(r => r.json())
        .then(events => {
          const list = document.getElementById('eventsList');
          list.innerHTML = '';
          events.slice(-50).reverse().forEach(event => {
            const div = document.createElement('div');
            div.className = 'event';
            div.innerHTML = `
              <div class="event-header">
                <span class="event-type ${event.type}">${event.type}</span>
                <span class="event-time">${new Date(event.timestamp).toLocaleTimeString()}</span>
              </div>
              <div class="event-title">${event.title}</div>
              ${event.description ? `<div class="event-description">${event.description}</div>` : ''}
            `;
            list.appendChild(div);
          });
        });
    }

    function refreshStats() {
      updateStats();
      loadEvents();
    }

    function clearEvents() {
      if (confirm('Clear all events?')) {
        fetch('/api/events', { method: 'DELETE' })
          .then(() => {
            refreshStats();
          });
      }
    }

    function startEventStream() {
      eventSource = new EventSource('/api/events/stream');
      eventSource.onmessage = (e) => {
        const event = JSON.parse(e.data);
        updateStats();
        loadEvents();
      };
    }

    // Initial load
    refreshStats();
    startEventStream();

    // Refresh stats every 5 seconds
    setInterval(updateStats, 5000);
  </script>
</body>
</html>
''';
  }
}

