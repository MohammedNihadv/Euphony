import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/update_prompt.dart';
import '../../data/remote/update_checker.dart';
import '../../design/theme/theme_controller.dart';
import '../../design/tokens/brutal.dart';
import '../../design/tokens/tokens.dart';
import '../../design/widgets/brand_badge.dart';
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
    final appVersion = ref.watch(appVersionProvider).asData?.value ?? '0.3.0';
    final isDark = themeData.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: false,
        backgroundColor: themeData.colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        title: const EuphonyPageCapsule(
          label: 'Settings',
          icon: Icons.tune_rounded,
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, EuSpace.sm, 20, 140),
              children: [
                // ---------------- 1. Hero Banner ----------------
                _SettingsHeroBanner(
                  version: appVersion,
                  audioQuality: settings.audioQuality,
                  region: settings.contentRegion,
                  dynamicIsland: settings.dynamicIsland,
                ),
                const SizedBox(height: EuSpace.lg),

                // ---------------- 2. Appearance & Dynamic Island Card ----------------
                _SettingsSectionCard(
                  icon: Icons.auto_awesome_rounded,
                  iconColor: EuBrutal.accent,
                  title: 'Appearance & Interface',
                  children: [
                    const Text(
                      'THEME MODE',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: EuSpace.sm),
                    Row(
                      children: [
                        _ThemeModeButton(
                          title: 'System',
                          icon: Icons.brightness_auto_rounded,
                          isSelected: theme.mode == ThemeMode.system,
                          onTap: () =>
                              themeController.setMode(ThemeMode.system),
                        ),
                        const SizedBox(width: 8),
                        _ThemeModeButton(
                          title: 'Light',
                          icon: Icons.light_mode_rounded,
                          isSelected: theme.mode == ThemeMode.light,
                          onTap: () =>
                              themeController.setMode(ThemeMode.light),
                        ),
                        const SizedBox(width: 8),
                        _ThemeModeButton(
                          title: 'Dark',
                          icon: Icons.dark_mode_rounded,
                          isSelected: theme.mode == ThemeMode.dark,
                          onTap: () =>
                              themeController.setMode(ThemeMode.dark),
                        ),
                      ],
                    ),
                    const SizedBox(height: EuSpace.md),
                    const Divider(height: 1),
                    const SizedBox(height: EuSpace.sm),

                    // Dynamic Island Toggle
                    _SettingsSwitchRow(
                      icon: Icons.motion_photos_on_rounded,
                      iconColor: EuBrutal.accent,
                      title: 'Dynamic Island',
                      subtitle: 'In-app capsule replaces mini-player',
                      value: settings.dynamicIsland,
                      onChanged: (value) =>
                          settingsController.setDynamicIsland(value),
                    ),
                    const Divider(height: 1),
                    const SizedBox(height: EuSpace.xs),

                    // AMOLED Black Toggle
                    _SettingsSwitchRow(
                      icon: Icons.dark_mode_rounded,
                      iconColor: Colors.amber,
                      title: 'AMOLED Pure Black',
                      subtitle: 'True pitch-black theme for OLED screens',
                      value: theme.amoled,
                      onChanged: (value) =>
                          themeController.setAmoled(value: value),
                    ),
                  ],
                ),
                const SizedBox(height: EuSpace.lg),

                // ---------------- 3. Playback & Streaming Engine Card ----------------
                _SettingsSectionCard(
                  icon: Icons.headphones_rounded,
                  iconColor: const Color(0xFF3B82F6),
                  title: 'Playback & Audio Engine',
                  children: [
                    _SettingsSwitchRow(
                      icon: Icons.data_saver_on_rounded,
                      iconColor: const Color(0xFF10B981),
                      title: 'Data Saver Mode',
                      subtitle: 'Optimizes audio for 2G/3G mobile networks',
                      value: settings.audioQuality == 'LOW',
                      onChanged: (value) =>
                          settingsController.setAudioQuality(value ? 'LOW' : 'HIGH'),
                    ),
                    const Divider(height: 1),
                    const SizedBox(height: EuSpace.sm),

                    const Text(
                      'AUDIO STREAM QUALITY',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: EuSpace.sm),
                    Row(
                      children: [
                        _QualityChipButton(
                          title: 'High',
                          sub: '256k AAC',
                          qualityKey: 'HIGH',
                          currentKey: settings.audioQuality,
                          onTap: () =>
                              settingsController.setAudioQuality('HIGH'),
                        ),
                        const SizedBox(width: 8),
                        _QualityChipButton(
                          title: 'Standard',
                          sub: '128k AAC',
                          qualityKey: 'STANDARD',
                          currentKey: settings.audioQuality,
                          onTap: () =>
                              settingsController.setAudioQuality('STANDARD'),
                        ),
                        const SizedBox(width: 8),
                        _QualityChipButton(
                          title: 'Data Saver',
                          sub: '64k Opus',
                          qualityKey: 'LOW',
                          currentKey: settings.audioQuality,
                          onTap: () =>
                              settingsController.setAudioQuality('LOW'),
                        ),
                      ],
                    ),
                    const SizedBox(height: EuSpace.md),
                    const Divider(height: 1),
                    const SizedBox(height: EuSpace.sm),

                    // Content Region
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6).withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.language_rounded,
                          color: Color(0xFF3B82F6),
                          size: 20,
                        ),
                      ),
                      title: const Text(
                        'Content Region',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                      subtitle: Text(
                        'Feed curated for ${settings.contentRegion}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0x1F252538)
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.14)
                                : Colors.black.withValues(alpha: 0.1),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black
                                  .withValues(alpha: isDark ? 0.2 : 0.04),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              settings.contentRegion.split(' - ').first,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.arrow_drop_down_rounded,
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                      onTap: () => _showCountryDialog(
                        context,
                        settings.contentRegion,
                        settingsController,
                      ),
                    ),
                    const Divider(height: 1),
                    const SizedBox(height: EuSpace.xs),

                    // Auto-Play Similar Songs
                    _SettingsSwitchRow(
                      icon: Icons.all_inclusive_rounded,
                      iconColor: Colors.purple,
                      title: 'Autoplay',
                      subtitle:
                          'Keep playing similar tracks when queue finishes',
                      value: settings.autoPlaySimilar,
                      onChanged: (value) =>
                          settingsController.setAutoPlaySimilar(value),
                    ),
                    const Divider(height: 1),
                    const SizedBox(height: EuSpace.xs),

                    // Skip Silence
                    _SettingsSwitchRow(
                      icon: Icons.graphic_eq_rounded,
                      iconColor: Colors.teal,
                      title: 'Skip Silence',
                      subtitle:
                          'Automatically trim silent gaps at track start and end',
                      value: settings.skipSilence,
                      onChanged: (value) =>
                          settingsController.setSkipSilence(value),
                    ),
                  ],
                ),
                const SizedBox(height: EuSpace.lg),

                
                // ---------------- 4. Storage, Cache & Data Card ----------------
                _SettingsSectionCard(
                  icon: Icons.folder_special_rounded,
                  iconColor: const Color(0xFFF59E0B),
                  title: 'Storage & Diagnostics',
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.14),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.auto_delete_rounded,
                          color: Color(0xFFF59E0B),
                          size: 20,
                        ),
                      ),
                      title: const Text(
                        'Clear Cache',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                      subtitle: const Text(
                        'Frees temporary memory & media cache without losing library',
                        style: TextStyle(fontSize: 12),
                      ),
                      trailing: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark
                              ? const Color(0x1F252538)
                              : const Color(0xFFF1F5F9),
                          foregroundColor: context.eu.ink,
                          side: BorderSide(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.14)
                                : Colors.black.withValues(alpha: 0.1),
                            width: 1.2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                        ),
                        onPressed: () => _clearCache(context),
                        child: const Text(
                          'CLEAR',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                    const Divider(height: 1),
                    const SizedBox(height: EuSpace.xs),

                    // Backup & Restore Row
                    Row(
                      children: [
                        Expanded(
                          child: _ActionPillButton(
                            icon: Icons.upload_file_rounded,
                            label: 'Export Backup',
                            onTap: () async {
                              final success =
                                  await BackupService.exportBackup();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      success
                                          ? 'Backup saved successfully!'
                                          : 'Backup cancelled.',
                                    ),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _ActionPillButton(
                            icon: Icons.file_download_outlined,
                            label: 'Import Backup',
                            onTap: () async {
                              final success =
                                  await BackupService.importBackup();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      success
                                          ? 'Backup restored! Please restart Euphony.'
                                          : 'Import cancelled.',
                                    ),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Diagnostic Logs
                    _ActionPillButton(
                      icon: Icons.bug_report_rounded,
                      label: 'Export Diagnostic Logs',
                      isFullWidth: true,
                      onTap: () async {
                        final success = await LogExporter.exportLogs();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                success
                                    ? 'Logs exported! Ready to share.'
                                    : 'Log export cancelled.',
                              ),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: EuSpace.lg),

                // ---------------- 5. App Updates Card ----------------
                const _AppUpdateCard(),
                const SizedBox(height: EuSpace.lg),

                // ---------------- 6. About Euphony (Brutalist Signature Card) ----------------
                _AboutEuphonyCard(appVersion: appVersion),
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
      'IN - India',
      'US - United States',
      'PK - Pakistan',
      'UK - United Kingdom',
      'CA - Canada',
      'AU - Australia',
      'JP - Japan',
      'KR - South Korea',
      'DE - Germany',
      'FR - France',
      'BR - Brazil',
      'NG - Nigeria',
      'AE - United Arab Emirates',
      'SA - Saudi Arabia',
      'ID - Indonesia',
    ];

    showDialog<void>(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF161626) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.15)
                    : Colors.black.withValues(alpha: 0.08),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.55 : 0.15),
                  blurRadius: 32,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            padding: const EdgeInsets.all(22),
            child: Material(
              color: Colors.transparent,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: EuBrutal.accent,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: EuBrutal.accent.withValues(alpha: 0.35),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      child: const Icon(
                        Icons.public_rounded,
                        color: EuBrutal.onAccent,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'SELECT CONTENT REGION',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 380),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: countries.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final country = countries[index];
                      final isSelected = country == currentRegion;
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        title: Text(
                          country,
                          style: TextStyle(
                            fontWeight: isSelected
                                ? FontWeight.w900
                                : FontWeight.w700,
                            color: isSelected ? EuBrutal.accent : null,
                          ),
                        ),
                        trailing: isSelected
                            ? Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: EuBrutal.accent,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check_rounded,
                                  size: 14,
                                  color: EuBrutal.onAccent,
                                ),
                              )
                            : null,
                        onTap: () {
                          controller.setContentRegion(country);
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Content region updated to $country'),
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
      );
    },
  );
}

  Future<void> _clearCache(BuildContext context) async {
    await HapticFeedback.mediumImpact();
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
          content: Text('Temporary memory and media cache cleared.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

// ---------------------------------------------------------------------------
// Premium Components & Bento Cards
// ---------------------------------------------------------------------------

class _SettingsHeroBanner extends StatelessWidget {
  const _SettingsHeroBanner({
    required this.version,
    required this.audioQuality,
    required this.region,
    required this.dynamicIsland,
  });

  final String version;
  final String audioQuality;
  final String region;
  final bool dynamicIsland;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.22),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4F46E5)
                .withValues(alpha: isDark ? 0.35 : 0.25),
            blurRadius: 20,
            spreadRadius: -2,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF22C55E),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'EUPHONY SYSTEM - v$version',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                  color: EuBrutal.onAccent.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Settings & Engine',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: EuBrutal.onAccent,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Hardware-accelerated playback with Dynamic Island & custom audio pipe',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: EuBrutal.onAccent.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 14),

          // Quick Bento Status Chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildMiniStatusChip(
                icon: Icons.graphic_eq_rounded,
                label: 'Audio $audioQuality',
              ),
              _buildMiniStatusChip(
                icon: Icons.smart_screen_rounded,
                label: 'Island: ${dynamicIsland ? 'AUTO' : 'OFF'}',
              ),
              _buildMiniStatusChip(
                icon: Icons.public_rounded,
                label: region.split(' - ').first,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStatusChip({
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.white),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsSectionCard extends StatelessWidget {
  const _SettingsSectionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.children,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.12)
              : Colors.black.withValues(alpha: 0.08),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.45)
                : const Color(0xFF64748B).withValues(alpha: 0.12),
            blurRadius: 24,
            spreadRadius: -2,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: isDark
                ? Colors.white.withValues(alpha: 0.03)
                : Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(21),
        child: Container(
          color: isDark
              ? const Color(0xFF1B1B29)
              : Colors.white,
          padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Fresh circular icon avatar + bold title
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: iconColor.withValues(alpha: 0.14),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: iconColor, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                ...children,
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
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? EuBrutal.accent
                : (isDark ? const Color(0x1F252538) : const Color(0xFFF1F5F9)),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? EuBrutal.accent
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.12)
                      : Colors.black.withValues(alpha: 0.08)),
              width: 1.2,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: EuBrutal.accent.withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? EuBrutal.onAccent : context.eu.ink,
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                  fontSize: 12,
                  color: isSelected ? EuBrutal.onAccent : context.eu.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QualityChipButton extends StatelessWidget {
  const _QualityChipButton({
    required this.title,
    required this.sub,
    required this.qualityKey,
    required this.currentKey,
    required this.onTap,
  });

  final String title;
  final String sub;
  final String qualityKey;
  final String currentKey;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isSelected = qualityKey == currentKey;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected
                ? EuBrutal.accent
                : (isDark ? const Color(0x1F252538) : const Color(0xFFF1F5F9)),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? EuBrutal.accent
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.12)
                      : Colors.black.withValues(alpha: 0.08)),
              width: 1.2,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: EuBrutal.accent.withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
          ),
          child: Column(
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.w800,
                  fontSize: 12.5,
                  color: isSelected ? EuBrutal.onAccent : context.eu.ink,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                sub,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 10,
                  color: isSelected
                      ? EuBrutal.onAccent.withValues(alpha: 0.8)
                      : context.eu.ink.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsSwitchRow extends StatelessWidget {
  const _SettingsSwitchRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    height: 1.25,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch(
            value: value,
            activeTrackColor: EuBrutal.accent,
            activeThumbColor: Colors.white,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _ActionPillButton extends StatelessWidget {
  const _ActionPillButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isFullWidth = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isFullWidth;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0x1F252538) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.12)
                : Colors.black.withValues(alpha: 0.08),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: context.eu.ink),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
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
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    final updateAsync = ref.watch(updateCheckFutureProvider);
    final info = _info ?? updateAsync.asData?.value;
    final isDark = themeData.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.12)
              : Colors.black.withValues(alpha: 0.08),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.45)
                : const Color(0xFF64748B).withValues(alpha: 0.12),
            blurRadius: 24,
            spreadRadius: -2,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: isDark
                ? Colors.white.withValues(alpha: 0.03)
                : Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(21),
        child: Container(
          color: isDark
              ? const Color(0xFF1B1B29)
              : Colors.white,
          padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.14),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.system_update_rounded,
                        color: Color(0xFF10B981),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Software Updates',
                        style: themeData.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Current Build: v${info?.currentVersion ?? ref.watch(appVersionProvider).asData?.value ?? '0.3.0'}',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 2),
                          if (info != null && info.hasUpdate)
                            Text(
                              'Update Available: v${info.latestVersion}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                color: EuBrutal.accent,
                              ),
                            )
                          else
                            const Text(
                              'All system patches & components are up to date',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: (info != null && info.hasUpdate)
                            ? EuBrutal.accent
                            : (isDark ? const Color(0x1F252538) : const Color(0xFFF1F5F9)),
                        foregroundColor: (info != null && info.hasUpdate)
                            ? EuBrutal.onAccent
                            : context.eu.ink,
                        side: BorderSide(
                          color: (info != null && info.hasUpdate)
                              ? EuBrutal.accent
                              : (isDark
                                  ? Colors.white.withValues(alpha: 0.14)
                                  : Colors.black.withValues(alpha: 0.1)),
                          width: 1.2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                        shadowColor: Colors.transparent,
                      ),
                      onPressed: _checking
                          ? null
                          : () async {
                              await HapticFeedback.lightImpact();
                              if (!context.mounted) return;
                              if (info != null && info.hasUpdate) {
                                unawaited(showUpdateDialog(context, info));
                              } else {
                                await _checkUpdate();
                              }
                            },
                      icon: _checking
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(
                              (info != null && info.hasUpdate)
                                  ? Icons.file_download
                                  : Icons.refresh_rounded,
                              size: 18,
                            ),
                      label: Text(
                        _checking
                            ? 'Checking...'
                            : (info != null && info.hasUpdate)
                            ? 'UPDATE'
                            : 'CHECK',
                        style: const TextStyle(fontWeight: FontWeight.w900),
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

class _AboutEuphonyCard extends StatelessWidget {
  const _AboutEuphonyCard({required this.appVersion});

  final String appVersion;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.12)
              : Colors.black.withValues(alpha: 0.08),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.45)
                : const Color(0xFF64748B).withValues(alpha: 0.12),
            blurRadius: 24,
            spreadRadius: -2,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: isDark
                ? Colors.white.withValues(alpha: 0.03)
                : Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(21),
        child: Container(
          color: isDark
              ? const Color(0xFF1B1B29)
              : Colors.white,
          padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: EuBrutal.highlight,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: EuBrutal.highlight.withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.graphic_eq_rounded,
                        color: EuBrutal.onHighlight,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'EUPHONY MUSIC',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                            ),
                          ),
                          Text(
                            'v$appVersion \u2022 Neo-Brutalist Glass Edition',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
                const SizedBox(height: 14),
                Text(
                  'Music deserves better than interruptions.\n\n'
                  'Euphony is an open-source, ad-free music streaming client built with Flutter.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
                    fontWeight: FontWeight.w500,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 18),
                const Divider(height: 1),
                const SizedBox(height: 16),
                // 2x2 Bento Tiles for By Fedaration & Ecosystem
                // Row 1: Euphony Web, GitHub Core
                // Row 2: Fedaration (3rd box as requested), Play Protect (4th box)
                Row(
                  children: [
                    Expanded(
                      child: _FedarationBentoTile(
                        icon: Icons.web_rounded,
                        title: 'Euphony Web',
                        badge: 'WEB APP',
                        badgeColor: const Color(0xFF3B82F6),
                        subtitle: 'euphony.fedaration.in',
                        onTap: () async {
                          final uri = Uri.parse('https://euphony.fedaration.in/');
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri, mode: LaunchMode.externalApplication);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _FedarationBentoTile(
                        icon: Icons.code_rounded,
                        title: 'GitHub Core',
                        badge: 'SOURCE',
                        badgeColor: const Color(0xFF10B981),
                        subtitle: 'Open-source',
                        onTap: () async {
                          final uri = Uri.parse('https://github.com/MohammedNihadv/Euphony');
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri, mode: LaunchMode.externalApplication);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _FedarationBentoTile(
                        icon: Icons.language_rounded,
                        title: 'Fedaration',
                        badge: 'OFFICIAL',
                        badgeColor: EuBrutal.accent,
                        subtitle: 'fedaration.in',
                        onTap: () async {
                          final uri = Uri.parse('https://fedaration.in/');
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri, mode: LaunchMode.externalApplication);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _FedarationBentoTile(
                        icon: Icons.shield_rounded,
                        title: 'Play Protect',
                        badge: '100% SAFE',
                        badgeColor: const Color(0xFF10B981),
                        subtitle: 'Tap to learn more',
                        onTap: () => _showPlayProtectSheet(context),
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

  void _showPlayProtectSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      showDragHandle: false,
      barrierColor: Colors.black.withValues(alpha: isDark ? 0.65 : 0.40),
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF141424)
              : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.12)
                : Colors.black.withValues(alpha: 0.08),
            width: 1.2,
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              24,
              16,
              24,
              MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : Colors.black26,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.shield_rounded,
                          color: Color(0xFF10B981),
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Play Protect & Security',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Open-Source Integrity Verification',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF10B981),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Why does Android show a Play Protect prompt?\n\n'
                    '\u2022 Euphony is distributed freely without third-party app store fees. '
                    'Android\'s Play Protect flags it as "unrecognized" until developer '
                    'whitelisting propagates.\n\n'
                    '\u2022 100% Privacy: Zero analytics SDKs, zero ads, no personal data collected.\n\n'
                    '\u2022 Open-source APK signatures are submitted to Google Play Protect Appeals for certificate whitelisting.',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      height: 1.5,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final uri = Uri.parse('https://fedaration.in/');
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri, mode: LaunchMode.externalApplication);
                            }
                          },
                          icon: const Icon(Icons.language_rounded, size: 18),
                          label: const Text(
                            'Fedaration.in',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: EuBrutal.accent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            side: BorderSide(
                              color: isDark ? Colors.white24 : Colors.black26,
                            ),
                          ),
                          child: Text(
                            'Got It',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FedarationBentoTile extends StatelessWidget {
  const _FedarationBentoTile({
    required this.icon,
    required this.title,
    required this.badge,
    required this.badgeColor,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String badge;
  final Color badgeColor;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          height: 100,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.07)
                : Colors.white.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.10)
                  : Colors.black.withValues(alpha: 0.06),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, size: 16, color: badgeColor),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      badge,
                      style: TextStyle(
                        color: badgeColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 8,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 10,
                  color: isDark ? Colors.white54 : Colors.black45,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

