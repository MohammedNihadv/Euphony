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
  });

  final String audioQuality;
  final bool autoPlaySimilar;
  final bool skipSilence;
  final String contentRegion;

  SettingsState copyWith({
    String? audioQuality,
    bool? autoPlaySimilar,
    bool? skipSilence,
    String? contentRegion,
  }) => SettingsState(
    audioQuality: audioQuality ?? this.audioQuality,
    autoPlaySimilar: autoPlaySimilar ?? this.autoPlaySimilar,
    skipSilence: skipSilence ?? this.skipSilence,
    contentRegion: contentRegion ?? this.contentRegion,
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
}

final settingsControllerProvider =
    NotifierProvider<SettingsController, SettingsState>(SettingsController.new);
