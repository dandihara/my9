class AppConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000',
  );

  static const String doosanSectionTheme = String.fromEnvironment(
    'DOOSAN_SECTION_THEME',
    defaultValue: 'cheolwoong',
  );

  static bool get useDoosanMangomSections =>
      doosanSectionTheme.toLowerCase() == 'mangom';
}
