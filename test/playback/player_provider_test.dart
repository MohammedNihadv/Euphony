import 'dart:math';

import 'package:euphony/domain/artist_ref.dart';
import 'package:euphony/domain/song.dart';
import 'package:euphony/playback/player_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Song _song(String id) =>
    Song(id: id, title: 'Track $id', artists: const <ArtistRef>[]);

/// A queue of [count] songs in natural order, sitting on [current].
QueueState _queue(int count, {int current = 0, List<int>? order}) => QueueState(
  queue: [for (var i = 0; i < count; i++) _song('$i')],
  currentIndex: current,
  order: order ?? List<int>.generate(count, (i) => i),
);

void main() {
  group('buildOrder', () {
    test('is the natural order when not shuffling', () {
      expect(buildOrder(length: 4, current: 2, shuffle: false), [0, 1, 2, 3]);
    });

    test('puts the playing track first so shuffling does not skip it', () {
      final order = buildOrder(
        length: 5,
        current: 3,
        shuffle: true,
        random: Random(1),
      );
      expect(order.first, 3);
      expect(order.toSet(), {0, 1, 2, 3, 4});
    });

    test('shuffles the whole list when nothing is playing yet', () {
      final order = buildOrder(
        length: 4,
        current: -1,
        shuffle: true,
        random: Random(1),
      );
      expect(order.toSet(), {0, 1, 2, 3});
    });

    test('handles an empty queue', () {
      expect(buildOrder(length: 0, current: -1, shuffle: true), isEmpty);
    });
  });

  group('QueueState.nextIndex', () {
    test('advances through the order', () {
      expect(_queue(3, current: 0).nextIndex(wrap: false), 1);
      expect(_queue(3, current: 1).nextIndex(wrap: false), 2);
    });

    test('stops at the end without wrap', () {
      expect(_queue(3, current: 2).nextIndex(wrap: false), isNull);
    });

    test('returns to the start with wrap, which is what repeat-all means', () {
      expect(_queue(3, current: 2).nextIndex(wrap: true), 0);
    });

    test('follows the shuffled order, not the queue order', () {
      final shuffled = _queue(4, current: 2, order: [2, 0, 3, 1]);
      expect(shuffled.nextIndex(wrap: false), 0);
      expect(
        _queue(4, current: 3, order: [2, 0, 3, 1]).nextIndex(wrap: false),
        1,
      );
    });

    test('is null for an empty queue rather than throwing', () {
      expect(const QueueState().nextIndex(wrap: true), isNull);
    });
  });

  group('QueueState.previousIndex', () {
    test('steps back through the order', () {
      expect(_queue(3, current: 2).previousIndex(wrap: false), 1);
    });

    test('stops at the start without wrap', () {
      expect(_queue(3, current: 0).previousIndex(wrap: false), isNull);
    });

    test('wraps to the last track with repeat on', () {
      expect(_queue(3, current: 0).previousIndex(wrap: true), 2);
    });
  });

  group('QueueState.ordered', () {
    test('lists the queue in playback order, paired with queue indices', () {
      final shuffled = _queue(3, order: [2, 0, 1]);
      expect(
        shuffled.ordered.map((e) => e.$1).toList(),
        [2, 0, 1],
        reason: 'the queue screen shows what plays next, not album order',
      );
      expect(shuffled.ordered.map((e) => e.$2.id).toList(), ['2', '0', '1']);
    });

    test('drops indices that no longer address a track', () {
      // A malformed order must not crash the queue screen.
      const state = QueueState(queue: [], currentIndex: -1, order: [0, 1]);
      expect(state.ordered, isEmpty);
    });
  });

  group('PlaybackNotifier', () {
    /// A container holding a real [queueProvider], disposed after each test.
    ({PlaybackNotifier notifier, QueueState Function() read}) harness(
      int count, {
      int startIndex = 0,
    }) {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(queueProvider.notifier)
        ..playQueue([
          for (var i = 0; i < count; i++) _song('$i'),
        ], startIndex: startIndex);
      return (notifier: notifier, read: () => container.read(queueProvider));
    }

    group('reorder', () {
      test('moves a row down', () {
        final h = harness(4)..notifier.reorder(0, 2);
        expect(h.read().order, [1, 2, 0, 3]);
      });

      test('moves a row up', () {
        final h = harness(4)..notifier.reorder(3, 1);
        expect(h.read().order, [0, 3, 1, 2]);
      });

      test('is a no-op when the row does not move', () {
        final h = harness(3)..notifier.reorder(1, 1);
        expect(h.read().order, [0, 1, 2]);
      });

      test('ignores an out-of-range row instead of throwing', () {
        final h = harness(3)
          ..notifier.reorder(9, 0)
          ..notifier.reorder(-1, 0);
        expect(h.read().order, [0, 1, 2]);
      });

      test('does not change which track is playing', () {
        final h = harness(4, startIndex: 2)..notifier.reorder(0, 3);
        expect(h.read().currentIndex, 2);
        expect(h.read().currentSong?.id, '2');
      });

      test('changes what plays next', () {
        // Order starts [0,1,2,3] on track 0; move track 3 to sit right after.
        final h = harness(4)..notifier.reorder(3, 1);
        expect(h.read().nextIndex(wrap: false), 3);
      });
    });

    group('removeFromQueue', () {
      test('drops the track and reindexes the order', () {
        final h = harness(4)..notifier.removeFromQueue(1);
        expect(h.read().queue.map((s) => s.id).toList(), ['0', '2', '3']);
        expect(h.read().order, [0, 1, 2]);
      });

      test('keeps playing the same track when an earlier one is removed', () {
        final h = harness(4, startIndex: 2)..notifier.removeFromQueue(0);
        expect(h.read().currentSong?.id, '2');
      });
    });

    group('applyShuffle', () {
      test('restores natural order when switched off', () {
        final h = harness(5, startIndex: 3)
          ..notifier.applyShuffle(shuffle: true, random: Random(3))
          ..notifier.applyShuffle(shuffle: false);
        expect(h.read().order, [0, 1, 2, 3, 4]);
      });

      test('keeps the playing track at the front when switched on', () {
        final h = harness(5, startIndex: 3)
          ..notifier.applyShuffle(shuffle: true, random: Random(3));
        expect(h.read().order.first, 3);
        expect(h.read().currentSong?.id, '3');
      });
    });
  });

  group('pickAudioStreamUrl', () {
    Map<String, dynamic> format({
      required String mime,
      String? url,
      int bitrate = 0,
      String? cipher,
    }) => <String, dynamic>{
      'mimeType': mime,
      'url': ?url,
      'bitrate': bitrate,
      'signatureCipher': ?cipher,
    };

    test('prefers the highest-bitrate audio-only format', () {
      final url = pickAudioStreamUrl(<String, dynamic>{
        'adaptiveFormats': [
          format(mime: 'audio/mp4', url: 'low', bitrate: 64000),
          format(mime: 'audio/webm', url: 'high', bitrate: 160000),
          format(mime: 'video/mp4', url: 'video', bitrate: 900000),
        ],
      });
      expect(url, 'high');
    });

    test('skips formats whose URL is ciphered rather than returning null', () {
      final url = pickAudioStreamUrl(<String, dynamic>{
        'adaptiveFormats': [
          format(mime: 'audio/mp4', bitrate: 320000, cipher: 's=abc'),
          format(mime: 'audio/mp4', url: 'plain', bitrate: 128000),
        ],
      });
      expect(url, 'plain');
    });

    test('falls back to a muxed format when no audio-only stream exists', () {
      final url = pickAudioStreamUrl(<String, dynamic>{
        'adaptiveFormats': [format(mime: 'video/mp4', url: 'v', bitrate: 1)],
        'formats': [format(mime: 'video/mp4', url: 'muxed', bitrate: 500000)],
      });
      expect(url, 'muxed');
    });

    test('returns null when nothing is playable', () {
      expect(
        pickAudioStreamUrl(<String, dynamic>{
          'adaptiveFormats': [
            format(mime: 'audio/mp4', bitrate: 128000, cipher: 's=abc'),
          ],
        }),
        isNull,
      );
    });

    test('survives a streamingData block of the wrong shape', () {
      expect(pickAudioStreamUrl(<String, dynamic>{}), isNull);
      expect(
        pickAudioStreamUrl(<String, dynamic>{'adaptiveFormats': 'nonsense'}),
        isNull,
      );
      expect(
        pickAudioStreamUrl(<String, dynamic>{
          'adaptiveFormats': [1, 'two', null],
        }),
        isNull,
      );
    });
  });

  group('ResolvedStream', () {
    test('treats a URL with no expiry as stale', () {
      expect(const ResolvedStream('https://x/y').isStale, isTrue);
    });

    test('treats a URL expiring far in the future as usable', () {
      final future =
          DateTime.now().add(const Duration(hours: 5)).millisecondsSinceEpoch ~/
          1000;
      expect(ResolvedStream('https://x/y?expire=$future').isStale, isFalse);
    });

    test('treats a URL that already expired as stale', () {
      final past =
          DateTime.now()
              .subtract(const Duration(hours: 1))
              .millisecondsSinceEpoch ~/
          1000;
      expect(ResolvedStream('https://x/y?expire=$past').isStale, isTrue);
    });
  });
}
