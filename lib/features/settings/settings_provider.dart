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
  });

  final String audioQuality;
  final bool autoPlaySimilar;
  final bool skipSilence;
  final String contentRegion;
  final bool dynamicIsland;
  final bool hideMiniPlayerWithIsland;

  SettingsState copyWith({
    String? audioQuality,
    bool? autoPlaySimilar,
    bool? skipSilence,
    String? contentRegion,
    bool? dynamicIsland,
    bool? hideMiniPlayerWithIsland,
  }) => SettingsState(
    audioQuality: audioQuality ?? this.audioQuality,
    autoPlaySimilar: autoPlaySimilar ?? this.autoPlaySimilar,
    skipSilence: skipSilence ?? this.skipSilence,
    contentRegion: contentRegion ?? this.contentRegion,
    dynamicIsland: dynamicIsland ?? this.dynamicIsland,
    hideMiniPlayerWithIsland:
        hideMiniPlayerWithIsland ?? this.hideMiniPlayerWithIsland,
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
}

final settingsControllerProvider =
    NotifierProvider<SettingsController, SettingsState>(SettingsController.new);
