class Racking {
  final int row;
  final int col;
  final bool occupied;
  final bool active;

  Racking({
    required this.row,
    required this.col,
    required this.occupied,
    this.active = true,
  });

  factory Racking.fromMap(Map<String, dynamic> json) {
    return Racking(
      row: json['row'],
      col: json['col'],
      occupied: json['occupied'],
      active: json['active'], // Default ke true jika tidak ada field active
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'row': row,
      'col': col,
      'occupied': occupied,
      'active': active,
    };
  }
}
