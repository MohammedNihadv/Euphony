import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:meta/meta.dart';
import 'package:path_provider/path_provider.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart' as yt_explode;

import '../core/log.dart';
import '../data/providers.dart';
import '../data/remote/innertube/innertube_client.dart';
import '../data/remote/innertube/innertube_utils.dart';
import '../domain/song.dart';

final _log = logFor('playback');

/// The queue, and where in it playback currently sits.
///
/// [order] is the layer shuffle works on: it holds indices into [queue] in the
/// order they will actually play. Shuffling permutes [order] and leaves [queue]
/// alone, so the visible track list never reorders under the user and turning
/// shuffle back off restores the album order exactly.
@immutable
class QueueState {
  const QueueState({
    this.queue = const [],
    this.currentIndex = -1,
    this.order = const [],
  });

  final List<Song> queue;

  /// Index into [queue], not into [order].
  final int currentIndex;

  /// Indices into [queue], in playback order.
  final List<int> order;

  Song? get currentSong => currentIndex >= 0 && currentIndex < queue.length
      ? queue[currentIndex]
      : null;

  bool get isEmpty => queue.isEmpty;

  /// The queue in playback order, which is what the queue screen lists.
  ///
  /// Paired with its index into [queue], so a row can act on the right track
  /// after a shuffle has permuted the order.
  List<(int index, Song song)> get ordered => [
    for (final i in order)
      if (i >= 0 && i < queue.length) (i, queue[i]),
  ];

  /// Where [currentIndex] sits within [order], or -1.
  int get _orderPosition => order.indexOf(currentIndex);

  /// The queue index that follows the current one, or `null` at the end.
  ///
  /// With [wrap] the last track leads back to the first, which is what repeat-all
  /// means.
  int? nextIndex({required bool wrap}) {
    if (order.isEmpty) return null;
    final position = _orderPosition;
    if (position < 0) return order.first;
    if (position + 1 < order.length) return order[position + 1];
    return wrap ? order.first : null;
  }

  /// The queue index before the current one, or `null` at the start.
  int? previousIndex({required bool wrap}) {
    if (order.isEmpty) return null;
    final position = _orderPosition;
    if (position < 0) return order.first;
    if (position > 0) return order[position - 1];
    return wrap ? order.last : null;
  }

  QueueState copyWith({
    List<Song>? queue,
    int? currentIndex,
    List<int>? order,
  }) => QueueState(
    queue: queue ?? this.queue,
    currentIndex: currentIndex ?? this.currentIndex,
    order: order ?? this.order,
  );
}

/// Builds a playback order over [length] items.
///
/// When shuffling, [current] is placed first so that turning shuffle on does not
/// jump away from the track already playing.
List<int> buildOrder({
  required int length,
  required int current,
  required bool shuffle,
  Random? random,
}) {
  final indices = List<int>.generate(length, (i) => i);
  if (!shuffle) return indices;
  if (current >= 0 && current < length) {
    indices.removeAt(current);
    indices.shuffle(random);
    return [current, ...indices];
  }
  return indices..shuffle(random);
}

class PlaybackNotifier extends Notifier<QueueState> {
  @override
  QueueState build() => const QueueState();

  Song? get currentSong => state.currentSong;

  int get currentIndex => state.currentIndex;

  List<Song> get queue => state.queue;

  /// Exposed so [PlayerController] can walk the playback order without reaching
  /// into [state], which Riverpod keeps protected.
  int? nextIndex({required bool wrap}) => state.nextIndex(wrap: wrap);

  int? previousIndex({required bool wrap}) => state.previousIndex(wrap: wrap);

  void playQueue(List<Song> songs, {int startIndex = 0, bool shuffle = false}) {
    final index = songs.isEmpty ? -1 : startIndex.clamp(0, songs.length - 1);
    state = QueueState(
      queue: songs,
      currentIndex: index,
      order: buildOrder(length: songs.length, current: index, shuffle: shuffle),
    );
  }

  void setIndex(int index) {
    if (index >= 0 && index < state.queue.length) {
      state = state.copyWith(currentIndex: index);
    }
  }

