import 'dart:io' show Platform;

import 'package:nyanya_rocket_cloud_server/http_interface.dart';

const String keyEnvName = 'GAME_SERVER_KEY';
const String capacityEnvName = 'GAME_SERVER_CAPACITY';

const String defaultKey = '00000000000000000000000000000000';
const int defaultCapacity = 20;

Future main(List<String> arguments) async {
  Map<String, String> environment = Platform.environment;

  String key = environment[keyEnvName] ?? defaultKey;
  int capacity = defaultCapacity;

  if (environment[capacityEnvName] != null) {
    capacity = int.tryParse(environment[capacityEnvName]) ?? defaultCapacity;
  }
  print('[INFO] Starting server with capacity $capacity');

  HttpInterface httpInterface = HttpInterface(key: key, capacity: capacity);

  await httpInterface.serve();
}
