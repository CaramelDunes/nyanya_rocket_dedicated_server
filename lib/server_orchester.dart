import 'dart:async';
import 'dart:collection';
import 'dart:isolate';
import 'dart:math';

import 'package:meta/meta.dart';
import 'package:nyanya_rocket_base/nyanya_rocket_base.dart';
import 'package:nyanya_rocket_cloud_server/new_server_info.dart';
import 'server_parameters.dart';

class _ServerInstance {
  final Isolate isolate;
  final DateTime launchTime;

  _ServerInstance({this.isolate, this.launchTime});
}

class _ServerParameters {
  final int port;
  final GameParameters gameParameters;
  final Set<int> tickets;

  _ServerParameters({this.tickets, this.port, this.gameParameters});
}

class ServerOrchester {
  static const int basePort = 43210;

  final Random _rng = Random();
  final int capacity;
  final List<_ServerInstance> _serverInstances = [];
  final Set<int> availablePorts = HashSet();

  ServerOrchester({@required this.capacity}) {
    for (int i = 0; i < capacity; i++) {
      availablePorts.add(basePort + i);
    }
  }

  int get instanceCount => _serverInstances.length;

  Future<bool> testCapacity() async {
    try {
      for (int i = 0; i < capacity; i++) {
        _ServerParameters serverParametersWithPort = _ServerParameters(
            port: basePort + i,
            gameParameters:
            GameParameters(board: Board.withBorder(), playerCount: 4),
            tickets: _generateTickets(4));

        ReceivePort onExitReceivePort = ReceivePort();

        Isolate newServer = await Isolate.spawn(
            _serverEntrypoint, serverParametersWithPort,
            onExit: onExitReceivePort.sendPort, paused: true);
        _ServerInstance serverInstance =
        _ServerInstance(isolate: newServer, launchTime: DateTime.now());
        _serverInstances.add(serverInstance);

        onExitReceivePort.listen((message) {
          print('[INFO] Test isolate stopped');
          _serverInstances.remove(serverInstance);
        });

        newServer.resume(newServer.pauseCapability);
      }
    } catch (e) {
      print('[ERROR] Capacity test failed with $e');
      return false;
    }

    return true;
  }

  Future<NewServerInfo> launchServer(GameParameters parameters) async {
    if (availablePorts.isEmpty) {
      return null;
    }

    int port = availablePorts.first;
    availablePorts.remove(port);

    _ServerParameters serverParametersWithPort = _ServerParameters(
        port: port,
        gameParameters: parameters,
        tickets: _generateTickets(parameters.playerCount));

    ReceivePort onExitReceivePort = ReceivePort();

    Isolate newServer = await Isolate.spawn(
        _serverEntrypoint, serverParametersWithPort,
        onExit: onExitReceivePort.sendPort, paused: true);

    _ServerInstance serverInstance =
    _ServerInstance(isolate: newServer, launchTime: DateTime.now());
    _serverInstances.add(serverInstance);

    onExitReceivePort.listen((message) {
      print('[INFO] Isolate stopped');
      availablePorts.add(port);
      _serverInstances.remove(serverInstance);
    });

    newServer.resume(newServer.pauseCapability);

    return NewServerInfo(port: port, tickets: serverParametersWithPort.tickets);
  }

  Set<int> _generateTickets(int numberOfTickets) {
    Set<int> tickets = HashSet();

    while (tickets.length < numberOfTickets) {
      tickets.add(_rng.nextInt(1 << 32));
    }

    return tickets;
  }

  static void _serverEntrypoint(_ServerParameters parameters) {
    Timer(Duration(minutes: 4), () {
      Isolate.current.kill();
    });

    GameServer gameServer = GameServer(
        board: parameters.gameParameters.board,
        port: parameters.port,
        playerCount: parameters.gameParameters.playerCount,
        tickets: parameters.tickets);

    Timer(Duration(minutes: 1), () {
      if (!gameServer.running) {
        Isolate.current.kill();
      }
    });
  }
}
