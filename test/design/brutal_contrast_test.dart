import 'package:euphony/design/tokens/brutal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// WCAG 2.1 AA floors.
const double _aaBodyText = 4.5;
const double _aaLargeText = 3.0;

void main() {
  group('contrastRatio', () {
    test('is 21:1 for black on white', () {
      expect(
        EuBrutal.contrastRatio(Colors.black, Colors.white),
        closeTo(21, 0.01),
      );
    });

    test('is 1:1 for a colour against itself', () {
      expect(
        EuBrutal.contrastRatio(EuBrutal.accent, EuBrutal.accent),
        closeTo(1, 0.001),
      );
    });

    test('is symmetric', () {
      expect(
        EuBrutal.contrastRatio(EuBrutal.accent, Colors.white),
        closeTo(EuBrutal.contrastRatio(Colors.white, EuBrutal.accent), 0.001),
      );
    });
  });

  // PRODUCT.md commits to WCAG AA. These are the pairings the app actually
  // renders — filled buttons, the nav indicator, chips, artwork placeholders.
  // The palette previously failed two of them, so this is a regression guard,
  // not a formality.
  group('palette meets WCAG AA', () {
    test('white on accent clears the body-text floor', () {
      expect(
        EuBrutal.contrastRatio(EuBrutal.onAccent, EuBrutal.accent),
        greaterThanOrEqualTo(_aaBodyText),
      );
    });

    test('white on alert clears the body-text floor', () {
      expect(
        EuBrutal.contrastRatio(Colors.white, EuBrutal.alert),
        greaterThanOrEqualTo(_aaBodyText),
      );
    });

    test('ink on highlight clears the body-text floor', () {
      expect(
        EuBrutal.contrastRatio(EuBrutal.onHighlight, EuBrutal.highlight),
        greaterThanOrEqualTo(_aaBodyText),
      );
    });

    test('ink on a light surface clears the body-text floor', () {
      expect(
        EuBrutal.contrastRatio(EuBrutal.ink, const Color(0xFFFAF7F2)),
        greaterThanOrEqualTo(_aaBodyText),
      );
    });

    test('ink borders stay visible against every accent', () {
      for (final (name, color) in <(String, Color)>[
        ('accent', EuBrutal.accent),
        ('highlight', EuBrutal.highlight),
        ('alert', EuBrutal.alert),
      ]) {
        expect(
          EuBrutal.contrastRatio(EuBrutal.ink, color),
          greaterThanOrEqualTo(_aaLargeText),
          reason: 'the hard border must read against $name',
        );
      }
    });
  });

  group('palette regressions that shipped before', () {
    test('the old accent would fail the floor it is now held to', () {
      // #7C5CFF with white label text measured 4.35:1 on filled buttons.
      expect(
        EuBrutal.contrastRatio(Colors.white, const Color(0xFF7C5CFF)),
        lessThan(_aaBodyText),
      );
    });

    test('the old alert would fail too', () {
      // #FF4081 with white measured 3.33:1.
      expect(
        EuBrutal.contrastRatio(Colors.white, const Color(0xFFFF4081)),
        lessThan(_aaBodyText),
      );
    });

    test('highlight is unusable as a text colour on white, as documented', () {
      expect(
        EuBrutal.contrastRatio(EuBrutal.highlight, Colors.white),
        lessThan(_aaLargeText),
      );
    });
  });
}
