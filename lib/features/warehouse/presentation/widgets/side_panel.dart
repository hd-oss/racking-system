import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:universal_html/html.dart' as html;
import 'package:excel/excel.dart' hide Border, TextSpan;

import '../../logic/history_notifier.dart';
import '../../logic/input_notifier.dart';
import '../../logic/racking_notifier.dart';

class SidePanel extends ConsumerWidget {
  final bool isMobile;
  const SidePanel(this.isMobile, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final input = ref.watch(inputProvider);
    final history = ref.watch(historyProvider);

    // Helper function for logging import process
    void logImport(String message) {
      final timestamp = timeFormat.format(DateTime.now());
      debugPrint('[$timestamp] [IMPORT] $message');
    }

    void showLoadingDialog(BuildContext context) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    void showErrorDialog(BuildContext context, String message) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Terjadi Kesalahan"),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Tutup"),
            ),
          ],
        ),
      );
    }

    Widget buildHistoryList() {
      if (history.isEmpty) {
        return const Center(
          child: Text('Tidak ada history hari ini'),
        );
      }

      return ListView.builder(
        shrinkWrap: true,
        physics: isMobile
            ? const NeverScrollableScrollPhysics()
            : const AlwaysScrollableScrollPhysics(),
        itemCount: history.length,
        itemBuilder: (context, idx) {
          final item = history[idx];
          return ListTile(
            dense: true,
            title: Text.rich(
              TextSpan(children: [
                TextSpan(
                    text: item.action,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: item.action == "IN" ? Colors.red : Colors.green,
                    )),
                TextSpan(text: " (${item.col}, ${item.row})"),
              ]),
            ),
            subtitle: Text(_formatDateTimeIndonesia(item.timestamp),
                style: const TextStyle(color: Colors.grey)),
          );
        },
      );
    }

    void exportHistory(BuildContext context, WidgetRef ref) {
      try {
        final history = ref.read(historyProvider);

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
          final readableDate = _formatDateTimeIndonesia(item.timestamp);
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

    void importRackingStatus(BuildContext context, WidgetRef ref) async {
      try {
        logImport('📂 Membuka file picker untuk memilih file Excel...');

        // Open file picker for Excel files
        FilePickerResult? result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['xlsx'],
        );

        if (result == null) {
          logImport('⚠️ User membatalkan pemilihan file');
          return;
        }

        logImport('✅ File dipilih: ${result.files.first.name}');
        logImport(
            '📊 Ukuran file: ${(result.files.first.size / 1024).toStringAsFixed(2)} KB');

        final bytes = result.files.first.bytes;
        if (bytes == null) {
          logImport('❌ ERROR: Tidak dapat membaca bytes dari file');
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("File tidak dapat dibaca")),
          );
          return;
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
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("File Excel kosong atau tidak valid")),
          );
          return;
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
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Tidak ada data valid dalam file")),
          );
          return;
        }

        // Update Racking status
        logImport('🚀 Memulai proses update racking ke database...');
        await ref.read(rackingProvider.notifier).importRackingData(excelRows);

        logImport('✅ Data racking berhasil diupdate');
        logImport('📊 Total racking yang diupdate: $validRowCount units');

        // Reload history after racking update (cloud code akan membuat history entries)
        logImport('🔄 Reload history dari database...');
        await ref.read(historyProvider.notifier).loadHistory();
        logImport('✅ History berhasil di-reload');

        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text("Import berhasil: ${excelRows.length} racking units")),
        );
      } catch (e, stackTrace) {
        logImport('❌ ERROR: Exception saat import');
        logImport('   Error: $e');
        logImport('   StackTrace: $stackTrace');

        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Import gagal: $e")),
        );
      }
    }

    return Column(
      mainAxisSize: MainAxisSize.min, // 🔑 penting untuk mobile
      children: [
        // Panel Input
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Panel Input",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: "Aksi",
                  contentPadding: EdgeInsets.symmetric(horizontal: 8),
                ),
                value: input.action ?? "IN",
                items: const [
                  DropdownMenuItem(value: "IN", child: Text("IN")),
                  DropdownMenuItem(value: "OUT", child: Text("OUT")),
                ],
                onChanged: ref.read(inputProvider.notifier).updateAction,
              ),
              const SizedBox(height: 12),

              // Input Row dan Col
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        hintText: "Rak",
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 8),
                        counterText: "",
                      ),
                      maxLength: 2,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: ref.read(inputProvider.notifier).updateCol,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        hintText: "Level",
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 8),
                        counterText: "",
                      ),
                      maxLength: 2,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: ref.read(inputProvider.notifier).updateRow,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(40),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () async {
                  final notifier = ref.read(rackingProvider.notifier);
                  final historyNotifier = ref.read(historyProvider.notifier);

                  if (input.action != null &&
                      input.row != null &&
                      input.col != null) {
                    try {
                      showLoadingDialog(context);

                      await notifier.setOccupied(
                        input.row!,
                        input.col!,
                        input.action == "IN",
                      );

                      await historyNotifier.loadHistory();

                      if (!context.mounted) return;
                      Navigator.of(context).pop(); // Tutup loading

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Update berhasil ✅")),
                      );
                    } catch (e) {
                      if (!context.mounted) return;
                      Navigator.of(context).pop(); // Tutup loading
                      showErrorDialog(context, e.toString());
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Row, Col, dan Action harus diisi ⚠️"),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.send),
                label: const Text("Submit"),
              )
            ],
          ),
        ),

        // Panel Riwayat
        Flexible(
          fit: FlexFit.loose,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 4)
                ]),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Panel Riwayat",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                const RealTimeClock(),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => exportHistory(context, ref),
                        icon: const Icon(Icons.download, size: 18),
                        label: const Text("Export"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => importRackingStatus(context, ref),
                        icon: const Icon(Icons.upload, size: 18),
                        label: const Text("Import"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                isMobile
                    ? buildHistoryList()
                    : Flexible(
                        fit: FlexFit.loose,
                        child: buildHistoryList(),
                      ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class RealTimeClock extends StatefulWidget {
  const RealTimeClock({super.key});

  @override
  State<RealTimeClock> createState() => _RealTimeClockState();
}

class _RealTimeClockState extends State<RealTimeClock> {
  late Stream<DateTime> _timeStream;

  @override
  void initState() {
    super.initState();
    _timeStream = Stream.periodic(
      const Duration(seconds: 1),
      (_) => DateTime.now(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DateTime>(
      stream: _timeStream,
      builder: (context, snapshot) {
        final now = snapshot.data ?? DateTime.now();

        return Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Row(
            children: [
              Icon(Icons.access_time, size: 16, color: Colors.blue[700]),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${_formatTanggalIndonesia(now)} | ${timeFormat.format(now)} WIB',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue[900],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// DateFormat with Indonesia locale
final timeFormat = DateFormat('HH:mm:ss', 'id');
final dateFormat =
    DateFormat('EEEE, dd MMMM yyyy', 'id'); // Senin, 27 Oktober 2025
final dateTimeFormat = DateFormat(
    'EEEE, dd MMMM yyyy HH:mm:ss', 'id'); // Senin, 27 Oktober 2025 14:30:45

// Convert UTC timestamp to WIB (UTC+7)
DateTime _convertUtcToWib(DateTime utcTime) {
  // Indonesia Standard Time is UTC+7
  return utcTime.add(const Duration(hours: 7));
}

String _formatTanggalIndonesia(DateTime date) {
  final wibTime = _convertUtcToWib(date);
  return dateFormat.format(wibTime);
}

// Format datetime lengkap dengan timezone info
String _formatDateTimeIndonesia(DateTime date) {
  final wibTime = _convertUtcToWib(date);
  return '${dateTimeFormat.format(wibTime)} WIB';
}
