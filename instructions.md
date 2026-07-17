Here is your structured blueprint, ready to be copied and pasted directly into your agents.md file.
This format is optimized for AI agents and developer contexts, providing structural clarity, explicit codebase mappings, a clean checklist state, and clear next steps. [1, 2, 3, 4, 5] 

# Glossa Messenger — Project Status & Handover Blueprint
This file serves as the definitive state documentation and roadmap for `glossa_messenger`, an Android-exclusive default SMS replacement application built with Flutter, Provider, and custom Kotlin MethodChannels.
---## 🏗️ System Architecture & Data Topology

┌───────────────────────────────────────┐
│ Android OS / Carrier Layer │
└───────┬───────────────────────▲───────┘
│ (Incoming SMS) │ (SmsManager)
▼ │
┌─────────────────────────────────┐ ┌────────┴────────────────────────┐
│ SmsReceiver.kt │ │ MainActivity.kt │
│ (Native Android Receiver) │ │ (Native Android Sender) │
└────────────────┬────────────────┘ └────────▲────────────────────────┘
│ (MethodChannel Loop) │ (MethodChannel Call)
▼ │
┌────────────────────────────────────────────────┴────────────────────────┐
│ │
│ Flutter Core Engine │
│ │
│ ┌────────────────────────┐ ┌───────────────────┐ ┌────────────────┐ │
│ │ Direct Cursor Query │ │ AppState │ │ Local System │ │
│ │ (content://sms/...) │ │ (In-Memory State) │ │ Notifications │ │
│ └──────────┬─────────────┘ └─────────▲─────────┘ └───────▲────────┘ │
└─────────────┼──────────────────────────┼────────────────────┼───────────┘
│ │ │
▼ │ │
┌────────────────────────────────────────┴────────────────────┴───────────┐
│ Flutter UI │
│ [ Conversation Thread List View ] ───> [ Chat Screen View ] │
└─────────────────────────────────────────────────────────────────────────┘ [6, 7, 8] 


---

## 🛠️ Stack Configuration Matrix

*   **UI Engine**: Flutter (Material 3 Adaptive Theme)
*   **State Architecture**: Two-Tiered Provider Model (Global `AppState` + Short-Lived Scoped `ChatScreenProvider`)
*   **Data Pipeline**: Direct Android SQLite Cursor mapping via native `content://sms` context wrappers. (No local app database sync layer required).
*   **Native Binds**: Custom `MethodChannel` signatures (`com.fshangala.apps.glossa_messenger/sms`).
*   **Background Handling**: Native Android `BroadcastReceiver` + High-Priority `NotificationChannel` APIs.

---

## 🗂️ Codebase File Map

*   `android/app/src/main/AndroidManifest.xml` — Core OS registry, intent routing filters, and platform permission locks.
*   `android/app/src/main/kotlin/.../MainActivity.kt` — Channel gateway handling text querying capabilities and carrier dispatching queues.
*   `android/app/src/main/kotlin/.../SmsReceiver.kt` — Asynchronous background broadcast interceptor and notification router.
*   `lib/main.dart` — App engine initializer, runtime permissions checker, and default-app router.
*   `lib/services/sms_channel.dart` — Type-safe wrapper routing platform channel invocations into clean async Dart futures.
*   `lib/services/notification_service.dart` — Handlers checking OS-level notification privileges.
*   `lib/models/conversation_thread.dart` — Data models mapping local OS database thread structures.
*   `lib/models/sms_message.dart` — Data models parsing historical individual texts with optimistic UI generators.
*   `lib/providers/app_state.dart` — Global reactive parent container tracking master threads and handling background-to-foreground alerts.
*   `lib/providers/chat_screen_provider.dart` — Isolated temporary layout wrapper managing text entries and optimistic dispatches.
*   `lib/screens/chat_list_screen.dart` — UI inbox list panel utilizing pull-to-refresh cursors.
*   `lib/screens/chat_messages_screen.dart` — UI thread bubble conversational timeline view.

---

## 📋 Project Status Tracking

### 🟢 Phase 1: Native Android Configuration & Plumbing
- [x] Configure permissions matrix (`SEND_SMS`, `RECEIVE_SMS`, `READ_SMS`, `POST_NOTIFICATIONS`) in the app manifest.
- [x] Register required intent components (`SmsReceiver`, `MmsReceiver`, `HeadlessSmsSendService`) to satisfy default application status requirements.
- [x] Write native Kotlin stub classes for `MmsReceiver` and `HeadlessSmsSendService` to ensure compilations clear safely.
- [x] Implement native Kotlin `isDefaultSmsApp()` checker via the `RoleManager` framework layer.
- [x] Construct native Kotlin `requestDefaultSmsApp()` to launch the standard system app-picker prompt dialog.

### 🟢 Phase 2: Direct-Read Cursor Engine & Models
- [x] Build native Kotlin cursor logic querying `content://sms/conversations` safely using lazy column projections.
- [x] Build native Kotlin cursor logic querying individual text components inside `getMessagesForThread(threadId)`.
- [x] Design distinct standalone Dart model domains (`ConversationThread` and `SmsMessage`).
- [x] Create the clean asynchronous Dart bridge service (`SmsChannelService`).
- [x] Formulate the entry `main.dart` script to block standard views until mandatory system parameters pass validation checks.

### 🟢 Phase 3: Message Dispatching & Visual Layout Interfaces
- [x] Implement the primary `ChatListScreen` rendering custom avatar initials and dynamic unread badge metrics.
- [x] Build out the `ChatMessagesScreen` chat-bubble screen structure.
- [x] Wire Android's native `SmsManager` into `MainActivity.kt` to transmit texts live via SIM carrier channels.
- [x] Add an optimistic UI pipeline inside `ChatScreenProvider` to append text components before carrier towers return network flags.
- [x] Integrate layout `ScrollController` listeners to auto-lock list windows to the bottom when messages load.

### 🟡 Phase 4: Inbound Interception & Live Screen Sync
- [x] Build `SmsReceiver.kt` combining raw multi-part SMS strings arriving via standard network antennas.
- [x] Wire `NotificationManager` in Kotlin to trigger high-priority system banners if the UI engine is closed or backgrounded.
- [x] Bind the live background listener to `main.dart` to inject new message packets safely into the global parent memory layer.
- [ ] **CURRENT TASK**: Wire the foreground listener loop into `ChatMessagesScreen` via the widget context tree. If the user is currently reading an active thread, incoming message feeds must pipe live into the bubble window view in real time (using `appendIncomingLiveMessageIfMatch`).
- [ ] Lock typing controls and send action icons during raw asynchronous carrier dispatch processing windows.

### 🔴 Phase 5: Production Post-MVP Polish
- [ ] Implement checks identifying dead SIM carrier states or network signal dropouts to deliver a graceful transmission failure UI.
- [ ] Build a contact resolution lookup engine query channel running against Android's native addresses database (`ContactsContract`) to display actual names instead of raw numbers.

---

## 🎯 Next Steps for the Next Session
To complete Phase 4, modify `lib/screens/chat_messages_screen.dart` to register a context listener to `AppState`. When a message lands over the air, check if the sender matches the currently viewed text thread. If true, inject it live into the `ChatScreenProvider` layout array so the conversation refreshes right before the user's eyes without them having to exit and re-enter the chat.

------------------------------
Would you like to tackle the Live Screen Sync Integration task next to finalize Phase 4 of the project? Let me know!

[1] [https://layer5.io](https://layer5.io/blog/ai/agentsmd-one-file-to-guide-them-all/)
[2] [https://developer.android.com](https://developer.android.com/studio/gemini/best-practices)
[3] [https://lucek.ai](https://lucek.ai/blogs/agent-skills)
[4] [https://medium.com](https://medium.com/@stephen.palmer_5653/the-5x-engineer-agentic-coding-workflow-for-speed-and-quality-97518f90f146)
[5] [https://towardsdatascience.com](https://towardsdatascience.com/what-ai-agents-should-never-do-on-their-own/)
[6] [https://blogs.oracle.com](https://blogs.oracle.com/apex/scaffolding-oracle-apex-applications-using-blueprints)
[7] [https://www.linkedin.com](https://www.linkedin.com/pulse/complete-agent-engineering-playbook-agentsmd-skillsmd-zeelan-shaik-dzpic)
[8] [https://ai.sulat.com](https://ai.sulat.com/codex-guide-agents-md-cascading-rules-and-the-optional-agents-override-md-1f4c81767e92)
