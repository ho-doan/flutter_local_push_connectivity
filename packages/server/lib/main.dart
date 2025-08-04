import 'package:flutter/material.dart';
import 'package:server/src/server.dart';
import 'package:server/src/widgets/client_list_widget.dart';

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
  final _server = Server(notificationPort: 8080, controlPort: 8081);

  bool _isRunning = false;
  final List<String> _logs = [];

  @override
  void initState() {
    super.initState();
    // Listen to server logs
    _server.logStream.listen((log) {
      setState(() {
        _logs.add(log);
      });
    });

    // Listen to client changes
    _server.addListener(() {
      setState(() {});
    });
  }

  Future<void> _toggleServer() async {
    if (_isRunning) {
      _server.stop();
      setState(() {
        _isRunning = false;
      });
    } else {
      await _server.start();
      setState(() {
        _isRunning = true;
      });
    }
  }

  @override
  void dispose() {
    _server.dispose();
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
        children: [
          // Left Panel - Server Info and Client List
          Expanded(
            flex: 2,
            child: Card(
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
                      'Notification Port: 8080',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Control Port: 8081',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 24),
                    // Client List
                    Expanded(
                      child: SingleChildScrollView(
                        child: ClientListWidget(server: _server),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Right Panel - Logs
          Expanded(
            flex: 3,
            child: Card(
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Server Logs',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        IconButton(
                          icon: const Icon(Icons.clear_all),
                          onPressed: () {
                            setState(() {
                              _logs.clear();
                            });
                          },
                          tooltip: 'Clear logs',
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ListView.builder(
                          padding: const EdgeInsets.all(8),
                          itemCount: _logs.length,
                          itemBuilder: (context, index) {
                            return Text(
                              _logs[index],
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 12,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
