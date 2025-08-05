import 'dart:developer' show log;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_push_common/flutter_push_common.dart';

import '../core/client.dart';
import '../core/server/i_server.dart';

class ClientListWidget extends StatefulWidget {
  final Set<IServer> servers;

  const ClientListWidget({super.key, required this.servers});

  @override
  State<ClientListWidget> createState() => _ClientListWidgetState();
}

class _ClientListWidgetState extends State<ClientListWidget> {
  List<(IServer, Client, TextEditingController)> _clients = [];
  void _init() {
    setState(() {
      _clients =
          widget.servers
              .expand(
                (e) => e.channelNotification.clientLst.map(
                  (c) => (e, c, TextEditingController()),
                ),
              )
              .toList();
    });
    for (final server in widget.servers) {
      server.channelNotification.addListener(_listen);
    }
  }

  void _listen() {
    if (mounted) {
      setState(() {
        _clients =
            widget.servers
                .expand(
                  (e) => e.channelNotification.clientLst.map(
                    (c) => (e, c, TextEditingController()),
                  ),
                )
                .toList();
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void didUpdateWidget(covariant ClientListWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.servers != widget.servers) {
      for (final server in oldWidget.servers) {
        server.channelNotification.removeListener(_listen);
      }
      _init();
    }
  }

  @override
  void dispose() {
    for (final server in widget.servers) {
      server.channelNotification.removeListener(_listen);
    }
    super.dispose();
  }

  void _sendMessage(
    IServer server,
    Client client,
    TextEditingController controller,
  ) {
    if (controller.text.isEmpty) {
      log('Message is empty');
      return;
    }

    final message = TextMessage(
      from: const User(deviceName: 'Server', deviceId: 'server'),
      to: client.user,
      message: controller.text,
    );

    server.send(message);
    controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Connected Clients',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        // Client List
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              for (final (server, client, controller) in _clients)
                ListTile(
                  leading: Icon(
                    Icons.person,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: Text(client.deviceName ?? 'Unknown'),
                  subtitle: Column(
                    children: [
                      TextButton(
                        onPressed: () {
                          Clipboard.setData(
                            ClipboardData(text: client.deviceId),
                          ).then((_) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Device ID copied to clipboard',
                                  ),
                                ),
                              );
                            }
                          });
                        },
                        child: Text(client.deviceId),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: controller,
                              decoration: const InputDecoration(
                                hintText: 'Enter message',
                                border: OutlineInputBorder(),
                              ),
                              onSubmitted:
                                  (_) =>
                                      _sendMessage(server, client, controller),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed:
                                () => _sendMessage(server, client, controller),
                            child: const Text('Send'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              if (widget.servers
                  .expand((e) => e.channelNotification.clientLst)
                  .isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No clients connected'),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
