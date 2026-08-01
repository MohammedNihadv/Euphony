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

  // The pairings the dark palette actually renders. A tweak that breaks one
  // fails the build rather than shipping an unreadable surface.
  group('dark palette meets WCAG AA', () {
    test('light ink reads as text on the dark canvas', () {
      expect(
        EuBrutal.contrastRatio(EuBrutal.ink, EuBrutal.canvas),
        greaterThanOrEqualTo(_aaBodyText),
      );
    });

    test('white on accent clears the body floor', () {
      expect(
        EuBrutal.contrastRatio(EuBrutal.onAccent, EuBrutal.accent),
        greaterThanOrEqualTo(_aaBodyText),
      );
    });

    test('white on alert clears the body floor', () {
      expect(
        EuBrutal.contrastRatio(Colors.white, EuBrutal.alert),
        greaterThanOrEqualTo(_aaBodyText),
      );
    });

    test('dark onHighlight reads on the yellow highlight fill', () {
      expect(
        EuBrutal.contrastRatio(EuBrutal.onHighlight, EuBrutal.highlight),
        greaterThanOrEqualTo(_aaBodyText),
      );
    });

    test('the light ink frame stays visible on raised surfaces', () {
      expect(
        EuBrutal.contrastRatio(EuBrutal.ink, EuBrutal.surface),
        greaterThanOrEqualTo(_aaLargeText),
      );
    });

    test('the accent reads as an icon/label on the dark canvas', () {
      expect(
        EuBrutal.contrastRatio(EuBrutal.accent, EuBrutal.canvas),
        greaterThanOrEqualTo(_aaLargeText),
      );
    });
  });
}
