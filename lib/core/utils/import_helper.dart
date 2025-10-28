import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Import logging helper
typedef LogImportFn = void Function(String message);

/// Pick dan parse Excel file untuk import racking data
/// Returns List<List<dynamic>> dengan format [rak, level, occupied]
/// atau null jika user cancel
Future<List<List<dynamic>>?> pickAndParseExcelFile(
  BuildContext context,
  LogImportFn logImport,
) async {
  try {
    logImport('📂 Membuka file picker untuk memilih file Excel...');

    // Open file picker for Excel files
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
    );

    if (result == null) {
      logImport('⚠️ User membatalkan pemilihan file');
      return null;
    }

    logImport('✅ File dipilih: ${result.files.first.name}');
    logImport(
        '📊 Ukuran file: ${(result.files.first.size / 1024).toStringAsFixed(2)} KB');

    final bytes = result.files.first.bytes;
    if (bytes == null) {
      logImport('❌ ERROR: Tidak dapat membaca bytes dari file');
      if (!context.mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("File tidak dapat dibaca")),
      );
      return null;
    }

    logImport('🔄 Parsing file Excel (${bytes.length} bytes)...');

    // Parse Excel file
    final excel = Excel.decodeBytes(bytes);
    final sheet = excel.tables.keys.first; // Get first sheet
    logImport('📋 Sheet yang ditemukan: $sheet');

    final rows = excel.tables[sheet];

    if (rows == null || rows.rows.isEmpty || rows.rows.length < 2) {
      logImport('❌ ERROR: File Excel kosong atau struktur tidak valid');
      logImport('   Total baris: ${rows?.rows.length ?? 0}');
      if (!context.mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("File Excel kosong atau tidak valid")),
      );
      return null;
    }

    logImport('✅ File Excel valid dengan ${rows.rows.length} total baris');
    logImport(
        '📝 Header row: ${rows.rows[0].map((c) => c?.value).join(", ")}');

    // Convert Excel rows to List<List<dynamic>> format
    // Expected format: Rak | Level | Occupied (true/false or IN/OUT)
    final excelRows = <List<dynamic>>[];
    int validRowCount = 0;
    int skippedRowCount = 0;

    for (int i = 1; i < rows.rows.length; i++) {
      // Skip header
      final row = rows.rows[i];
      final excelRow = <dynamic>[];
      for (final cell in row) {
        excelRow.add(cell?.value);
      }
      if (excelRow.isNotEmpty && excelRow.length >= 3) {
        excelRows.add(excelRow);
        validRowCount++;
        logImport(
            '   Row $i: Rak=${excelRow[0]} | Level=${excelRow[1]} | Occupied=${excelRow[2]}');
      } else {
        skippedRowCount++;
      }
    }

    logImport(
        '✅ Parsing selesai: $validRowCount baris valid, $skippedRowCount baris kosong');

    if (excelRows.isEmpty) {
      logImport('❌ ERROR: Tidak ada data valid yang dapat diimport');
      if (!context.mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Tidak ada data valid dalam file")),
      );
      return null;
    }

    return excelRows;
  } catch (e, stackTrace) {
    logImport('❌ ERROR: Exception saat pick/parse file');
    logImport('   Error: $e');
    logImport('   StackTrace: $stackTrace');

    if (!context.mounted) return null;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Import gagal: $e")),
    );
    return null;
  }
}

/// Log import message dengan timestamp
String formatImportLog(String message) {
  final timestamp = DateFormat('HH:mm:ss').format(DateTime.now());
  return '[$timestamp] $message';
}
