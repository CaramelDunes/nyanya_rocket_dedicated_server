import 'package:nyanya_rocket_base/nyanya_rocket_base.dart';

class GameParameters {
  final int playerCount;
  final Board board;

  GameParameters({required this.playerCount, required this.board});

  static GameParameters fromJson(Map<String, dynamic> json) {
    int playerCount = json['playerCount'];
    Board board = Board.fromJson(json['board']);

    return GameParameters(playerCount: playerCount, board: board);
  }
}