  void addToQueue(Song song) {
    final newQueue = [...state.queue, song];
    state = QueueState(
      queue: newQueue,
      currentIndex: state.currentIndex < 0 ? 0 : state.currentIndex,
      // Append rather than reshuffle: a track added mid-listen should play at
      // the end, not displace the order already decided.
      order: [...state.order, newQueue.length - 1],
    );
  }

  /// Appends several songs at once — used by autoplay to extend the queue with
  /// related tracks. Songs already present are skipped so the radio does not
  /// loop the same handful of tracks.
  void addAllToQueue(List<Song> songs) {
    final existing = state.queue.map((s) => s.id).toSet();
    final fresh = songs.where((s) => existing.add(s.id)).toList();
    if (fresh.isEmpty) return;
    final newQueue = [...state.queue, ...fresh];
    final appendedOrder = [
      for (var i = 0; i < fresh.length; i++) state.queue.length + i,
    ];
    state = QueueState(
      queue: newQueue,
      currentIndex: state.currentIndex < 0 ? 0 : state.currentIndex,
      order: [...state.order, ...appendedOrder],
    );
  }

  void addNext(Song song) {
    final newQueue = [...state.queue, song];
    final newIndex = newQueue.length - 1;
    final orderPos = state.order.indexOf(state.currentIndex);
    final newOrder = [...state.order];
    if (orderPos >= 0 && orderPos + 1 <= newOrder.length) {
      newOrder.insert(orderPos + 1, newIndex);
    } else {
      newOrder.add(newIndex);
    }
    state = QueueState(
      queue: newQueue,
      currentIndex: state.currentIndex < 0 ? 0 : state.currentIndex,
      order: newOrder,
    );
  }

  void removeFromQueue(int index) {
    if (index < 0 || index >= state.queue.length) return;
    final newQueue = [...state.queue]..removeAt(index);
    var newIndex = state.currentIndex;
    if (index < state.currentIndex) {
      newIndex--;
    } else if (index == state.currentIndex) {
      newIndex = newQueue.isEmpty ? -1 : newIndex.clamp(0, newQueue.length - 1);
    }
    // Every index above the removed one shifts down by one.
    final newOrder = [
      for (final i in state.order)
        if (i != index) i > index ? i - 1 : i,
    ];
    state = QueueState(
      queue: newQueue,
      currentIndex: newIndex,
      order: newOrder,
    );
  }

  /// Moves an entry within the playback order.
  ///
  /// Both indices address [QueueState.order], not [QueueState.queue], because
  /// that is what the queue screen lists. [newIndex] is the final resting
  /// position, already accounting for the dragged row being lifted out — which
  /// is what `ReorderableListView.onReorderItem` passes. The older `onReorder`
  /// callback did not adjust it; correcting for that here as well would move
  /// the row one slot too far.
  void reorder(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= state.order.length) return;
    final newOrder = [...state.order];
    final moved = newOrder.removeAt(oldIndex);
    newOrder.insert(newIndex.clamp(0, newOrder.length), moved);
    state = state.copyWith(order: newOrder);
  }

  /// Rebuilds [QueueState.order] for a change in the shuffle setting.
  void applyShuffle({required bool shuffle, Random? random}) {
    state = state.copyWith(
      order: buildOrder(
        length: state.queue.length,
        current: state.currentIndex,
        shuffle: shuffle,
        random: random,
      ),
    );
  }

  void clearQueue() {
    state = const QueueState();
  }
}

final queueProvider = NotifierProvider<PlaybackNotifier, QueueState>(
  PlaybackNotifier.new,
);

final audioPlayerProvider = Provider<AudioPlayer>((ref) {
  final player = AudioPlayer();
  ref.onDispose(player.dispose);
  return player;
});

final activeSongProvider = Provider<Song?>((ref) {
  final queue = ref.watch(queueProvider);
  return queue.currentSong;
});

/// Whether audio is currently playing.
///
/// Driven by the player's own stream. Reading `player.playing` in a plain
/// `Provider` — as this did — samples the value once and never rebuilds, which
/// left the play/pause button stuck on whatever it showed first.
final playerStateProvider = StreamProvider<PlayerState>((ref) {
  final player = ref.watch(audioPlayerProvider);
  return player.playerStateStream;
});

