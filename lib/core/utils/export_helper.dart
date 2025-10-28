import 'package:excel/excel.dart' hide Border, TextSpan;
import 'package:intl/intl.dart';
import 'package:universal_html/html.dart' as html;
import 'package:flutter/material.dart';

import '../../data/models/history_model.dart';
import 'date_formatter.dart';

/// Export history data to Excel file dan trigger download
Future<void> exportHistoryToExcel(
  BuildContext context,
  List<History> history,
) async {
  try {
    debugPrint('[EXPORT] Exporting today\'s history only');
    debugPrint('[EXPORT] History item count: ${history.length}');

    if (history.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Tidak ada data untuk di-export")),
      );
      return;
    }

    // Create Excel file with proper initialization
    final excel = Excel.createExcel();

    // Remove default sheet and create new one
    if (excel.tables.containsKey('Sheet1')) {
      excel.delete('Sheet1');
    }

    excel.rename(excel.tables.keys.first, 'History');
    final sheet = excel.tables['History'];

    if (sheet == null) {
      throw Exception('Gagal membuat sheet History');
    }

    debugPrint('[EXPORT] Creating header row...');

    // Add header
    sheet.insertRowIterables([
      TextCellValue('Action'),
      TextCellValue('Rak'),
      TextCellValue('Level'),
      TextCellValue('Timestamp (UTC)'),
      TextCellValue('Waktu Indonesia (WIB)'),
    ], 0);

    debugPrint('[EXPORT] Adding ${history.length} data rows...');

    // Add data rows
    int rowIndex = 1;
    for (var item in history) {
      final readableDate = formatDateTimeIndonesia(item.timestamp);
      final isoFormat = item.timestamp.toIso8601String();

      sheet.insertRowIterables([
        TextCellValue(item.action),
        IntCellValue(item.col),
        IntCellValue(item.row),
        TextCellValue(isoFormat),
        TextCellValue(readableDate),
      ], rowIndex);

      rowIndex++;
    }

    debugPrint('[EXPORT] Total rows added: $rowIndex');

    // Get bytes
    final excelBytes = excel.encode();
    debugPrint('[EXPORT] Excel bytes: ${excelBytes?.length ?? 0}');

    if (excelBytes == null || excelBytes.isEmpty) {
      throw Exception('Gagal generate Excel file - bytes kosong');
    }

    // Download file (web)
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final filename = 'history_export_$timestamp.xlsx';

    debugPrint('[EXPORT] Creating blob and download link...');

    final blob = html.Blob([excelBytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute('download', filename)
      ..click();
    html.Url.revokeObjectUrl(url);

    debugPrint('[EXPORT] File download triggered: $filename');

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Export berhasil: $filename (${history.length} records)",
        ),
      ),
    );
  } catch (e, stackTrace) {
    debugPrint('[EXPORT] ERROR: $e');
    debugPrint('[EXPORT] Stack: $stackTrace');

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Export gagal: $e")),
    );
  }
}
