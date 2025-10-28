import 'package:flutter/material.dart';

import '../../../core/app_theme.dart';
import 'pages/warehouse_page.dart';

class WarehouseApp extends StatelessWidget {
  const WarehouseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Warehouse Racking',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const WarehousePage(),
    );
  }
}
