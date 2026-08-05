class AppConfig {
  // Distributed Android builds always use the externally reachable API.
  // Keep local/emulator endpoints out of the application binary.
  static const String apiBaseUrl = 'http://14.34.103.137:8000';

  static const String doosanSectionTheme = String.fromEnvironment(
    'DOOSAN_SECTION_THEME',
    defaultValue: 'cheolwoong',
  );

  static bool get useDoosanMangomSections =>
      doosanSectionTheme.toLowerCase() == 'mangom';
}
