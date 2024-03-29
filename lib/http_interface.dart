import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'new_server_info.dart';
import 'server_parameters.dart';
import 'server_orchester.dart';

class _ServerInfo {
  final int totalCapacity;
  final int usedCapacity;

  _ServerInfo({required this.totalCapacity, required this.usedCapacity});

  Map<String, dynamic> toJson() =>
      {'totalCapacity': totalCapacity, 'usedCapacity': usedCapacity};
}

class HttpInterface {
  final ServerOrchester _serverOrchester;

  HttpInterface({required int capacity})
      : _serverOrchester = ServerOrchester(capacity: capacity);

  Future<void> serve({int port = 8080}) async {
    HttpServer server = await HttpServer.bind(
      InternetAddress.anyIPv6,
      port,
    );

    print('[INFO] Listening on $port');

    await for (HttpRequest request in server) {
      unawaited(_handleRequest(request));
    }
  }

  Future _handleLaunchRequest(HttpRequest request) async {
    String content = await utf8.decoder.bind(request).join();
    Map<String, dynamic> data = jsonDecode(content) as Map<String, dynamic>;

    GameParameters parameters;
    try {
      parameters = GameParameters.fromJson(data);
    } catch (e) {
      print('[ERROR] Bad game parameters format: $content');

      request.response.statusCode = HttpStatus.badRequest;
      request.response.add(utf8.encode('Bad Request'));
      return request.response.close();
    }

    NewServerInfo? newServerInfo =
        await _serverOrchester.launchServer(parameters);

    if (newServerInfo == null) {
      print('[ERROR] Could not launch server');
      request.response.statusCode = HttpStatus.internalServerError;
      request.response.add(utf8.encode('Internal Server Error'));
      return request.response.close();
    }

    request.response.statusCode = HttpStatus.ok;
    request.response.add(utf8.encode(jsonEncode(newServerInfo.toJson())));
    return request.response.close();
  }

  Future _handleInfoRequest(HttpRequest request) {
    _ServerInfo serverInfo = _ServerInfo(
        totalCapacity: _serverOrchester.capacity,
        usedCapacity: _serverOrchester.instanceCount);

    request.response.statusCode = HttpStatus.ok;
    request.response.headers.contentType = ContentType.json;
    request.response.add(utf8.encode(jsonEncode(serverInfo.toJson())));
    return request.response.close();
  }

  Future _handleTestRequest(HttpRequest request) async {
    bool result = await _serverOrchester.testCapacity();

    request.response.statusCode = HttpStatus.ok;
    request.response.add(utf8.encode('Test ${result ? 'passed' : 'failed'}'));
    return request.response.close();
  }

  Future _handleNotFound(HttpRequest request) {
    print(
        '[WARN] Not Found: ${request.uri}, ${request.connectionInfo?.remoteAddress.address}');
    HttpResponse response = request.response;
    response.statusCode = HttpStatus.notFound;
    response.add(utf8.encode('Not Found'));
    return response.close();
  }

  Future _handleRequest(HttpRequest request) async {
    try {
      // print(
      //     '[INFO] Received ${request.method} request: ${request.uri.path} from ${request.connectionInfo.remoteAddress}.');

      if (request.method == 'GET') {
        switch (request.uri.path) {
          case '/info':
            return _handleInfoRequest(request);

          case '/test':
            return _handleTestRequest(request);

          default:
            break;
        }
      } else if (request.method == 'POST') {
        switch (request.uri.path) {
          case '/launch':
            return _handleLaunchRequest(request);

          default:
            break;
        }
      }

      return _handleNotFound(request);
    } catch (e) {
      print('[ERROR] Could not handle request: $e');
    }
  }
}
