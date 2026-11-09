import 'package:flutter/foundation.dart';

/// Categories of errors within Euphony.
enum EuErrorCategory {
  ui('UI', 'Interface & Layout'),
  navigation('NAV', 'Navigation & Routing'),
  network('NET', 'Network & Connectivity'),
  media('MEDIA', 'Media & Stream Pipeline'),
  storage('STORAGE', 'Local Storage & Database'),
  system('SYS', 'System & Runtime');

  const EuErrorCategory(this.prefix, this.label);
  final String prefix;
  final String label;
}

/// A structured error representation with unique error codes, human titles,
/// and actionable diagnostics.
class EuErrorInfo {
  const EuErrorInfo({
    required this.code,
    required this.name,
    required this.category,
    required this.title,
    required this.description,
    required this.suggestedAction,
    this.technicalDetails,
    this.originalError,
    this.stackTrace,
  });

  /// The unique alphanumeric error code (e.g. `EUPHONY-UI-001`).
  final String code;

  /// The machine-readable error token (e.g. `ERR_MATERIAL_LAYOUT_CONFLICT`).
  final String name;

  /// The broad classification of the issue.
  final EuErrorCategory category;

  /// High-level human-friendly title.
  final String title;

  /// Plain language description of what happened.
  final String description;

  /// Direct recommendation for the user.
  final String suggestedAction;

  /// Raw exception or assertion message.
  final String? technicalDetails;

  /// Original error object.
  final Object? originalError;

  /// Stack trace if captured.
  final StackTrace? stackTrace;

  /// Formats a complete markdown bug report suitable for clipboard copying.
  String toMarkdownReport() {
    final buffer = StringBuffer();
    buffer.writeln('# Euphony Diagnostic Report');
    buffer.writeln('**Error Code:** `$code` ($name)');
    buffer.writeln('**Category:** ${category.label}');
    buffer.writeln('**Title:** $title');
    buffer.writeln('**Timestamp:** ${DateTime.now().toUtc().toIso8601String()}');
    buffer.writeln('**Platform:** ${defaultTargetPlatform.name}');
    buffer.writeln();
    buffer.writeln('### Description');
    buffer.writeln(description);
    buffer.writeln();
    if (technicalDetails != null && technicalDetails!.isNotEmpty) {
      buffer.writeln('### Technical Details');
      buffer.writeln('```');
      buffer.writeln(technicalDetails);
      buffer.writeln('```');
      buffer.writeln();
    }
    if (stackTrace != null) {
      buffer.writeln('### Stack Trace');
      buffer.writeln('```');
      buffer.writeln(stackTrace.toString().trim());
      buffer.writeln('```');
    }
    return buffer.toString();
  }

