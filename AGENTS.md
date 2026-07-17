# Repository guidance for agents

## Project context
- This repository is an Android-exclusive default SMS replacement app built with Flutter, Provider, and custom Kotlin MethodChannels.
- The architecture is a two-tier provider model: global app state for conversation threads and a scoped provider for the active chat screen.
- The app reads SMS data directly from Android system content providers and uses native Android side channels for sending and receiving messages.

## Architecture map
- [lib/main.dart](lib/main.dart) initializes Flutter, requests runtime permissions, checks default SMS app status, listens for native SMS events, and routes between the inbox and setup screen.
- [lib/providers/app_state.dart](lib/providers/app_state.dart) holds the global reactive thread list and updates previews when inbound SMS data arrives.
- [lib/screens/chat_list_screen.dart](lib/screens/chat_list_screen.dart) renders the inbox list and navigates into a conversation thread.
- [lib/screens/chat_messages_screen.dart](lib/screens/chat_messages_screen.dart) manages the active thread UI, message bubbles, and sending state.
- [lib/services/sms_channel.dart](lib/services/sms_channel.dart) wraps the native MethodChannel bridge for SMS operations.
- [lib/services/notification_service.dart](lib/services/notification_service.dart) handles notification permission setup.

## Working conventions
- Follow the existing Flutter and Dart conventions in this repository.
- Preserve the current provider-based architecture and keep UI state separate from platform-channel logic.
- Keep Android MethodChannel payload shapes compatible with the native side.
- Prefer strongly typed code and avoid unnecessary dynamic casts.
- Prefer `debugPrint` over `print` for diagnostics.
- Before finishing changes, run `flutter format .` and `flutter analyze`.

## Current implementation priorities
- Keep the live inbound SMS flow wired into the global app state and, when relevant, into the active chat screen via the scoped provider.
- Preserve optimistic message behavior for outbound sends while remaining compatible with the native Android SMS flow.
- Avoid introducing a local database layer unless the architecture explicitly requires it.
