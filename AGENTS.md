# Repository guidance for agents

- Follow the existing Flutter and Dart conventions in this repository.
- Preserve the current provider-based architecture and keep UI state separate from platform-channel logic.
- Before finishing changes, run `flutter format .` and `flutter analyze`.
- Prefer `debugPrint` over `print` for diagnostics.
- Keep Android MethodChannel payload shapes compatible with the native side.
- Avoid unnecessary dynamic casts and prefer strongly typed code.
