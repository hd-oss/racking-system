import 'package:flutter_riverpod/flutter_riverpod.dart';

class InputData {
  final String? action; // "IN" atau "OUT"
  final int? row;
  final int? col;

  InputData({this.action, this.row, this.col});

  InputData copyWith({String? action, int? row, int? col}) {
    return InputData(
      action: action ?? this.action,
      row: row ?? this.row,
      col: col ?? this.col,
    );
  }
}

class InputNotifier extends StateNotifier<InputData> {
  InputNotifier() : super(InputData(action: "IN"));

  void updateAction(String? value) =>
      state = state.copyWith(action: value);

  void updateRow(String? value) =>
      state = state.copyWith(row: int.tryParse(value ?? ''));

  void updateCol(String? value) =>
      state = state.copyWith(col: int.tryParse(value ?? ''));
}

final inputProvider = StateNotifierProvider<InputNotifier, InputData>((ref) {
  return InputNotifier();
});