final isPlayingProvider = Provider<bool>((ref) {
  final state = ref.watch(playerStateProvider).value;
  if (state == null) return false;
  // `completed` still reports `playing == true` until the next source loads.
  return state.playing && state.processingState != ProcessingState.completed;
});

/// True while a track is being resolved or buffered, so the UI can show a
/// spinner instead of a dead play button.
final isBufferingProvider = Provider<bool>((ref) {
  final state = ref.watch(playerStateProvider).value;
  return state != null &&
      (state.processingState == ProcessingState.loading ||
          state.processingState == ProcessingState.buffering);
});

final trackPositionProvider = StreamProvider<Duration>((ref) {
  final player = ref.watch(audioPlayerProvider);
  return player.positionStream;
});

/// The playing track's length.
///
/// Prefers the duration the player decoded, because InnerTube's listed duration
/// is frequently absent and sometimes disagrees with the audio stream.
final totalDurationProvider = Provider<Duration?>((ref) {
  final decoded = ref.watch(playerDurationProvider).value;
  if (decoded != null) return decoded;
  return ref.watch(activeSongProvider)?.duration;
});

final playerDurationProvider = StreamProvider<Duration?>((ref) {
  final player = ref.watch(audioPlayerProvider);
  return player.durationStream;
});

/// The last playback failure, for the UI to surface. `null` when healthy.
///
/// Without this a track that cannot be resolved just silently does nothing when
/// tapped, which reads as the app being broken.
final playbackErrorProvider = NotifierProvider<PlaybackErrorNotifier, String?>(
  PlaybackErrorNotifier.new,
);

class PlaybackErrorNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void report(String message) => state = message;

  void clear() => state = null;
}

final shuffleModeProvider = NotifierProvider<ShuffleNotifier, bool>(
  ShuffleNotifier.new,
);

class ShuffleNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void toggle() {
    state = !state;
    // Shuffle used to be a button that changed nothing; the order has to be
    // rebuilt for it to mean anything.
    ref.read(queueProvider.notifier).applyShuffle(shuffle: state);
  }
}

final repeatModeProvider = NotifierProvider<RepeatNotifier, LoopMode>(
  RepeatNotifier.new,
);

class RepeatNotifier extends Notifier<LoopMode> {
  @override
  LoopMode build() => LoopMode.off;

  void cycle() {
    state = switch (state) {
      LoopMode.off => LoopMode.all,
      LoopMode.all => LoopMode.one,
      LoopMode.one => LoopMode.off,
    };
  }
}

final playbackSpeedProvider = NotifierProvider<PlaybackSpeedNotifier, double>(
  PlaybackSpeedNotifier.new,
);

class PlaybackSpeedNotifier extends Notifier<double> {
  @override
  double build() => 1.0;

  void setSpeed(double speed) {
    state = speed;
    ref.read(audioPlayerProvider).setSpeed(speed);
  }
}

final playerControllerProvider = Provider<PlayerController>((ref) {
  final controller = PlayerController(
    player: ref.read(audioPlayerProvider),
    queue: ref.read(queueProvider.notifier),
    client: ref.read(innertubeClientProvider),
    repeatMode: () => ref.read(repeatModeProvider),
    shuffleEnabled: () => ref.read(shuffleModeProvider),
    onEnableShuffle: () {
      if (!ref.read(shuffleModeProvider)) {
        ref.read(shuffleModeProvider.notifier).toggle();
      }
    },
    onError: (message) =>
        ref.read(playbackErrorProvider.notifier).report(message),
    fetchAutoplay: (seed) async {
      // Only when the user has autoplay on; otherwise the queue simply ends.
      if (!ref.read(settingsRepositoryProvider).autoPlaySimilar) {
        return const <Song>[];
      }
      return ref.read(musicDetailRepositoryProvider).relatedSongs(seed.id);
    },
  );
  ref.onDispose(controller.dispose);
  return controller;
});

/// A stream URL together with the moment it stops working.
@immutable
class ResolvedStream {
  const ResolvedStream(this.url);

  final String url;

  /// InnerTube signs stream URLs with an `expire` timestamp and refuses them
  /// afterwards. Re-resolving is cheap; playing a dead URL is a silent failure.
  bool get isStale => isExpired(url: url);
}

