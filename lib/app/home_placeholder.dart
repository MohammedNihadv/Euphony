import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/providers.dart';
import '../data/repository/settings_repository.dart';
import '../design/theme/theme_controller.dart';
import '../design/tokens/tokens.dart';

/// Phase 0 scaffolding: exercises the wiring end to end — Riverpod, Drift, the
/// token layer, and the artwork-derived colour pipeline — so a broken
/// foundation shows up before any feature is built on it. Replaced by the real
/// shell in phase 3.
class HomePlaceholder extends ConsumerWidget {
  const HomePlaceholder({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeControllerProvider);
    final controller = ref.read(themeControllerProvider.notifier);
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Euphony')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          EuSpace.screenGutter,
          0,
          EuSpace.screenGutter,
          EuSpace.xxxl,
        ),
        children: [
          Text('Foundations', style: text.sectionTitle),
          const SizedBox(height: EuSpace.sm),
          Text(
            'Phase 0 — Riverpod, Drift and the design system are wired.',
            style: text.itemSubtitle,
          ),
          const SizedBox(height: EuSpace.xl),

          Text('Theme', style: text.sectionTitle),
          const SizedBox(height: EuSpace.sm),
          SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(value: ThemeMode.system, label: Text('System')),
              ButtonSegment(value: ThemeMode.light, label: Text('Light')),
              ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
            ],
            selected: {theme.mode},
            onSelectionChanged: (selection) =>
                controller.setMode(selection.first),
          ),
          SwitchListTile(
            title: const Text('AMOLED dark'),
            value: theme.amoled,
            onChanged: (value) => controller.setAmoled(value: value),
          ),
          SwitchListTile(
            title: const Text('Colour from artwork'),
            value: theme.source == ColourSource.artwork,
            onChanged: (value) => controller.setColourSource(
              value ? ColourSource.artwork : ColourSource.fixed,
            ),
          ),

          const SizedBox(height: EuSpace.lg),
          Text('Artwork palette', style: text.sectionTitle),
          const SizedBox(height: EuSpace.sm),
          const _SwatchStrip(),

          const SizedBox(height: EuSpace.xl),
          Text('Search history (Drift)', style: text.sectionTitle),
          const SizedBox(height: EuSpace.sm),
          const _SearchHistoryDemo(),
        ],
      ),
    );
  }
}

/// Tapping a swatch repaints the whole app from that "artwork".
class _SwatchStrip extends ConsumerWidget {
  const _SwatchStrip();

  static const _samples = <String, Color>{
    'violet': Color(0xFF7C5CFF),
    'ember': Color(0xFFE2574C),
    'moss': Color(0xFF3F8F5B),
    'sand': Color(0xFFD9A441),
    'ocean': Color(0xFF2A6FA8),
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Wrap(
      spacing: EuSpace.sm,
      runSpacing: EuSpace.sm,
      children: [
        for (final entry in _samples.entries)
          _Swatch(
            name: entry.key,
            colour: entry.value,
            onTap: () async {
              final image = await _solidImage(entry.value);
              await ref
                  .read(themeControllerProvider.notifier)
                  .applyArtwork(entry.key, image);
            },
          ),
        ActionChip(
          label: const Text('Reset'),
          onPressed: ref.read(themeControllerProvider.notifier).resetArtwork,
        ),
      ],
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.name,
    required this.colour,
    required this.onTap,
  });

  final String name;
  final Color colour;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: EuShape.artwork,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(color: colour, borderRadius: EuShape.artwork),
        alignment: Alignment.bottomLeft,
        padding: const EdgeInsets.all(EuSpace.xs),
        child: Text(
          name,
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: Colors.white),
        ),
      ),
    );
  }
}

/// Stands in for album art until the data layer can fetch real thumbnails.
Future<ImageProvider> _solidImage(Color colour) async {
  final recorder = ui.PictureRecorder();
  ui.Canvas(
    recorder,
  ).drawRect(const ui.Rect.fromLTWH(0, 0, 64, 64), ui.Paint()..color = colour);
  final image = await recorder.endRecording().toImage(64, 64);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return MemoryImage(Uint8List.view(bytes!.buffer));
}

class _SearchHistoryDemo extends ConsumerWidget {
  const _SearchHistoryDemo();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dao = ref.watch(searchHistoryDaoProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            FilledButton(
              onPressed: () => dao.record(
                'query ${DateTime.now().millisecondsSinceEpoch % 1000}',
              ),
              child: const Text('Add row'),
            ),
            const SizedBox(width: EuSpace.sm),
            TextButton(onPressed: dao.clear, child: const Text('Clear')),
          ],
        ),
        const SizedBox(height: EuSpace.sm),
        StreamBuilder(
          stream: dao.watchRecent(),
          builder: (context, snapshot) {
            final rows = snapshot.data ?? const [];
            if (rows.isEmpty) {
              return Text(
                'No rows yet.',
                style: Theme.of(context).textTheme.itemSubtitle,
              );
            }
            return Column(
              children: [
                for (final row in rows)
                  ListTile(
                    title: Text(row.query),
                    subtitle: Text(row.lastUsedAt.toString()),
                    trailing: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => dao.remove(row.query),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}
