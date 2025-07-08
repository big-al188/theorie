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
    
    // Create a list that includes the current value if it's not in commonRoots
    final rootOptions = MusicConstants.commonRoots.contains(currentValue)
        ? MusicConstants.commonRoots
        : [...MusicConstants.commonRoots, currentValue];
    
    // Sort the list to maintain consistent order
    final sortedRoots = List<String>.from(rootOptions)
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
      value: currentValue,
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