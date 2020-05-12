import 'dart:io' show Platform;

import 'package:nyanya_rocket_cloud_server/http_interface.dart';

const String capacityEnvName = 'GAME_SERVER_CAPACITY';
const int defaultCapacity = 20;

Future main(List<String> arguments) async {
  Map<String, String> environment = Platform.environment;

  int capacity = defaultCapacity;

  if (environment[capacityEnvName] != null) {
    capacity = int.tryParse(environment[capacityEnvName]) ?? defaultCapacity;
  }
  print('[INFO] Starting server with capacity $capacity');

  HttpInterface httpInterface = HttpInterface(capacity: capacity);

  await httpInterface.serve();
}
