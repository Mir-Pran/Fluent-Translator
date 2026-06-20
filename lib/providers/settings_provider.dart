/// Persisted user preferences backed by shared_preferences.
///
/// Stores: theme mode (system/light/dark), auto-translate toggle, auto-detect
/// language toggle, offline mode toggle, TTS rate, and TTS accent preference.
/// Everything is exposed as a Riverpod [Notifier] so the UI rebuilds
/// reactively on change.
library;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final settingsProvider =
    NotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);

class AppSettings {
  const AppSettings({
    this.themeMode = ThemeMode.dark,
    this.autoTranslate = false,
    this.autoDetectLanguage = true,
    this.offlineMode = false,
    this.voiceRate = 0.5,
    this.useBanglaVoice = true,
  });

  final ThemeMode themeMode;
  final bool autoTranslate;
  final bool autoDetectLanguage;

  /// When true, ML Kit on-device translation is used first. Falls back to
  /// web APIs only if the model is not downloaded.
  final bool offlineMode;

  final double voiceRate;
  final bool useBanglaVoice;

  AppSettings copyWith({
    ThemeMode? themeMode,
    bool? autoTranslate,
    bool? autoDetectLanguage,
    bool? offlineMode,
    double? voiceRate,
    bool? useBanglaVoice,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      autoTranslate: autoTranslate ?? this.autoTranslate,
      autoDetectLanguage: autoDetectLanguage ?? this.autoDetectLanguage,
      offlineMode: offlineMode ?? this.offlineMode,
      voiceRate: voiceRate ?? this.voiceRate,
      useBanglaVoice: useBanglaVoice ?? this.useBanglaVoice,
    );
  }
}

const _kThemeMode = 'themeMode';
const _kAutoTranslate = 'autoTranslate';
const _kAutoDetect = 'autoDetect';
const _kOfflineMode = 'offlineMode';
const _kVoiceRate = 'voiceRate';
const _kBanglaVoice = 'banglaVoice';

class SettingsNotifier extends Notifier<AppSettings> {
  SharedPreferences? _prefs;

  @override
  AppSettings build() => const AppSettings();

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final themeIndex = _prefs!.getInt(_kThemeMode) ?? ThemeMode.system.index;
    state = AppSettings(
      themeMode: ThemeMode.values[themeIndex],
      autoTranslate: _prefs!.getBool(_kAutoTranslate) ?? false,
      autoDetectLanguage: _prefs!.getBool(_kAutoDetect) ?? true,
      offlineMode: _prefs!.getBool(_kOfflineMode) ?? false,
      voiceRate: _prefs!.getDouble(_kVoiceRate) ?? 0.5,
      useBanglaVoice: _prefs!.getBool(_kBanglaVoice) ?? true,
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await _prefs?.setInt(_kThemeMode, mode.index);
  }

  Future<void> toggleAutoTranslate() async {
    state = state.copyWith(autoTranslate: !state.autoTranslate);
    await _prefs?.setBool(_kAutoTranslate, state.autoTranslate);
  }

  Future<void> toggleAutoDetect() async {
    state = state.copyWith(autoDetectLanguage: !state.autoDetectLanguage);
    await _prefs?.setBool(_kAutoDetect, state.autoDetectLanguage);
  }

  Future<void> toggleOfflineMode() async {
    state = state.copyWith(offlineMode: !state.offlineMode);
    await _prefs?.setBool(_kOfflineMode, state.offlineMode);
  }

  Future<void> setVoiceRate(double rate) async {
    state = state.copyWith(voiceRate: rate);
    await _prefs?.setDouble(_kVoiceRate, rate);
  }

  Future<void> toggleBanglaVoice() async {
    state = state.copyWith(useBanglaVoice: !state.useBanglaVoice);
    await _prefs?.setBool(_kBanglaVoice, state.useBanglaVoice);
  }
}

/// Convenience: the resolved brightness for the current theme mode given the
/// platform brightness. Used by widgets that need to know "are we dark right
/// now?" without rebuilding on platform brightness changes.
Brightness resolvedBrightness(WidgetRef ref, Brightness platform) {
  final mode = ref.watch(settingsProvider.select((s) => s.themeMode));
  switch (mode) {
    case ThemeMode.light:
      return Brightness.light;
    case ThemeMode.dark:
      return Brightness.dark;
    case ThemeMode.system:
      return platform;
  }
}
