import 'dart:convert';
import 'dart:io';

import 'package:flutter_push_common/flutter_push_common.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_cors_headers/shelf_cors_headers.dart';

import '../server.dart' as app_server;

class ApiHandler<T, R> {
  final app_server.IServer<T, R> _server;
  final Router _router = Router();
  HttpServer? _httpServer;

  ApiHandler(this._server) {
    _router.post('/send-message', _handleSendMessage);
  }

  Future<void> start({
    String host = Constants.mHost,
    int port = Constants.apiPort,
  }) async {
    final handler = const Pipeline()
        .addMiddleware(logRequests())
        .addMiddleware(corsHeaders())
        .addHandler(_router);

    _httpServer = await shelf_io.serve(handler, host, port);
    print('REST API server listening on port ${_httpServer?.port}');
  }

  Future<void> stop() async {
    await _httpServer?.close();
    _httpServer = null;
  }

  Future<Response> _handleSendMessage(Request request) async {
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;

      // Validate required fields
      if (!data.containsKey('deviceId') || !data.containsKey('message')) {
        return Response(
          HttpStatus.badRequest,
          body: jsonEncode({
            'error': 'Missing required fields: deviceId and message',
          }),
        );
      }

      final message = data['message'] as String;

      // Create message object
      const fromUser = User(
        deviceName: 'server',
        deviceId: 'server',
        status: UserStatus.online,
      );

      final toUser = User.fromJson(data);

      final textMessage = TextMessage(
        from: fromUser,
        to: toUser,
        message: message,
      );

      // Send message
      final success = _server.sendMessage(textMessage);

      return Response.ok(
        jsonEncode({
          'success': success,
          'message': success ? 'Message sent successfully' : 'Message not sent',
        }),
        headers: {HttpHeaders.contentTypeHeader: ContentType.json.toString()},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to send message: $e'}),
        headers: {HttpHeaders.contentTypeHeader: ContentType.json.toString()},
      );
    }
  }
}
