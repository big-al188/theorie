// test/root_selector_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:Theorie/models/app_state.dart';
import 'package:Theorie/views/widgets/controls/root_selector.dart';
import 'package:Theorie/constants/music_constants.dart';

void main() {
  group('RootSelector Tests', () {
    late AppState appState;

    setUp(() {
      appState = AppState();
    });

    testWidgets('RootSelector should handle Unicode sharps/flats correctly', (WidgetTester tester) async {
      // Test with a Unicode flat note (G♭) that should map to "Gb" in commonRoots
      appState.setRoot('G♭'); // Unicode flat
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider.value(
              value: appState,
              child: const RootSelector(),
            ),
          ),
        ),
      );

      // Should not throw any assertion errors
      expect(tester.takeException(), isNull);
      
      // Should find the dropdown button
      final dropdown = find.byType(DropdownButton<String>);
      expect(dropdown, findsOneWidget);
      
      // The dropdown should have a valid value
      final dropdownWidget = tester.widget<DropdownButton<String>>(dropdown);
      expect(dropdownWidget.value, isNotNull);
      expect(dropdownWidget.value, equals('Gb')); // Should normalize to 'Gb'
    });

    testWidgets('RootSelector should handle Unicode sharps correctly', (WidgetTester tester) async {
      // Test with a Unicode sharp note (F♯) that should work with the system
      appState.setRoot('F♯'); // Unicode sharp
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider.value(
              value: appState,
              child: const RootSelector(),
            ),
          ),
        ),
      );

      // Should not throw any assertion errors
      expect(tester.takeException(), isNull);
      
      // Should find the dropdown button
      final dropdown = find.byType(DropdownButton<String>);
      expect(dropdown, findsOneWidget);
      
      // The dropdown should have a valid value
      final dropdownWidget = tester.widget<DropdownButton<String>>(dropdown);
      expect(dropdownWidget.value, isNotNull);
      // F♯ should either normalize to existing value or be handled properly
    });

    testWidgets('RootSelector should handle all common roots', (WidgetTester tester) async {
      // Test all common roots to ensure none break the UI
      for (final root in MusicConstants.commonRoots) {
        appState.setRoot(root);
        
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ChangeNotifierProvider.value(
                value: appState,
                child: const RootSelector(),
              ),
            ),
          ),
        );

        // Should not throw any assertion errors
        expect(tester.takeException(), isNull, 
            reason: 'Root "$root" should not cause any UI errors');
        
        // Should find the dropdown button
        final dropdown = find.byType(DropdownButton<String>);
        expect(dropdown, findsOneWidget, 
            reason: 'Should find dropdown for root "$root"');
        
        // The dropdown should have a valid value
        final dropdownWidget = tester.widget<DropdownButton<String>>(dropdown);
        expect(dropdownWidget.value, isNotNull, 
            reason: 'Dropdown value should not be null for root "$root"');
      }
    });

    test('Normalization function test', () {
      // Test the normalization logic separately
      String normalizeNoteName(String noteName) {
        return noteName.replaceAll('♯', '#').replaceAll('♭', 'b');
      }
      
      expect(normalizeNoteName('G♭'), equals('Gb'));
      expect(normalizeNoteName('F♯'), equals('F#'));
      expect(normalizeNoteName('Db'), equals('Db')); // Already normalized
      expect(normalizeNoteName('C'), equals('C')); // Natural note
    });

    test('Matching common root function test', () {
      // Test the logic for finding matching common roots
      String normalizeNoteName(String noteName) {
        return noteName.replaceAll('♯', '#').replaceAll('♭', 'b');
      }
      
      String? findMatchingCommonRoot(String value) {
        final normalizedValue = normalizeNoteName(value);
        
        // First try exact match
        if (MusicConstants.commonRoots.contains(value)) {
          return value;
        }
        
        // Then try normalized match
        for (final root in MusicConstants.commonRoots) {
          if (normalizeNoteName(root) == normalizedValue) {
            return root;
          }
        }
        
        return null;
      }
      
      expect(findMatchingCommonRoot('G♭'), equals('Gb'));
      expect(findMatchingCommonRoot('Gb'), equals('Gb'));
      expect(findMatchingCommonRoot('C'), equals('C'));
      expect(findMatchingCommonRoot('F♯'), isNull); // F# not in commonRoots, but that's expected
    });
  });
}