class PlayerController {
  // `prefer_initializing_formals` asks for `required this._player` here, which
  // does not compile: Dart forbids named parameters that start with an
  // underscore. The fields stay private, so the initializer list is the only
  // way to assign them.
  PlayerController({
    required AudioPlayer player,
    required PlaybackNotifier queue,
    required InnertubeClient client,
    required LoopMode Function() repeatMode,
    required bool Function() shuffleEnabled,
    void Function()? onEnableShuffle,
    void Function(String message)? onError,
    Future<List<Song>> Function(Song seed)? fetchAutoplay,
    // ignore: prefer_initializing_formals
  }) : _client = client,
       // ignore: prefer_initializing_formals
       _player = player,
       // ignore: prefer_initializing_formals
       _queue = queue,
       // ignore: prefer_initializing_formals
       _repeatMode = repeatMode,
       // ignore: prefer_initializing_formals
       _shuffleEnabled = shuffleEnabled,
       // ignore: prefer_initializing_formals
       _onEnableShuffle = onEnableShuffle,
       // ignore: prefer_initializing_formals
       _onError = onError,
       // ignore: prefer_initializing_formals
       _fetchAutoplay = fetchAutoplay {
    _setupListeners();
  }

  final AudioPlayer _player;
  final PlaybackNotifier _queue;
  final InnertubeClient _client;
  final LoopMode Function() _repeatMode;
  final bool Function() _shuffleEnabled;
  final void Function()? _onEnableShuffle;
  final void Function(String message)? _onError;

  /// Returns related tracks to extend the queue with when it runs out. Null or
  /// an empty result simply ends playback.
  final Future<List<Song>> Function(Song seed)? _fetchAutoplay;

  /// Guards against firing autoplay twice for the same queue-end.
  bool _loadingAutoplay = false;

  StreamSubscription<PlayerState>? _stateSub;
  bool _disposed = false;

  /// Resolved stream URLs, keyed by video id, reused until they expire.
  final Map<String, ResolvedStream> _streams = {};

  /// Guards against two loads racing — a fast double-tap, or a track finishing
  /// while the user is already skipping.
  int _loadGeneration = 0;

  void _setupListeners() {
    // The old listener mirrored just_audio's `sequenceState.currentIndex` back
    // into the queue. Because each track is loaded as its own single-item
    // source that index is always 0, so playing track 5 immediately reset the
    // queue position to 0. The queue is the single source of truth now, and
    // the player is told what to play rather than asked.
    _stateSub = _player.playerStateStream.listen((state) {
      if (_disposed) return;
      if (state.processingState == ProcessingState.completed) {
        unawaited(_onTrackCompleted());
      }
    });
  }

  void dispose() {
    _disposed = true;
    unawaited(_stateSub?.cancel());
  }

  /// Advances when a track plays out, honouring the repeat mode.
  ///
  /// Nothing did this before, so playback simply stopped at the end of every
  /// track.
  Future<void> _onTrackCompleted() async {
    final repeat = _repeatMode();
    if (repeat == LoopMode.one) {
      await _player.seek(Duration.zero);
      await _player.play();
      return;
    }

    final next = _queue.nextIndex(wrap: repeat == LoopMode.all);
    if (next == null) {
      // End of the queue with repeat off: try to keep the music going with
      // related tracks (autoplay radio) before giving up.
      if (await _extendWithAutoplay()) {
        final resumed = _queue.nextIndex(wrap: false);
        if (resumed != null) {
          _queue.setIndex(resumed);
          await _playCurrent();
          return;
        }
      }
      // Nothing to play next: stop cleanly rather than sitting in `completed`,
      // which reports as "playing" to the UI.
      await _player.stop();
      return;
    }
    _queue.setIndex(next);
    await _playCurrent();
  }

  /// Fetches related tracks for the last song and appends them to the queue.
  /// Returns true if anything new was added.
  Future<bool> _extendWithAutoplay() async {
    final fetch = _fetchAutoplay;
    final seed = _queue.currentSong;
    if (fetch == null || seed == null || _loadingAutoplay) return false;

    _loadingAutoplay = true;
    try {
      final before = _queue.queue.length;
      final related = await fetch(seed);
      if (related.isEmpty) return false;
      _queue.addAllToQueue(related);
      final added = _queue.queue.length > before;
      if (added) _log.info('autoplay added ${related.length} related tracks');
      return added;
    } catch (error) {
      _log.warning('autoplay fetch failed: $error');
      return false;
    } finally {
      _loadingAutoplay = false;
    }
  }

