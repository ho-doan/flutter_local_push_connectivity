import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:flutter_push_common/flutter_push_common.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_cors_headers/shelf_cors_headers.dart';

import '../core/connection.dart';

class ApiHandler {
  final Set<IServer> _servers;
  final Router _router = Router();
  HttpServer? _httpServer;

  ApiHandler(this._servers) {
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
    log('REST API server listening on port ${_httpServer?.port}');
  }

  Future<void> stop() async {
    await _httpServer?.close();
    _httpServer = null;
  }

  Future<Response> _handleSendMessage(Request request) async {
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;

      try {
        final textMessage = TextMessage.fromJson(data);
        final lst = await Future.wait(_servers.map((e) => e.send(textMessage)));
        final success = lst.any((e) => e == true);

        return Response.ok(
          jsonEncode({
            'success': success,
            'message':
                success ? 'Message sent successfully' : 'Message not sent',
          }),
          headers: {HttpHeaders.contentTypeHeader: ContentType.json.toString()},
        );
      } catch (e) {
        return Response(
          HttpStatus.badRequest,
          body: jsonEncode({'error': 'Invalid message format'}),
        );
      }
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to send message: $e'}),
        headers: {HttpHeaders.contentTypeHeader: ContentType.json.toString()},
      );
    }
  }
}
