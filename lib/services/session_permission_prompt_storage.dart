abstract interface class SessionPermissionPromptStorage {
  Future<bool> loadSessionNotificationExplanationPresented();

  Future<void> saveSessionNotificationExplanationPresented(bool value);
}
