import 'dart:developer' show log;

import 'package:flutter/material.dart';
import 'package:flutter_push_common/flutter_push_common.dart';
import 'package:server/src/server.dart';

class ClientListWidget extends StatefulWidget {
  final IServer server;

  const ClientListWidget({super.key, required this.server});

  @override
  State<ClientListWidget> createState() => _ClientListWidgetState();
}

class _ClientListWidgetState extends State<ClientListWidget> {
  User? _selectedClient;
  final _messageController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_selectedClient == null) {
      log('No selected client');
      return;
    }
    if (_messageController.text.isEmpty) {
      log('Message is empty');
      return;
    }

    final message = TextMessage(
      from: const User(deviceName: 'Server', deviceId: 'server'),
      to: _selectedClient!,
      message: _messageController.text,
    );

    widget.server.sendMessage(message);
    _messageController.clear();
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
              for (final client in widget.server.connectedClients)
                ListTile(
                  leading: Icon(
                    Icons.person,
                    color:
                        _selectedClient?.deviceId == client.deviceId
                            ? Theme.of(context).primaryColor
                            : null,
                  ),
                  title: Text(client.deviceName ?? 'Unknown'),
                  subtitle: Text(client.deviceId),
                  selected: _selectedClient?.deviceId == client.deviceId,
                  onTap: () {
                    setState(() {
                      if (_selectedClient?.deviceId == client.deviceId) {
                        _selectedClient = null;
                      } else {
                        _selectedClient = client;
                      }
                    });
                  },
                ),
              if (widget.server.connectedClients.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No clients connected'),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Message Input
        if (_selectedClient != null) ...[
          Text(
            'Send Message to ${_selectedClient?.deviceName}',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: const InputDecoration(
                    hintText: 'Enter message',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _sendMessage,
                child: const Text('Send'),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
