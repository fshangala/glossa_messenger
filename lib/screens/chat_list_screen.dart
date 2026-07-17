import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/conversation_thread.dart';
import 'chat_messages_screen.dart'; // We will build this screen next

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  @override
  void initState() {
    super.initState();
    // Pull the latest conversation data chunks out of the OS database on startup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().fetchConversations();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Glossa Messenger', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<AppState>().fetchConversations(),
          ),
        ],
      ),
      body: Consumer<AppState>(
        builder: (context, appState, child) {
          if (appState.isFetchingThreads && appState.threads.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (appState.threads.isEmpty) {
            return const Center(
              child: Text(
                'No conversations found in your database.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => appState.fetchConversations(),
            child: ListView.builder(
              itemCount: appState.threads.length,
              itemBuilder: (context, index) {
                final ConversationThread thread = appState.threads[index];
                
                // Extract a clean initials string from the phone address for the avatar bubble
                final String avatarLabel = thread.address.replaceAll(RegExp(r'\D'), '');
                final String displayInitial = avatarLabel.length >= 2 
                    ? avatarLabel.substring(avatarLabel.length - 2) 
                    : '#';

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    child: Text(displayInitial, style: TextStyle(color: Theme.of(context).colorScheme.onPrimaryContainer)),
                  ),
                  title: Text(
                    thread.address,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  subtitle: Text(
                    thread.displaySnippet,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  trailing: thread.msgCount > 0
                      ? Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${thread.msgCount}',
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        )
                      : null,
                  onTap: () {
                    // Navigate to the deep individual messaging screen view
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatMessagesScreen(thread: thread),
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}
