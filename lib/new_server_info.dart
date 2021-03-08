class NewServerInfo {
  final Set<int> tickets;
  final int? port;

  NewServerInfo({required this.tickets, this.port});

  Map<String, dynamic> toJson() => {'port': port, 'tickets': tickets.toList()};
}
