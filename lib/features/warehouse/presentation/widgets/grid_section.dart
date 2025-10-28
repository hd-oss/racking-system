import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../logic/racking_notifier.dart';

class GridSection extends ConsumerWidget {
  final bool isMobile;
  const GridSection({super.key, required this.isMobile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final racking = ref.watch(rackingProvider);

    if (racking.isEmpty) {
      return const Center(child: Text('No racks available'));
    }

    final maxRow =
        racking.fold<int>(0, (prev, r) => r.row > prev ? r.row : prev);
    final maxCol =
        racking.fold<int>(0, (prev, r) => r.col > prev ? r.col : prev);

    // Buat map untuk akses cepat
    final rackMap = {
      for (var rack in racking) '${rack.row}-${rack.col}': rack,
    };

    const double cellWidth = 60.0; // Lebar tetap setiap sel
    const double cellAspectRatio = 16 / 10; // Aspect ratio 16:10
    const double cellHeight = cellWidth / cellAspectRatio;

    Widget buildRacking() {
      // Grid utama
      final grid = GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: maxCol,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
              childAspectRatio: 16 / 10),
          itemCount: maxRow * maxCol,
          itemBuilder: (context, index) {
            final row = maxRow - (index ~/ maxCol); // Membalik row
            final col = index % maxCol + 1;
            final rack = rackMap['$row-$col'];

            Color color;
            if (rack == null || !rack.active) {
              color = Colors.grey[200]!;
            } else {
              color = rack.occupied ? Colors.red : Colors.green;
            }

            return Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(3),
              ),
            );
          });

      // Bungkus grid + label row
      final gridWithRowLabels = Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label row di kiri
          Column(
            children: List.generate(
                maxRow,
                (i) => Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      height: cellHeight, // Tinggi sama dengan tinggi sel grid
                      width: 30,
                      child: Center(child: Text('${maxRow - i}')),
                    )),
          ),
          // Grid
          SizedBox(
              width: (cellWidth * maxCol) + (4 * (maxCol - 1)), // Lebar total
              height: (cellHeight * maxRow) + (4 * (maxRow - 1)),
              child: grid),
        ],
      );

      // Tambahkan label kolom di bawah
      final gridWithLabels = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          gridWithRowLabels,
          Row(children: [
            const SizedBox(width: 30), // ruang kosong sejajar label row
            ...List.generate(
                maxCol,
                (i) => Container(
                    margin: const EdgeInsets.only(right: 4),
                    width: cellWidth,
                    child: Center(child: Text('${i + 1}')))),
          ]),
        ],
      );

      // Scroll 2 arah
      return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: gridWithLabels,
          ));
    }

    return Column(
      children: [
        Container(
            padding: const EdgeInsets.all(8),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.blueGrey,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Text('RA',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  )),
            )),
        buildRacking(),
        const SizedBox(height: 12),
        Row(
          children: [
            _legendItem(Colors.green, "Available"),
            const SizedBox(width: 6),
            _legendItem(Colors.red, "Occupied"),
          ],
        ),
      ],
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
          width: isMobile ? 10 : 20,
          height: isMobile ? 10 : 20,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          )),
      const SizedBox(width: 6),
      Text(label),
    ]);
  }
}
