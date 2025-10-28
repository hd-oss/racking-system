class History {
  final String action; // "IN" atau "OUT"
  final int row;
  final int col;
  final DateTime timestamp;

  History({
    required this.action,
    required this.row,
    required this.col,
    required this.timestamp,
  });

  // Convert ke Map untuk simpan di database (Back4App / JSON)
  Map<String, dynamic> toMap() {
    return {
      'action': action,
      'row': row,
      'col': col,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  // Factory untuk membuat dari Map (misalnya dari ParseObject atau JSON)
  factory History.fromMap(Map<String, dynamic> map) {
    return History(
      action: map['action'] ?? '',
      row: map['row'] ?? 0,
      col: map['col'] ?? 0,
      timestamp: DateTime.tryParse(map['timestamp'] ?? '') ?? DateTime.now(),
    );
  }

  @override
  String toString() {
    return "$action ($row,$col) @ ${timestamp.toString().substring(0, 19)}";
  }
}
