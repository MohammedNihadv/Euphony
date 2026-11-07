import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';

@immutable
class SettingsState {
  const SettingsState({
    required this.audioQuality,
    required this.autoPlaySimilar,
    required this.skipSilence,
    required this.contentRegion,
    required this.dynamicIsland,
    this.hideMiniPlayerWithIsland = true,
    this.discordRpcEnabled = true,
    this.crossfadeSeconds = 0,
    this.sleepFadeOut = true,
    this.audioSpeed = 1.0,
    this.audioPitch = 1.0,
    this.audioDspPreset = 'normal',
    this.closeToTray = false,
  });

  final String audioQuality;
  final bool autoPlaySimilar;
  final bool skipSilence;
  final String contentRegion;
  final bool dynamicIsland;
  final bool hideMiniPlayerWithIsland;
  final bool discordRpcEnabled;
  final int crossfadeSeconds;
  final bool sleepFadeOut;
  final double audioSpeed;
  final double audioPitch;
  final String audioDspPreset;
  final bool closeToTray;

  SettingsState copyWith({
    String? audioQuality,
    bool? autoPlaySimilar,
    bool? skipSilence,
    String? contentRegion,
    bool? dynamicIsland,
    bool? hideMiniPlayerWithIsland,
    bool? discordRpcEnabled,
    int? crossfadeSeconds,
    bool? sleepFadeOut,
    double? audioSpeed,
    double? audioPitch,
    String? audioDspPreset,
    bool? closeToTray,
  }) => SettingsState(
    audioQuality: audioQuality ?? this.audioQuality,
    autoPlaySimilar: autoPlaySimilar ?? this.autoPlaySimilar,
    skipSilence: skipSilence ?? this.skipSilence,
    contentRegion: contentRegion ?? this.contentRegion,
    dynamicIsland: dynamicIsland ?? this.dynamicIsland,
    hideMiniPlayerWithIsland:
        hideMiniPlayerWithIsland ?? this.hideMiniPlayerWithIsland,
    discordRpcEnabled: discordRpcEnabled ?? this.discordRpcEnabled,
    crossfadeSeconds: crossfadeSeconds ?? this.crossfadeSeconds,
    sleepFadeOut: sleepFadeOut ?? this.sleepFadeOut,
    audioSpeed: audioSpeed ?? this.audioSpeed,
    audioPitch: audioPitch ?? this.audioPitch,
    audioDspPreset: audioDspPreset ?? this.audioDspPreset,
    closeToTray: closeToTray ?? this.closeToTray,
  );
}

class SettingsController extends Notifier<SettingsState> {
  @override
  SettingsState build() {
    final repo = ref.watch(settingsRepositoryProvider);
    return SettingsState(
      audioQuality: repo.audioQuality,
      autoPlaySimilar: repo.autoPlaySimilar,
      skipSilence: repo.skipSilence,
      contentRegion: repo.contentRegion,
      dynamicIsland: repo.dynamicIsland,
      hideMiniPlayerWithIsland: repo.hideMiniPlayerWithIsland,
      discordRpcEnabled: repo.discordRpcEnabled,
      crossfadeSeconds: repo.crossfadeSeconds,
      sleepFadeOut: repo.sleepFadeOut,
      audioSpeed: repo.audioSpeed,
      audioPitch: repo.audioPitch,
      audioDspPreset: repo.audioDspPreset,
      closeToTray: repo.closeToTray,
    );
  }

  void setAudioQuality(String quality) {
    ref.read(settingsRepositoryProvider).setAudioQuality(quality);
    state = state.copyWith(audioQuality: quality);
  }

  void setAutoPlaySimilar(bool value) {
    ref.read(settingsRepositoryProvider).setAutoPlaySimilar(value);
    state = state.copyWith(autoPlaySimilar: value);
  }

  void setSkipSilence(bool value) {
    ref.read(settingsRepositoryProvider).setSkipSilence(value);
    state = state.copyWith(skipSilence: value);
  }

  void setContentRegion(String region) {
    ref.read(settingsRepositoryProvider).setContentRegion(region);
    state = state.copyWith(contentRegion: region);
  }

  void setDynamicIsland(bool value) {
    ref.read(settingsRepositoryProvider).setDynamicIsland(value);
    state = state.copyWith(dynamicIsland: value);
  }

  void setHideMiniPlayerWithIsland(bool value) {
    ref.read(settingsRepositoryProvider).setHideMiniPlayerWithIsland(value);
    state = state.copyWith(hideMiniPlayerWithIsland: value);
  }

  void setDiscordRpcEnabled(bool value) {
    ref.read(settingsRepositoryProvider).setDiscordRpcEnabled(value);
    state = state.copyWith(discordRpcEnabled: value);
  }

  void setCrossfadeSeconds(int value) {
    ref.read(settingsRepositoryProvider).setCrossfadeSeconds(value);
    state = state.copyWith(crossfadeSeconds: value);
  }

  void setSleepFadeOut(bool value) {
    ref.read(settingsRepositoryProvider).setSleepFadeOut(value);
    state = state.copyWith(sleepFadeOut: value);
  }

  void setAudioSpeed(double value) {
    ref.read(settingsRepositoryProvider).setAudioSpeed(value);
    state = state.copyWith(audioSpeed: value);
  }

  void setAudioPitch(double value) {
    ref.read(settingsRepositoryProvider).setAudioPitch(value);
    state = state.copyWith(audioPitch: value);
  }

  void setAudioDspPreset(String preset) {
    ref.read(settingsRepositoryProvider).setAudioDspPreset(preset);
    state = state.copyWith(audioDspPreset: preset);
  }

  void setCloseToTray(bool value) {
    ref.read(settingsRepositoryProvider).setCloseToTray(value);
    state = state.copyWith(closeToTray: value);
  }
}

final settingsControllerProvider =
    NotifierProvider<SettingsController, SettingsState>(SettingsController.new);
