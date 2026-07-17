import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/conversation_thread.dart';
import '../models/sms_message.dart';
import '../providers/app_state.dart';
import '../providers/chat_screen_provider.dart';

class ChatMessagesScreen extends StatefulWidget {
  final ConversationThread thread;

  const ChatMessagesScreen({super.key, required this.thread});

  @override
  State<ChatMessagesScreen> createState() => _ChatMessagesScreenState();
}

class _ChatMessagesScreenState extends State<ChatMessagesScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Automatically animated scroll lock down helper to track new text bubbles
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. Initialize localized Screen State, pulling dependencies out of Global State
    return ChangeNotifierProvider<ChatScreenProvider>(
      create: (context) => ChatScreenProvider(
        threadId: widget.thread.threadId,
        address: widget.thread.address,
        globalAppState: context.read<AppState>(),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.thread.address,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Thread ID: ${widget.thread.threadId}',
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: Consumer<ChatScreenProvider>(
          builder: (context, chatProvider, child) {
            // Automatically trigger scroll focus down whenever message arrays populate
            WidgetsBinding.instance.addPostFrameCallback(
              (_) => _scrollToBottom(),
            );

            if (chatProvider.isLoadingMessages &&
                chatProvider.messages.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            return Column(
              children: [
                // A. Scrolling Message History Container Pane
                Expanded(
                  child: chatProvider.messages.isEmpty
                      ? const Center(child: Text('No text history found.'))
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16.0),
                          itemCount: chatProvider.messages.length,
                          itemBuilder: (context, index) {
                            final SmsMessage msg = chatProvider.messages[index];
                            return _buildMessageBubble(context, msg);
                          },
                        ),
                ),

                // B. Interactive Dispatch Typing Dock Base Channel
                _buildMessageInputDock(context, chatProvider),
              ],
            );
          },
        ),
      ),
    );
  }

  /// UI Widget: Generates stylized text message bubbles aligning with sender context
  Widget _buildMessageBubble(BuildContext context, SmsMessage message) {
    final bool isMe = message.isMe;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4.0),
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isMe
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 0),
            bottomRight: Radius.circular(isMe ? 0 : 16),
          ),
        ),
        child: Text(
          message.body,
          style: TextStyle(
            color: isMe
                ? Colors.white
                : Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  /// UI Widget: Typing text fields bar sitting above system hardware software keyboards
  Widget _buildMessageInputDock(
    BuildContext context,
    ChatScreenProvider chatProvider,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
      color: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _textController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'Text message',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 12.0),
                ),
                maxLines: null, // Dynamic expansion support for lengthy inputs
              ),
            ),
            IconButton(
              icon: chatProvider.isSending
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2.0),
                    )
                  : Icon(
                      Icons.send,
                      color: Theme.of(context).colorScheme.primary,
                    ),
              onPressed: chatProvider.isSending
                  ? null
                  : () async {
                      final text = _textController.text.trim();
                      if (text.isEmpty) return;

                      _textController.clear();
                      await chatProvider.sendTextMessage(text);
                    },
            ),
          ],
        ),
      ),
    );
  }
}
