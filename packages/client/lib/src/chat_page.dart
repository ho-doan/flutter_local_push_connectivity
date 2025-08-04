import 'package:flutter/material.dart';
import 'chat_client.dart';
import 'models/message.dart';
import 'models/user.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late final ChatClient _client;
  final _messageController = TextEditingController();
  final _messages = <Message>[];
  final _users = <User>[];
  User? _selectedUser;
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _initializeClient();
  }

  void _initializeClient() {
    _client = ChatClient(
      host: '127.0.0.1',
      notificationPort: 8080,
      controlPort: 8081,
      deviceName: 'Flutter Client ${DateTime.now().millisecondsSinceEpoch}',
    );

    // Listen for connection state changes
    _client.connectionStream.listen((isConnected) {
      setState(() {
        _isConnected = isConnected;
      });
    });

    // Listen for messages
    _client.messageStream.listen((m) {
      Message message = Message.fromJson(m);
      setState(() {
        _messages.add(message);
      });

      // Show notification if message is not from selected user
      if (mounted && message.from.deviceId != _selectedUser?.deviceId) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('New message from ${message.from.deviceName}'),
            action: SnackBarAction(
              label: 'View',
              onPressed: () {
                setState(() {
                  _selectedUser = message.from;
                });
              },
            ),
          ),
        );
      }
    });

    // Listen for directory updates
    _client.directoryStream.listen((users) {
      setState(() {
        _users
          ..clear()
          ..addAll(users.where((u) => u.deviceId != _client.deviceId));

        // Clear selected user if they're no longer in the list
        if (_selectedUser != null && !_users.contains(_selectedUser)) {
          _selectedUser = null;
        }
      });
    });
  }

  Future<void> _connect() async {
    try {
      await _client.connect();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Connection failed: $e')));
      }
    }
  }

  void _disconnect() {
    _client.disconnect();
    setState(() {
      _selectedUser = null;
      _messages.clear();
      _users.clear();
    });
  }

  Future<void> _sendMessage() async {
    if (_selectedUser == null) return;
    if (_messageController.text.isEmpty) return;

    try {
      await _client.sendMessage(
        _messageController.text,
        _selectedUser!.deviceId,
      );
      setState(() {
        _messages.add(
          Message(
            from: User(
              deviceName: _client.deviceName,
              deviceId: _client.deviceId,
            ),
            to: _selectedUser!,
            text: _messageController.text,
            timestamp: DateTime.now(),
          ),
        );
      });
      _messageController.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to send message: $e')));
      }
    }
  }

  @override
  void dispose() {
    _client.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Push Chat'),
        actions: [
          IconButton(
            icon: Icon(_isConnected ? Icons.cloud_done : Icons.cloud_off),
            onPressed: _isConnected ? _disconnect : _connect,
          ),
        ],
      ),
      body: Row(
        children: [
          // User List
          SizedBox(
            width: 250,
            child: Card(
              margin: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Online Users',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _users.length,
                      itemBuilder: (context, index) {
                        final user = _users[index];
                        return ListTile(
                          leading: const Icon(Icons.person),
                          title: Text(user.deviceName),
                          selected: _selectedUser?.deviceId == user.deviceId,
                          onTap: () {
                            setState(() {
                              if (_selectedUser?.deviceId == user.deviceId) {
                                _selectedUser = null;
                              } else {
                                _selectedUser = user;
                              }
                            });
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Chat Area
          Expanded(
            child: Card(
              margin: const EdgeInsets.all(8),
              child: Column(
                children: [
                  // Chat Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: Theme.of(context).dividerColor,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.chat),
                        const SizedBox(width: 8),
                        Text(
                          _selectedUser != null
                              ? 'Chat with ${_selectedUser!.deviceName}'
                              : 'Select a user to start chatting',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ),
                  // Messages
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(8),
                      reverse: true,
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final message = _messages[_messages.length - 1 - index];
                        final isMe = message.from.deviceId == _client.deviceId;
                        final isSelected =
                            message.from.deviceId == _selectedUser?.deviceId ||
                            message.to.deviceId == _selectedUser?.deviceId;

                        if (!isSelected) return const SizedBox.shrink();

                        return Align(
                          alignment:
                              isMe
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color:
                                  isMe
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context).colorScheme.secondary,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment:
                                  isMe
                                      ? CrossAxisAlignment.end
                                      : CrossAxisAlignment.start,
                              children: [
                                Text(
                                  message.text,
                                  style: TextStyle(
                                    color: isMe ? Colors.white : null,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  // Message Input
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _messageController,
                            decoration: InputDecoration(
                              hintText:
                                  _selectedUser != null
                                      ? 'Type a message...'
                                      : 'Select a user to start chatting',
                              border: const OutlineInputBorder(),
                            ),
                            enabled: _selectedUser != null && _isConnected,
                            onSubmitted: (_) => _sendMessage(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.send),
                          onPressed:
                              _selectedUser != null && _isConnected
                                  ? _sendMessage
                                  : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
