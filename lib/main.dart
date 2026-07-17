import 'package:flutter/material.dart';
import 'package:glossa_messenger/app.dart';
import 'package:provider/provider.dart';

// Import our internal application services and architecture blocks
import 'services/notification_service.dart';
import 'providers/app_state.dart';

void main() async {
  // 1. Ensure engine frames are fully initialized before calling native channels
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Trigger critical runtime notification allowance pop-ups for Android 13+
  await NotificationService.initNotificationPermissions();

  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => AppState())],
      child: const GlossaMessengerApp(),
    ),
  );
}
