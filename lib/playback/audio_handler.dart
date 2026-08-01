import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../core/log.dart';
import '../domain/song.dart';
import 'player_provider.dart';

final _log = logFor('audio_service');

/// Bridges Euphony's player to the OS media session.
///
/// This existed before but nothing ever constructed it: `AudioService.init` was
/// never called and the Android manifest declared no service, so there was no
/// notification, no lock-screen controls, and playback was killed the moment the
/// app went to the background — fatal for a music client.
///
/// It owns no playback state. [PlayerController] remains the single place that
/// decides what plays; this mirrors that outward and forwards commands back.
class EuphonyAudioHandler extends BaseAudioHandler with SeekHandler {
  EuphonyAudioHandler(this._container) {
    _publishTransportState();
    _watchSong();
  }

  final ProviderContainer _container;
  final List<StreamSubscription<void>> _subs = [];
  ProviderSubscription<Song?>? _songSub;

  PlayerController get _controller => _container.read(playerControllerProvider);

  AudioPlayer get _player => _container.read(audioPlayerProvider);

  DateTime _lastEmit = DateTime.fromMillisecondsSinceEpoch(0);

  /// Mirrors the player's own streams into [playbackState].
  void _publishTransportState() {
    _subs.add(_player.playerStateStream.listen((_) => _emit(force: true)));
    // Position is not on `playerStateStream`; without it the notification's
    // scrubber never moves. Throttled to max 2 emits/second so Android's
    // notification channel doesn't get flooded.
    _subs.add(
      _player.positionStream.listen((_) {
        final now = DateTime.now();
        if (now.difference(_lastEmit).inMilliseconds > 500) {
          _emit();
        }
      }),
    );
    _subs.add(_player.durationStream.listen((_) => _emit(force: true)));
  }

  void _watchSong() {
    _songSub = _container.listen<Song?>(activeSongProvider, (previous, next) {
      mediaItem.add(next == null ? null : _toMediaItem(next));
    }, fireImmediately: true);
  }

  void _emit({bool force = false}) {
    _lastEmit = DateTime.now();
    final playing = _player.playing;
    playbackState.add(
      PlaybackState(
        controls: [
          MediaControl.skipToPrevious,
          if (playing) MediaControl.pause else MediaControl.play,
          MediaControl.skipToNext,
        ],
        systemActions: const {MediaAction.seek},
        // Collapsed notification shows prev, play/pause, next
        androidCompactActionIndices: const [0, 1, 2],
        processingState: _mapProcessingState(_player.processingState),
        playing: playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
        updateTime: DateTime.now(),
      ),
    );
  }

  static AudioProcessingState _mapProcessingState(ProcessingState state) =>
      switch (state) {
        ProcessingState.idle => AudioProcessingState.idle,
        ProcessingState.loading => AudioProcessingState.loading,
        ProcessingState.buffering => AudioProcessingState.buffering,
        ProcessingState.ready => AudioProcessingState.ready,
        ProcessingState.completed => AudioProcessingState.completed,
      };

  MediaItem _toMediaItem(Song song) {
    // Prefer the highest resolution artwork (600x600) for clean, crisp media notification images
    final artworkStr =
        song.artwork?.max ?? song.artwork?.high ?? song.artworkUrl;
    return MediaItem(
      id: song.id,
      title: song.title,
      artist: song.artistNames,
      album: song.albumTitle,
      duration: song.duration,
      artUri: artworkStr == null ? null : Uri.tryParse(artworkStr),
      extras: const {
        // Use our signature Neo-Brutalist Electric Violet accent (#6A4BE8) so
        // Android/ColorOS tints the media controls in our brand aesthetic.
        'android.media.notification.color': 0xFF6A4BE8,
      },
    );
  }

  // Play and pause used to both call `togglePlayPause`, so a lock-screen "play"
  // arriving while audio was already playing would pause it instead.
  @override
  Future<void> play() => _controller.play();

  @override
  Future<void> pause() => _controller.pause();

  @override
  Future<void> seek(Duration position) => _controller.seek(position);

  @override
  Future<void> skipToNext() => _controller.skipNext();

  @override
  Future<void> skipToPrevious() => _controller.skipPrevious();

  @override
  Future<void> stop() async {
    await _controller.stop();
    await super.stop();
  }

  Future<void> close() async {
    for (final sub in _subs) {
      await sub.cancel();
    }
    _subs.clear();
    _songSub?.close();
    _log.fine('audio handler closed');
  }
}
