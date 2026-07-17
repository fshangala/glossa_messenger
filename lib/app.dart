import 'package:flutter/material.dart';
import 'package:glossa_messenger/providers/app_state.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'screens/chat_list_screen.dart';
import 'services/sms_channel.dart';

class GlossaMessengerApp extends StatefulWidget {
  const GlossaMessengerApp({super.key});

  @override
  State<GlossaMessengerApp> createState() => _GlossaMessengerAppState();
}

class _GlossaMessengerAppState extends State<GlossaMessengerApp> {
  final SmsChannelService _smsChannel = SmsChannelService();
  bool _isDefaultApp = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkSystemRequirements();
    _setupIncomingMessageListener();
  }

  /// Verifies telephony privileges and checks if we are the system default SMS app
  Future<void> _checkSystemRequirements() async {
    // A. Request explicit runtime permission to read and transmit carrier SMS texts
    Map<Permission, PermissionStatus> statuses = await [
      Permission.sms,
    ].request();

    if (statuses[Permission.sms]?.isGranted ?? false) {
      // B. Query Kotlin to see if we are currently selected as the system's primary SMS handler
      final isDefault = await _smsChannel.isDefaultSmsApp();
      if (!mounted) return;

      setState(() {
        _isDefaultApp = isDefault;
        _isLoading = false;
      });

      // If already default, fetch conversation history from the database immediately
      if (isDefault) {
        context.read<AppState>().fetchConversations();
      }
    } else {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  /// Establishes the real-time MethodChannel hook to catch live texts forwarded from SmsReceiver.kt
  void _setupIncomingMessageListener() {
    const MethodChannel(
      'com.fshangala.apps.glossa_messenger/sms',
    ).setMethodCallHandler((MethodCall call) async {
      if (call.method == 'onMessageReceived') {
        final dynamic rawData = call.arguments;
        if (rawData is Map) {
          final mapData = Map<String, dynamic>.from(rawData);

          // Inject the incoming text straight into our active global state array
          if (mounted) {
            context.read<AppState>().handleIncomingLiveSms(mapData);
          }
        }
      }
    });
  }

  /// Launches the native Android OS default app picker modal sheet
  Future<void> _requestDefaultStatus() async {
    final success = await _smsChannel.requestDefaultSmsApp();
    if (success) {
      // Re-evaluate system requirements to see if the user accepted or skipped the setup
      await _checkSystemRequirements();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Glossa Messenger',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E3A8A), // Deep executive sapphire blue
          brightness: Brightness.light,
        ),
      ),
      home: _isLoading
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : _isDefaultApp
          ? const ChatListScreen()
          : Scaffold(
              body: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.forum_outlined,
                      size: 80,
                      color: Color(0xFF1E3A8A),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Glossa Messenger',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'To query conversation history, catch real-time texts, and reply directly over carrier lines, this app must be set as your active default messaging handler.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 15, color: Colors.grey),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      onPressed: _requestDefaultStatus,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E3A8A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                      ),
                      icon: const Icon(Icons.swap_horizontal_circle_outlined),
                      label: const Text(
                        'Set as Default SMS App',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
