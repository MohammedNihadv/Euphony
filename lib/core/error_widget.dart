import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/router.dart';
import '../design/tokens/brutal.dart';
import '../design/tokens/spacing.dart';
import 'error_codes.dart';

/// A premium, Neo-Brutalist error view that replaces Flutter's default red screen
/// and provides structured error codes, human explanations, and safe recovery actions.
class EuphonyErrorWidget extends StatefulWidget {
  const EuphonyErrorWidget({
    super.key,
    this.error,
    this.stackTrace,
    this.details,
    this.onRetry,
    this.isFullScreen = false,
  });

  /// An optional exception or error object.
  final Object? error;

  /// An optional stack trace.
  final StackTrace? stackTrace;

  /// Flutter's build-time error details if caught by [ErrorWidget.builder].
  final FlutterErrorDetails? details;

  /// Callback when the user taps 'Reload / Try Again'.
  final VoidCallback? onRetry;

  /// Whether this view is displayed as a standalone full screen or inline.
  final bool isFullScreen;

  @override
  State<EuphonyErrorWidget> createState() => _EuphonyErrorWidgetState();
}

class _EuphonyErrorWidgetState extends State<EuphonyErrorWidget> {
  bool _showDetails = false;
  bool _copied = false;

  late final EuErrorInfo _errorInfo;

  @override
  void initState() {
    super.initState();
    _errorInfo = EuErrorInfo.classify(
      widget.details ?? widget.error,
      widget.stackTrace,
    );
  }

  void _copyErrorReport() {
    HapticFeedback.lightImpact();
    Clipboard.setData(ClipboardData(text: _errorInfo.toMarkdownReport()));
    setState(() => _copied = true);

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _copied = false);
    });

    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(
        content: Text('Copied error report (${_errorInfo.code}) to clipboard!'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _handleRetry() {
    HapticFeedback.mediumImpact();
    if (widget.onRetry != null) {
      widget.onRetry!();
    } else {
      // Re-navigate to current route or fallback to home
      try {
        final currentLoc = routerProvider.state.uri.toString();
        routerProvider.go(currentLoc.isEmpty ? '/' : currentLoc);
      } catch (_) {
        routerProvider.go('/');
      }
    }
  }

  void _handleGoHome() {
    HapticFeedback.lightImpact();
    try {
      routerProvider.go('/');
    } catch (_) {
      Navigator.of(context).maybePop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isDark ? const Color(0xFF13131F) : const Color(0xFFFBFBFE);
    final cardBorderColor = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.black.withValues(alpha: 0.08);

    final errorContent = Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(EuSpace.screenGutter),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Container(
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: cardBorderColor, width: 1.4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.06),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header: Error Code Badge & Category Tag
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: EuBrutal.accent.withValues(alpha: isDark ? 0.22 : 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: EuBrutal.accent.withValues(alpha: 0.4),
                          width: 1.0,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            size: 16,
                            color: EuBrutal.accent,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _errorInfo.code,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'monospace',
                              letterSpacing: 0.6,
                              color: EuBrutal.accent,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(
                        color: (isDark ? Colors.white : Colors.black)
                            .withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _errorInfo.category.label.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Error Title
                Text(
                  _errorInfo.title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                    color: isDark ? Colors.white : const Color(0xFF13131F),
                  ),
                ),
                const SizedBox(height: 8),

                // Friendly Description
                Text(
                  _errorInfo.description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isDark ? Colors.white70 : Colors.black87,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 12),

                // Suggested Action Box
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (isDark ? Colors.white : Colors.black)
                        .withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: (isDark ? Colors.white : Colors.black)
                          .withValues(alpha: 0.06),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline_rounded,
                        size: 18,
                        color: isDark ? Colors.amberAccent : Colors.orange,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _errorInfo.suggestedAction,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.87)
                                : Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Collapsible Technical Diagnostics Toggle
                InkWell(
                  onTap: () => setState(() => _showDetails = !_showDetails),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _showDetails
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          size: 18,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _showDetails
                              ? 'Hide Technical Diagnostics'
                              : 'View Technical Diagnostics (${_errorInfo.name})',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Expanded Technical Box
                if (_showDetails) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    constraints: const BoxConstraints(maxHeight: 200),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0B0B12) : const Color(0xFFF1F3F6),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: (isDark ? Colors.white : Colors.black)
                            .withValues(alpha: 0.08),
                      ),
                    ),
                    child: SingleChildScrollView(
                      child: SelectableText(
                        '${_errorInfo.technicalDetails ?? ''}\n\n${_errorInfo.stackTrace ?? ''}',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                          height: 1.4,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 20),

                // Action Buttons Row
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    // Primary Action: Retry / Reload
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: EuBrutal.accent,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _handleRetry,
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text(
                        'Reload Screen',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),

                    // Copy Diagnostics Report
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isDark ? Colors.white : Colors.black87,
                        side: BorderSide(color: cardBorderColor, width: 1.2),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _copyErrorReport,
                      icon: Icon(
                        _copied ? Icons.check_rounded : Icons.copy_rounded,
                        size: 16,
                        color: _copied ? Colors.green : null,
                      ),
                      label: Text(
                        _copied ? 'Report Copied' : 'Copy Error Code',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),

                    // Go Home Action
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: isDark ? Colors.white60 : Colors.black54,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                      onPressed: _handleGoHome,
                      icon: const Icon(Icons.home_outlined, size: 18),
                      label: const Text('Go Home'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (widget.isFullScreen) {
      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF0C0C14) : const Color(0xFFF3F4F8),
        body: SafeArea(child: errorContent),
      );
    }

    return errorContent;
  }
}

/// Standalone Full-Page Error Screen suitable for GoRouter [errorBuilder].
class EuphonyErrorScreen extends StatelessWidget {
  const EuphonyErrorScreen({
    super.key,
    this.error,
    this.uri,
  });

  final Object? error;
  final Uri? uri;

  @override
  Widget build(BuildContext context) {
    return EuphonyErrorWidget(
      error: error ?? 'Page not found: ${uri?.path ?? ''}',
      isFullScreen: true,
    );
  }
}

