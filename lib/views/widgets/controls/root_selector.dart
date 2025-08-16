// lib/views/widgets/controls/root_selector.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/app_state.dart';
import '../../../constants/music_constants.dart';

class RootSelector extends StatelessWidget {
  final Function(String)? onChanged;
  final String? value;

  const RootSelector({
    super.key,
    this.onChanged,
    this.value,
  });

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final currentValue = value ?? state.root;
    
    // Normalize note names for comparison (♯ -> #, ♭ -> b)
    String normalizeNoteName(String noteName) {
      return noteName.replaceAll('♯', '#').replaceAll('♭', 'b');
    }
    
    // Find the matching common root, considering both formats and enharmonic equivalents
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
      
      // Handle enharmonic equivalents (sharp to flat conversions)
      const enharmonicMap = {
        'F#': 'Gb', 'f#': 'Gb',
        'C#': 'Db', 'c#': 'Db', 
        'G#': 'Ab', 'g#': 'Ab',
        'D#': 'Eb', 'd#': 'Eb',
        'A#': 'Bb', 'a#': 'Bb',
        // Unicode versions
        'F♯': 'Gb',
        'C♯': 'Db',
        'G♯': 'Ab', 
        'D♯': 'Eb',
        'A♯': 'Bb',
      };
      
      // Check if the value is an enharmonic equivalent that should map to a common root
      final enharmonicEquivalent = enharmonicMap[value] ?? enharmonicMap[normalizedValue];
      if (enharmonicEquivalent != null && MusicConstants.commonRoots.contains(enharmonicEquivalent)) {
        return enharmonicEquivalent;
      }
      
      return null;
    }
    
    // Get the appropriate value to use in dropdown
    final matchingRoot = findMatchingCommonRoot(currentValue);
    final dropdownValue = matchingRoot ?? currentValue;
    
    // Create a set to avoid duplicates, then convert to list
    final rootOptionsSet = Set<String>.from(MusicConstants.commonRoots);
    
    // Ensure the dropdown value is always included
    rootOptionsSet.add(dropdownValue);
    
    // Convert to list and sort
    final sortedRoots = rootOptionsSet.toList()
      ..sort((a, b) {
        // Sort by circle of fifths order if possible
        final aIndex = MusicConstants.circleOfFifths.indexOf(a);
        final bIndex = MusicConstants.circleOfFifths.indexOf(b);
        if (aIndex != -1 && bIndex != -1) {
          return aIndex.compareTo(bIndex);
        }
        // Otherwise alphabetical
        return a.compareTo(b);
      });

    return DropdownButton<String>(
      value: dropdownValue,
      isExpanded: true,
      underline: const SizedBox(),
      items: sortedRoots
          .map((root) => DropdownMenuItem(
                value: root,
                child: Text(root),
              ))
          .toList(),
      onChanged: (root) {
        if (root != null) {
          debugPrint('RootSelector: Selected root = $root');
          if (onChanged != null) {
            onChanged!(root);
          } else {
            state.setRoot(root);
          }
        }
      },
    );
  }
}