import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';

import '../../app/update_prompt.dart';
import '../../data/remote/update_checker.dart';
import '../../design/theme/theme_controller.dart';
import '../../design/tokens/brutal.dart';
import '../../design/tokens/tokens.dart';
import 'backup_service.dart';
import 'log_exporter.dart';
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
    final appVersion = ref.watch(appVersionProvider).asData?.value ?? '0.2.9';

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
                      const SizedBox(height: EuSpace.md),
                      const Text(
                        'Theme',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: EuSpace.sm),
                      Row(
                        children: [
                          _ThemeModeButton(
                            title: 'System',
                            isSelected: theme.mode == ThemeMode.system,
                            onTap: () =>
                                themeController.setMode(ThemeMode.system),
                          ),
                          const SizedBox(width: 8),
                          _ThemeModeButton(
                            title: 'Light',
                            isSelected: theme.mode == ThemeMode.light,
                            onTap: () =>
                                themeController.setMode(ThemeMode.light),
                          ),
                          const SizedBox(width: 8),
                          _ThemeModeButton(
                            title: 'Dark',
                            isSelected: theme.mode == ThemeMode.dark,
                            onTap: () =>
                                themeController.setMode(ThemeMode.dark),
                          ),
                        ],
                      ),
                      const SizedBox(height: EuSpace.sm),
                      SwitchListTile(
                        activeThumbColor: EuBrutal.accent,
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'AMOLED black',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        subtitle: const Text(
                          'Pure black background in dark mode',
                        ),
                        value: theme.amoled,
                        onChanged: (value) =>
                            themeController.setAmoled(value: value),
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
                            border: Border.all(
                              color: EuBrutal.onHighlight,
                              width: 1.5,
                            ),
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
                        trailing: Icon(Icons.public, color: context.eu.ink),
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
                            side: BorderSide(color: context.eu.ink, width: 1.5),
                          ),
                          onPressed: () => _clearCache(context),
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
                      const Divider(height: 16),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'Export Error Logs',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        subtitle: const Text(
                          'Download app logs to report issues to developers',
                        ),
                        trailing: const Icon(Icons.bug_report_outlined),
                        onTap: () async {
                          final success = await LogExporter.exportLogs();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  success
                                      ? 'Logs saved successfully! Share with developers.'
                                      : 'Log export failed or cancelled.',
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
                                Text(
                                  'v$appVersion • Neo-Brutalist Edition',
                                  style: const TextStyle(
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
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Container(
          decoration: EuBrutal.boxDecoration(
            color: context.eu.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.eu.ink, width: 2.5),
            shadows: EuBrutal.hardShadow,
          ),
          padding: const EdgeInsets.all(24),
          child: Material(
            color: Colors.transparent,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'SELECT AUDIO QUALITY',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 16),
                ...options.map((opt) {
                  final isSelected = opt.$1 == current;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      opt.$2,
                      style: TextStyle(
                        fontWeight: isSelected
                            ? FontWeight.w900
                            : FontWeight.w700,
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
                }),
              ],
            ),
          ),
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
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Container(
          decoration: EuBrutal.boxDecoration(
            color: context.eu.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.eu.ink, width: 2.5),
            shadows: EuBrutal.hardShadow,
          ),
          padding: const EdgeInsets.all(24),
          child: Material(
            color: Colors.transparent,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'SELECT CONTENT REGION',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: countries.length,
                    itemBuilder: (context, index) {
                      final country = countries[index];
                      final isSelected = country == currentRegion;
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          country,
                          style: TextStyle(
                            fontWeight: isSelected
                                ? FontWeight.w900
                                : FontWeight.w700,
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _clearCache(BuildContext context) async {
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
    try {
      final tempDir = await getTemporaryDirectory();
      if (tempDir.existsSync()) {
        final files = tempDir.listSync(recursive: true);
        for (final file in files) {
          if (file is File) {
            try {
              file.deleteSync();
            } catch (_) {}
          }
        }
      }
    } catch (_) {}
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All cached artwork and temporary disk data cleared!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
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
                        Text(
                          'Current Version: v${info?.currentVersion ?? ref.watch(appVersionProvider).asData?.value ?? '0.2.9'}',
                          style: const TextStyle(fontWeight: FontWeight.w800),
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
                      side: BorderSide(color: context.eu.ink, width: 2),
                    ),
                    onPressed: _checking
                        ? null
                        : () async {
                            if (info != null && info.hasUpdate) {
                              unawaited(showUpdateDialog(context, info));
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

}

class _ThemeModeButton extends StatelessWidget {
  const _ThemeModeButton({
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: EuBrutal.boxDecoration(
            color: isSelected ? EuBrutal.accent : context.eu.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: context.eu.ink,
              width: isSelected ? 2.5 : 1.5,
            ),
            shadows: isSelected ? EuBrutal.smHardShadow : [],
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
              color: isSelected ? EuBrutal.onAccent : context.eu.ink,
            ),
          ),
        ),
      ),
    );
  }
}
