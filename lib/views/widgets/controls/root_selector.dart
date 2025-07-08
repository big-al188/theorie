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
    
    // Ensure we have a valid value from the list
    final validValue = MusicConstants.commonRoots.contains(currentValue) 
        ? currentValue 
        : MusicConstants.commonRoots.first;

    return DropdownButton<String>(
      value: validValue,
      isExpanded: true,
      underline: const SizedBox(),
      items: MusicConstants.commonRoots
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