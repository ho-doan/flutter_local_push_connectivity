import 'package:flutter/material.dart';
import 'package:flutter_push_common/flutter_push_common.dart';
import 'package:server/src/widgets/client_list_widget.dart';

import 'src/core/api/api_handler.dart';
import 'src/core/server/i_server.dart';
import 'src/core/server/tcp_server.dart';

void main() {
  runApp(const ServerApp());
}

class ServerApp extends StatelessWidget {
  const ServerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Push Server',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const ServerPage(),
    );
  }
}

class ServerPage extends StatefulWidget {
  const ServerPage({super.key});

  @override
  State<ServerPage> createState() => _ServerPageState();
}

class _ServerPageState extends State<ServerPage> {
  Set<IServer> _servers = {
    TcpServer(
      portNotification: Constants.notificationPort,
      portControl: Constants.controlPort,
    ),
  };

  late ApiHandler _apiHandler;

  bool _isRunning = false;

  void _listen() {
    setState(() {});
  }

  void _init() {
    setState(() {
      _servers = {
        TcpServer(
          portNotification: Constants.notificationPort,
          portControl: Constants.controlPort,
        ),
      };
      for (final server in _servers) {
        server.addListener(_listen);
      }

      _apiHandler = ApiHandler(_servers);
    });
  }

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _toggleServer() async {
    if (_isRunning) {
      for (final server in _servers) {
        await server.stop();
      }
      _apiHandler.stop();
      setState(() {
        _isRunning = false;
      });
    } else {
      _init();
      for (final server in _servers) {
        await server.start();
      }
      _apiHandler.start();
      setState(() {
        _isRunning = true;
      });
    }
  }

  @override
  void dispose() {
    for (final server in _servers) {
      server.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Push Server'),
        actions: [
          IconButton(
            icon: Icon(_isRunning ? Icons.stop : Icons.play_arrow),
            onPressed: _toggleServer,
          ),
        ],
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Panel - Server Info and Client List
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Server Status
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color:
                          _isRunning
                              ? Colors.green.shade100
                              : Colors.red.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _isRunning ? Icons.cloud_done : Icons.cloud_off,
                          color: _isRunning ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 16),
                        Text(
                          _isRunning
                              ? 'Server is running'
                              : 'Server is stopped',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Port Information
                  Text(
                    'Server Configuration',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Notification Port: ${Constants.notificationPort}',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Control Port: ${Constants.controlPort}',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'API Port: ${Constants.apiPort}',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          // Client List
          Expanded(
            child: SingleChildScrollView(
              child: ClientListWidget(servers: _servers),
            ),
          ),
        ],
      ),
    );
  }
}
