// lib/views/widgets/controls/scale_selector.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/app_state.dart';
import '../../../models/music/scale.dart';

class ScaleSelector extends StatelessWidget {
  final Function(String)? onChanged;
  final String? value;

  const ScaleSelector({
    super.key,
    this.onChanged,
    this.value,
  });

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final currentValue = value ?? state.scale;

    return DropdownButton<String>(
      value: currentValue,
      isExpanded: true,
      underline: const SizedBox(),
      items: Scale.all.keys
          .map((scale) => DropdownMenuItem(
                value: scale,
                child: Text(scale),
              ))
          .toList(),
      onChanged: (scale) {
        if (scale != null) {
          if (onChanged != null) {
            onChanged!(scale);
          } else {
            state.setScale(scale);
          }
        }
      },
    );
  }
}