  /// Classifies any error, exception, assertion, or [FlutterErrorDetails] into
  /// a structured [EuErrorInfo] with the appropriate error code.
  factory EuErrorInfo.classify(Object? error, [StackTrace? stackTrace]) {
    final rawMessage = error is FlutterErrorDetails
        ? error.exceptionAsString()
        : (error?.toString() ?? 'Unknown error');

    final effectiveStack = stackTrace ??
        (error is FlutterErrorDetails ? error.stack : null);

    final lower = rawMessage.toLowerCase();

    // 1. UI: Shape and borderRadius conflict
    if (lower.contains('shape != null && borderradius != null') ||
        (lower.contains('material.dart') && lower.contains('assertion'))) {
      return EuErrorInfo(
        code: 'EUPHONY-UI-001',
        name: 'ERR_MATERIAL_SHAPE_RADIUS',
        category: EuErrorCategory.ui,
        title: 'Interface Layout Conflict',
        description:
            'A widget attempted to apply both custom shape borders and direct border radius at the same time.',
        suggestedAction:
            'Tap Reload below or navigate back to refresh the component view.',
        technicalDetails: rawMessage,
        originalError: error,
        stackTrace: effectiveStack,
      );
    }

    // 2. UI: Layout overflow
    if (lower.contains('overflowed by') || lower.contains('renderflex')) {
      return EuErrorInfo(
        code: 'EUPHONY-UI-002',
        name: 'ERR_LAYOUT_OVERFLOW',
        category: EuErrorCategory.ui,
        title: 'Display Boundary Exceeded',
        description:
            'Some interface elements exceeded their available space by a few pixels on this window size.',
        suggestedAction:
            'Resize your window slightly or tap Reload to recompute sizing.',
        technicalDetails: rawMessage,
        originalError: error,
        stackTrace: effectiveStack,
      );
    }

    // 3. UI: ListTile background / DecoratedBox clipping assertion
    if (lower.contains('listtile background color or ink splashes may be invisible') ||
        lower.contains('decoratedbox')) {
      return EuErrorInfo(
        code: 'EUPHONY-UI-003',
        name: 'ERR_TILE_DECORATION_CLIPPING',
        category: EuErrorCategory.ui,
        title: 'Tile Composing Warning',
        description:
            'An interactive list tile was wrapped in an intermediate decoration that obscured ink effects.',
        suggestedAction:
            'Tap Reload or return to the previous screen.',
        technicalDetails: rawMessage,
        originalError: error,
        stackTrace: effectiveStack,
      );
    }

    // 4. Navigation: Missing route / GoException / 404
    if (lower.contains('goexception') ||
        lower.contains('no routes') ||
        lower.contains('not found') ||
        lower.contains('path not registered')) {
      return EuErrorInfo(
        code: 'EUPHONY-NAV-004',
        name: 'ERR_ROUTE_NOT_FOUND',
        category: EuErrorCategory.navigation,
        title: 'Destination Not Found',
        description:
            'The requested screen or link could not be located in Euphony.',
        suggestedAction:
            'Head back to your Library or Home screen to continue playing.',
        technicalDetails: rawMessage,
        originalError: error,
        stackTrace: effectiveStack,
      );
    }

    // 5. Network / Socket / HTTP
    if (lower.contains('socketexception') ||
        lower.contains('httpexception') ||
        lower.contains('connection refused') ||
        lower.contains('handshakeexception') ||
        lower.contains('clientexception') ||
        lower.contains('failed host lookup')) {
      return EuErrorInfo(
        code: 'EUPHONY-NET-005',
        name: 'ERR_NETWORK_DISCONNECTED',
        category: EuErrorCategory.network,
        title: 'Network Connection Interrupted',
        description:
            'Euphony could not establish a connection to metadata or streaming servers.',
        suggestedAction:
            'Check your internet or Wi-Fi connection and tap Retry.',
        technicalDetails: rawMessage,
        originalError: error,
        stackTrace: effectiveStack,
      );
    }

    // 6. Audio Decoder / Media Stream
    if (lower.contains('audioplayer') ||
        lower.contains('mediakit') ||
        lower.contains('extractor') ||
        lower.contains('streamproxy') ||
        lower.contains('innertube')) {
      return EuErrorInfo(
        code: 'EUPHONY-MEDIA-006',
        name: 'ERR_STREAM_DECODE_FAULT',
        category: EuErrorCategory.media,
        title: 'Audio Pipeline Fault',
        description:
            'The media pipeline or audio decoder encountered an unexpected stream structure.',
        suggestedAction:
            'Try playing another track or selecting a cached offline song.',
        technicalDetails: rawMessage,
        originalError: error,
        stackTrace: effectiveStack,
      );
    }

    // 7. Storage / Database
    if (lower.contains('sqlite') ||
        lower.contains('drift') ||
        lower.contains('sharedpreferences') ||
        lower.contains('database') ||
        lower.contains('disk full')) {
      return EuErrorInfo(
        code: 'EUPHONY-STORAGE-007',
        name: 'ERR_STORAGE_FAULT',
        category: EuErrorCategory.storage,
        title: 'Local Storage Error',
        description:
            'Euphony was unable to read or write local playback database files.',
        suggestedAction:
            'Ensure your device storage is not completely full and tap Retry.',
        technicalDetails: rawMessage,
        originalError: error,
        stackTrace: effectiveStack,
      );
    }

    // 8. General / Fallback
    return EuErrorInfo(
      code: 'EUPHONY-SYS-999',
      name: 'ERR_UNEXPECTED_EXCEPTION',
      category: EuErrorCategory.system,
      title: 'Unexpected Hiccup',
      description:
          'Euphony encountered an unhandled exception during execution. Your playback session remains protected.',
      suggestedAction:
          'Tap Reload to refresh this view or return to Home.',
      technicalDetails: rawMessage,
      originalError: error,
      stackTrace: effectiveStack,
    );
  }
}

