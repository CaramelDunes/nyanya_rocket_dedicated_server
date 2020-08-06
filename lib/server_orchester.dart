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
  final int id;
  final int port;
  final GameParameters gameParameters;
  final Set<int> tickets;

  _ServerParameters(
      {@required this.id,
      this.tickets,
      @required this.port,
      @required this.gameParameters});
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
            id: _rng.nextInt(2 << 32),
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
        id: _rng.nextInt(1 << 32),
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
      print('[STATS] Killed after 4 minutes.');
      Isolate.current.kill();
    });

    GameServer gameServer = GameServer(
      board: parameters.gameParameters.board,
      port: parameters.port,
      playerCount: parameters.gameParameters.playerCount,
      gameDuration: const Duration(minutes: 3),
      tickets: parameters.tickets,
      onGameEnd: (scores) {
        print('[STATS] Game ${parameters.id} ended with scores $scores');
      },
    );

    Timer(Duration(minutes: 1), () {
      if (!gameServer.running) {
        print('[STATS] Killed after 1 minute of inactivity.');
        Isolate.current.kill();
      }
    });
  }
}