  Future<void> playSong(Song song) async {
    _queue.playQueue([song], shuffle: _shuffleEnabled());
    await _playCurrent();
  }

  Future<void> playQueue(
    List<Song> songs, {
    int startIndex = 0,
    bool shuffle = false,
  }) async {
    if (shuffle && !_shuffleEnabled()) {
      _onEnableShuffle?.call();
    }
    _queue.playQueue(
      songs,
      startIndex: startIndex,
      shuffle: shuffle || _shuffleEnabled(),
    );
    await _playCurrent();
  }

  /// Jumps to a track already in the queue, for tapping a row on the queue
  /// screen. Keeps the queue and its order intact, unlike [playQueue].
  Future<void> playAt(int queueIndex) async {
    _queue.setIndex(queueIndex);
    await _playCurrent();
  }

  void addNext(Song song) {
    _queue.addNext(song);
  }

  void addToQueue(Song song) {
    _queue.addToQueue(song);
  }

  Future<void> _playCurrent() async {
    final song = _queue.currentSong;
    if (song == null) return;

    final generation = ++_loadGeneration;
    final source = await _resolveStream(song);

    // A newer load started while this one was in flight; its result wins.
    if (_disposed || generation != _loadGeneration) return;

    if (source == null) {
      _fail('Could not play "${song.title}".');
      return;
    }

    try {
      await _player.setAudioSource(AudioSource.uri(Uri.parse(source.url)));
      if (_disposed || generation != _loadGeneration) return;
      await _player.play();
      _log.info('playing: ${song.title}');
    } catch (error) {
      _log.severe('playback failed for ${song.id}: $error');
      // A URL that resolved but will not load is usually one that expired
      // between resolution and use. Drop it so the next attempt re-resolves.
      _streams.remove(song.id);
      _fail('Could not play "${song.title}".');
    }
  }

  void _fail(String message) {
    _onError?.call(message);
  }

  /// Returns a usable stream URL for [song], reusing a cached one when it has
  /// not expired.
  Future<ResolvedStream?> _resolveStream(Song song) async {
    final cached = _streams[song.id];
    if (cached != null && !cached.isStale) return cached;
    if (cached != null) {
      _log.fine('stream for ${song.id} expired, re-resolving');
    }

    // 0. Check offline downloads directory first (100% offline playback)
    try {
      final docDir = await getApplicationDocumentsDirectory();
      final file = File('${docDir.path}/offline_audio/${song.id}.audio');
      if (file.existsSync()) {
        _log.info('playing ${song.id} offline from ${file.path}');
        return ResolvedStream(file.uri.toString());
      }
    } catch (_) {}

    // Primary engine: YoutubeExplode
    // Resolves signatures, throttling challenges, and client headers automatically.
    final yt = yt_explode.YoutubeExplode();
    try {
      final manifest = await yt.videos.streamsClient.getManifest(song.id);
      final audioOnly = manifest.audioOnly;
      if (audioOnly.isNotEmpty) {
        final bestAudio = audioOnly.lastWhere(
          (item) => item.tag == 251 || item.tag == 140,
          orElse: () => audioOnly.first,
        );
        final url = bestAudio.url.toString();
        if (url.isNotEmpty) {
          _log.info(
            'resolved via YoutubeExplode (${bestAudio.tag}) for ${song.id}',
          );
          final resolved = ResolvedStream(url);
          _streams[song.id] = resolved;
          return resolved;
        }
      }
    } catch (e) {
      _log.warning(
        'YoutubeExplode failed for ${song.id}, falling back to InnertubeClient: $e',
      );
    } finally {
      // Always release the client's HTTP resources, even when getManifest threw
      // — otherwise a run of failing tracks leaks a socket pool each time.
      yt.close();
    }

    // 2. Fallback engine: InnertubeClient mobile client
    final result = await _client.player(song.id);
    return result.fold(
      (data) {
        final streamingData = data['streamingData'] as Map<String, dynamic>?;
        if (streamingData == null) {
          _log.warning('no streamingData for ${song.id}');
          return null;
        }
        final url = pickAudioStreamUrl(streamingData);
        if (url == null) {
          _log.warning('no playable audio format for ${song.id}');
          return null;
        }
        final resolved = ResolvedStream(url);
        _streams[song.id] = resolved;
        return resolved;
      },
      (failure) {
        _log.warning('failed to resolve audio for ${song.id}: $failure');
        return null;
      },
    );
  }

