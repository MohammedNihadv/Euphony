// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'theme_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The palette cache. Long-lived — re-deriving a scheme the user already saw
/// would flash the fallback colours on every repeat play.

@ProviderFor(artworkPalette)
final artworkPaletteProvider = ArtworkPaletteProvider._();

/// The palette cache. Long-lived — re-deriving a scheme the user already saw
/// would flash the fallback colours on every repeat play.

final class ArtworkPaletteProvider
    extends $FunctionalProvider<ArtworkPalette, ArtworkPalette, ArtworkPalette>
    with $Provider<ArtworkPalette> {
  /// The palette cache. Long-lived — re-deriving a scheme the user already saw
  /// would flash the fallback colours on every repeat play.
  ArtworkPaletteProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'artworkPaletteProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$artworkPaletteHash();

  @$internal
  @override
  $ProviderElement<ArtworkPalette> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ArtworkPalette create(Ref ref) {
    return artworkPalette(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ArtworkPalette value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ArtworkPalette>(value),
    );
  }
}

String _$artworkPaletteHash() => r'd1ec2b2f8ca1c30f747af437fc67f50b8ac20e23';

@ProviderFor(ThemeController)
final themeControllerProvider = ThemeControllerProvider._();

final class ThemeControllerProvider
    extends $NotifierProvider<ThemeController, ThemeState> {
  ThemeControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'themeControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$themeControllerHash();

  @$internal
  @override
  ThemeController create() => ThemeController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ThemeState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ThemeState>(value),
    );
  }
}

String _$themeControllerHash() => r'a5251ff0fc1f28701eea76d5a8861163ebf12f04';

abstract class _$ThemeController extends $Notifier<ThemeState> {
  ThemeState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ThemeState, ThemeState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ThemeState, ThemeState>,
              ThemeState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
