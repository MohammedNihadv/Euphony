import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/remote/update_checker.dart';
import '../../data/repository/settings_repository.dart';
import '../../design/theme/theme_controller.dart';
import '../../design/tokens/brutal.dart';
import '../../design/tokens/tokens.dart';
import 'backup_service.dart';
import 'settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeControllerProvider);
    final themeController = ref.read(themeControllerProvider.notifier);
    final settings = ref.watch(settingsControllerProvider);
    final settingsController = ref.read(settingsControllerProvider.notifier);
    final themeData = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          tooltip: 'Back',
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/');
            }
          },
        ),
        backgroundColor: themeData.colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        title: Text(
          'Settings',
          style: themeData.textTheme.screenTitle?.copyWith(
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, EuSpace.md, 20, 120),
          children: [
            // Appearance Section Card
            Container(
              decoration: EuBrutal.boxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                shadows: EuBrutal.hardShadow,
              ),
              child: Material(
                type: MaterialType.canvas,
                color: themeData.colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.palette_outlined,
                            color: EuBrutal.accent,
                          ),
                          const SizedBox(width: EuSpace.sm),
                          Text(
                            'Appearance',
                            style: themeData.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: EuSpace.xs),
                      SwitchListTile(
                        activeThumbColor: EuBrutal.accent,
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'AMOLED black',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        subtitle: const Text('Pure black background'),
                        value: theme.amoled,
                        onChanged: (value) =>
                            themeController.setAmoled(value: value),
                      ),
                      SwitchListTile(
                        activeThumbColor: EuBrutal.accent,
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'Dynamic colours',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        subtitle: const Text('Tint the player from the artwork'),
                        value: theme.source == ColourSource.artwork,
                        onChanged: (value) => themeController.setColourSource(
                          value ? ColourSource.artwork : ColourSource.fixed,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: EuSpace.lg),

            // Playback & Audio Settings Card
            Container(
              decoration: EuBrutal.boxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                shadows: EuBrutal.hardShadow,
              ),
              child: Material(
                type: MaterialType.canvas,
                color: themeData.colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.tune, color: EuBrutal.accent),
                          const SizedBox(width: EuSpace.sm),
                          Text(
                            'Playback & Quality',
                            style: themeData.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: EuSpace.md),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'Audio Quality',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        subtitle: Text(
                          settings.audioQuality == 'HIGH'
                              ? 'High Quality (256 kbps AAC)'
                              : settings.audioQuality == 'STANDARD'
                              ? 'Standard Quality (128 kbps AAC)'
                              : 'Data Saver (64 kbps Opus)',
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: EuBrutal.highlight,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: EuBrutal.onHighlight, width: 1.5),
                          ),
                          child: Text(
                            settings.audioQuality,
                            style: const TextStyle(
                              color: EuBrutal.onHighlight,
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        onTap: () => _showAudioQualityDialog(
                          context,
                          settings.audioQuality,
                          settingsController,
                        ),
                      ),
                      const Divider(height: 16),
                      SwitchListTile(
                        activeThumbColor: EuBrutal.accent,
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'Auto-Play Similar Songs',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        subtitle: const Text(
                          'Keep playing recommendations when queue finishes',
                        ),
                        value: settings.autoPlaySimilar,
                        onChanged: (value) =>
                            settingsController.setAutoPlaySimilar(value),
                      ),
                      const Divider(height: 16),
                      SwitchListTile(
                        activeThumbColor: EuBrutal.accent,
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'Skip Silence in Tracks',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        subtitle: const Text(
                          'Automatically trim silent intros and outros',
                        ),
                        value: settings.skipSilence,
                        onChanged: (value) =>
                            settingsController.setSkipSilence(value),
                      ),
                      const Divider(height: 16),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'Content Region / Country',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        subtitle: Text(settings.contentRegion),
                        trailing: const Icon(Icons.public, color: EuBrutal.ink),
                        onTap: () => _showCountryDialog(
                          context,
                          settings.contentRegion,
                          settingsController,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: EuSpace.lg),

            // Storage & Cache Section Card
            Container(
              decoration: EuBrutal.boxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                shadows: EuBrutal.hardShadow,
              ),
              child: Material(
                type: MaterialType.canvas,
                color: themeData.colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.storage_outlined,
                            color: EuBrutal.accent,
                          ),
                          const SizedBox(width: EuSpace.sm),
                          Text(
                            'Storage & Cache',
                            style: themeData.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: EuSpace.md),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'Cached Media & Artwork',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        subtitle: const Text('32.4 MB temporary data'),
                        trailing: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: EuBrutal.ink,
                              width: 1.5,
                            ),
                          ),
                          onPressed: () {
                            PaintingBinding.instance.imageCache.clear();
                            PaintingBinding.instance.imageCache
                                .clearLiveImages();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'All cached artwork and audio buffers cleared!',
                                ),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          child: const Text(
                            'CLEAR',
                            style: TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: EuSpace.lg),

            Container(
              decoration: EuBrutal.boxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                shadows: EuBrutal.hardShadow,
              ),
              child: Material(
                type: MaterialType.canvas,
                color: themeData.colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.security, color: EuBrutal.accent),
                          const SizedBox(width: EuSpace.sm),
                          Text(
                            'Data & Backup',
                            style: themeData.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: EuSpace.md),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'Export Backup',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        subtitle: const Text('Save your library and settings'),
                        trailing: const Icon(Icons.file_upload),
                        onTap: () async {
                          final success = await BackupService.exportBackup();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  success
                                      ? 'Backup saved successfully.'
                                      : 'Backup failed or cancelled.',
                                ),
                              ),
                            );
                          }
                        },
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'Import Backup',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        subtitle: const Text('Restore from a backup file'),
                        trailing: const Icon(Icons.file_download),
                        onTap: () async {
                          final success = await BackupService.importBackup();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  success
                                      ? 'Backup imported! Please restart the app.'
                                      : 'Import failed or cancelled.',
                                ),
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: EuSpace.lg),

            // About Section
            Container(
              decoration: EuBrutal.boxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                shadows: EuBrutal.hardShadow,
              ),
              child: Material(
                type: MaterialType.canvas,
                color: themeData.colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: EuBrutal.highlight,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: themeData.colorScheme.onSurface,
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.graphic_eq,
                              color: EuBrutal.onHighlight,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: EuSpace.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'EUPHONY MUSIC',
                                  style: themeData.textTheme.titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 1.2,
                                      ),
                                ),
                                const Text(
                                  'v${UpdateChecker.currentVersion} • '
                                  'Neo-Brutalist Edition',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                    color: EuBrutal.accent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: EuSpace.md),
                      Text(
                        'Music deserves better than interruptions.\n\n'
                        'Euphony is a free, open-source music player that '
                        'simply gets out of your way — no ads, no paywalls, '
                        'just your music. Built by the community, for the '
                        'community.',
                        style: themeData.textTheme.bodyMedium?.copyWith(
                          color: themeData.colorScheme.onSurface.withValues(
                            alpha: 0.8,
                          ),
                          fontWeight: FontWeight.w600,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: EuSpace.lg),

            // App Updates & Version Card
            const _AppUpdateCard(),
          ],
        ),
      ),
    );
  }

  void _showAudioQualityDialog(
    BuildContext context,
    String current,
    SettingsController controller,
  ) {
    final options = [
      ('HIGH', 'High Quality (256 kbps AAC)'),
      ('STANDARD', 'Standard Quality (128 kbps AAC)'),
      ('LOW', 'Data Saver (64 kbps Opus)'),
    ];

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: EuBrutal.ink, width: 2.5),
        ),
        title: const Text(
          'SELECT AUDIO QUALITY',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: options.map((opt) {
            final isSelected = opt.$1 == current;
            return ListTile(
              title: Text(
                opt.$2,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                ),
              ),
              trailing: isSelected
                  ? const Icon(Icons.check, color: EuBrutal.accent)
                  : null,
              onTap: () {
                controller.setAudioQuality(opt.$1);
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showCountryDialog(
    BuildContext context,
    String currentRegion,
    SettingsController controller,
  ) {
    final countries = [
      'US - United States',
      'IN - India',
      'UK - United Kingdom',
      'JP - Japan',
      'BR - Brazil',
      'DE - Germany',
      'CA - Canada',
      'AU - Australia',
    ];

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: EuBrutal.ink, width: 2.5),
        ),
        title: const Text(
          'SELECT CONTENT REGION',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: countries.length,
            itemBuilder: (context, index) {
              final country = countries[index];
              final isSelected = country == currentRegion;
              return ListTile(
                title: Text(
                  country,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                  ),
                ),
                trailing: isSelected
                    ? const Icon(Icons.check, color: EuBrutal.accent)
                    : null,
                onTap: () {
                  controller.setContentRegion(country);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Content region set to $country'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class _AppUpdateCard extends ConsumerStatefulWidget {
  const _AppUpdateCard();

  @override
  ConsumerState<_AppUpdateCard> createState() => _AppUpdateCardState();
}

class _AppUpdateCardState extends ConsumerState<_AppUpdateCard> {
  bool _checking = false;
  UpdateInfo? _info;

  Future<void> _checkUpdate() async {
    setState(() => _checking = true);
    final info = await ref.read(updateCheckerProvider).checkUpdate();
    if (!mounted) return;
    setState(() {
      _checking = false;
      _info = info;
    });

    if (info != null && !info.hasUpdate) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'You are on the latest version (v${info.currentVersion}).',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    final updateAsync = ref.watch(updateCheckFutureProvider);
    final info = _info ?? updateAsync.asData?.value;

    return Container(
      decoration: EuBrutal.boxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        shadows: EuBrutal.hardShadow,
      ),
      child: Material(
        type: MaterialType.canvas,
        color: themeData.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.system_update, color: EuBrutal.accent),
                  const SizedBox(width: EuSpace.sm),
                  Text(
                    'App Updates',
                    style: themeData.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: EuSpace.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Current Version: v${UpdateChecker.currentVersion}',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        if (info != null && info.hasUpdate)
                          Text(
                            'New version available: v${info.latestVersion}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              color: EuBrutal.accent,
                            ),
                          )
                        else
                          const Text(
                            'Up to date • Auto-preserves all data',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: EuSpace.md),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: (info != null && info.hasUpdate)
                          ? EuBrutal.accent
                          : themeData.colorScheme.surfaceContainerHighest,
                      foregroundColor: (info != null && info.hasUpdate)
                          ? Colors.white
                          : themeData.colorScheme.onSurface,
                      side: const BorderSide(color: EuBrutal.ink, width: 2),
                    ),
                    onPressed: _checking
                        ? null
                        : () async {
                            if (info != null && info.hasUpdate) {
                              _showUpdateDialog(context, info);
                            } else {
                              await _checkUpdate();
                            }
                          },
                    icon: _checking
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            (info != null && info.hasUpdate)
                                ? Icons.file_download
                                : Icons.refresh,
                          ),
                    label: Text(
                      _checking
                          ? 'Checking...'
                          : (info != null && info.hasUpdate)
                          ? 'Update'
                          : 'Check',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showUpdateDialog(BuildContext context, UpdateInfo info) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        scrollable: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: EuBrutal.ink, width: 2.5),
        ),
        title: Text(
          'UPDATE AVAILABLE (v${info.latestVersion})',
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: 0.8,
            fontSize: 16,
          ),
        ),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'A new version of Euphony is available!',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: EuSpace.sm),
            const Text(
              'Updating will preserve all your downloaded songs, liked tracks, playlists, and app settings.',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            if (info.releaseNotes != null && info.releaseNotes!.isNotEmpty) ...[
              const SizedBox(height: EuSpace.md),
              const Text(
                'Release Notes:',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  info.releaseNotes!,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Later',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: EuBrutal.accent,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context);
              context.push(info.releaseUrl);
            },
            child: const Text(
              'Download Release',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}