  Future<void> togglePlayPause() async {
    if (_player.playing) {
      await _player.pause();
    } else if (_player.processingState == ProcessingState.completed ||
        _player.audioSource == null) {
      await _playCurrent();
    } else {
      await _player.play();
    }
  }

  /// Explicit play, for media-button and lock-screen controls which must not
  /// toggle — a "play" command while already playing has to stay playing.
  Future<void> play() async {
    if (_player.playing) return;
    await togglePlayPause();
  }

  Future<void> pause() async {
    if (_player.playing) await _player.pause();
  }

  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  Future<void> skipNext() async {
    // An explicit skip wraps whenever repeat is on; repeat-one applies to
    // tracks running out, not to the user asking for the next one.
    final next = _queue.nextIndex(wrap: _repeatMode() != LoopMode.off);
    if (next == null) return;
    _queue.setIndex(next);
    await _playCurrent();
  }

  Future<void> skipPrevious() async {
    final previous = _queue.previousIndex(wrap: _repeatMode() != LoopMode.off);
    if (previous == null) {
      await _player.seek(Duration.zero);
      return;
    }
    _queue.setIndex(previous);
    await _playCurrent();
  }

  Future<void> stop() async {
    _loadGeneration++;
    await _player.stop();
    _queue.clearQueue();
  }
}

/// Chooses the best audio stream out of an InnerTube `streamingData` block.
///
/// The previous version walked the format list backwards and stopped at the
/// first `AUDIO_QUALITY_MEDIUM` entry, which picked an arbitrary format and
/// happily returned one with no `url` at all. This prefers audio-only adaptive
/// formats by bitrate, falls back to muxed formats when a track offers none
/// (common for music videos), and skips anything whose URL is ciphered, since
/// Euphony does not implement signature deciphering.
@visibleForTesting
String? pickAudioStreamUrl(Map<String, dynamic> streamingData) {
  final adaptive = streamingData['adaptiveFormats'];
  final muxed = streamingData['formats'];

  List<Map<String, dynamic>> formatsOf(Object? raw) =>
      raw is List ? raw.whereType<Map<String, dynamic>>().toList() : const [];

  int bitrateOf(Map<String, dynamic> format) {
    final value = format['bitrate'] ?? format['averageBitrate'];
    return value is num ? value.toInt() : 0;
  }

  bool isPlayable(Map<String, dynamic> format) {
    final url = format['url'];
    return url is String && url.isNotEmpty;
  }

  bool isAudio(Map<String, dynamic> format) =>
      (format['mimeType'] as String? ?? '').startsWith('audio/');

  final adaptiveFormats = formatsOf(adaptive);
  final muxedFormats = formatsOf(muxed);
  final allFormats = [...adaptiveFormats, ...muxedFormats];

  final ciphered = allFormats
      .where(isAudio)
      .where((f) => !isPlayable(f))
      .where((f) => f['signatureCipher'] != null || f['cipher'] != null)
      .length;
  if (ciphered > 0) {
    _log.warning(
      '$ciphered audio format(s) are signature-ciphered and unplayable',
    );
  }

  // Audio-only first: smaller, and the whole point for a music client.
  final audioOnly = allFormats.where(isAudio).where(isPlayable).toList()
    ..sort((a, b) => bitrateOf(b).compareTo(bitrateOf(a)));
  if (audioOnly.isNotEmpty) return audioOnly.first['url'] as String;

  // Any playable format as fallback
  final fallback = allFormats.where(isPlayable).toList()
    ..sort((a, b) => bitrateOf(b).compareTo(bitrateOf(a)));
  return fallback.isEmpty ? null : fallback.first['url'] as String;
}
