import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import 'player_provider.dart';

enum SleepTimerPreset {
  off('Off', null),
  m15('15 minutes', Duration(minutes: 15)),
  m30('30 minutes', Duration(minutes: 30)),
  m60('60 minutes', Duration(minutes: 60)),
  endOfTrack('End of track', null);

  const SleepTimerPreset(this.label, this.duration);
  final String label;
  final Duration? duration;
}

class SleepTimerState {
  const SleepTimerState({
    required this.preset,
    this.remaining,
    this.finishCurrentSong = false,
  });

  final SleepTimerPreset preset;
  final Duration? remaining;
  final bool finishCurrentSong;

  bool get isActive => preset != SleepTimerPreset.off;

  SleepTimerState copyWith({
    SleepTimerPreset? preset,
    Duration? remaining,
    bool? finishCurrentSong,
  }) {
    return SleepTimerState(
      preset: preset ?? this.preset,
      remaining: remaining ?? this.remaining,
      finishCurrentSong: finishCurrentSong ?? this.finishCurrentSong,
    );
  }
}

final sleepTimerProvider =
    NotifierProvider<SleepTimerNotifier, SleepTimerState>(
  SleepTimerNotifier.new,
);

class SleepTimerNotifier extends Notifier<SleepTimerState> {
  Timer? _timer;

  @override
  SleepTimerState build() {
    ref.listen<AsyncValue<PlayerState>>(
      playerStateProvider,
      (previous, next) {
        if (!state.isActive) return;
        if (state.finishCurrentSong) {
          final processingState = next.asData?.value.processingState;
          if (processingState == ProcessingState.completed) {
            _triggerSleep();
          }
        }
      },
    );

    ref.onDispose(() {
      _timer?.cancel();
    });

    return const SleepTimerState(preset: SleepTimerPreset.off);
  }

  void setPreset(SleepTimerPreset preset) {
    _timer?.cancel();
    if (preset == SleepTimerPreset.off) {
      state = const SleepTimerState(preset: SleepTimerPreset.off);
      return;
    }

    if (preset == SleepTimerPreset.endOfTrack) {
      state = const SleepTimerState(
        preset: SleepTimerPreset.endOfTrack,
        finishCurrentSong: true,
      );
      return;
    }

    state = SleepTimerState(
      preset: preset,
      remaining: preset.duration,
      finishCurrentSong: false,
    );

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final current = state.remaining;
      if (current == null || current.inSeconds <= 1) {
        _triggerSleep();
      } else {
        state = state.copyWith(
          remaining: Duration(seconds: current.inSeconds - 1),
        );
      }
    });
  }

  void _triggerSleep() {
    _timer?.cancel();
    ref.read(playerControllerProvider).pause();
    state = const SleepTimerState(preset: SleepTimerPreset.off);
  }
}
