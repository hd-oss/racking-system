import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

import 'features/warehouse/presentation/warehouse_app.dart';
import 'config/env_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize date formatting for Indonesia locale
  await initializeDateFormatting('id', null);

  // Get Parse credentials from environment
  const appId = EnvConfig.parseAppId;
  const serverUrl = EnvConfig.parseServerUrl;
  const clientKey = EnvConfig.parseClientKey;

  await Parse().initialize(
    appId,
    serverUrl,
    clientKey: clientKey,
    autoSendSessionId: true,
  );
  runApp(const ProviderScope(child: WarehouseApp()));
}
