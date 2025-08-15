// lib/views/pages/keyboard_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/app_state.dart';
import '../../models/keyboard/keyboard_instance.dart';
import '../../constants/ui_constants.dart';
import '../widgets/common/app_bar.dart';
import '../widgets/keyboard/keyboard_widget.dart';
import '../widgets/controls/keyboard_controls.dart';
import '../../models/keyboard/key_configuration.dart';
import '../../models/keyboard/keyboard_config.dart';
import '../../models/fretboard/fretboard_config.dart'; // For ViewMode
import '../../models/music/chord.dart'; // For ChordInversion

/// Keyboard page following the same pattern as FretboardPage
/// Displays and manages keyboard instances with music theory visualization
class KeyboardPage extends StatefulWidget {
  final String keyboardType;
  final int keyCount;
  final String startNote;

  const KeyboardPage({
    super.key,
    required this.keyboardType,
    required this.keyCount,
    required this.startNote,
  });

  @override
  State<KeyboardPage> createState() => _KeyboardPageState();
}

class _KeyboardPageState extends State<KeyboardPage> {
  List<KeyboardInstance> _keyboards = [];
  int _nextId = 1;
  bool _cleanViewMode = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _addKeyboard();
    });
  }

  void _addKeyboard() {
    // Get current state from AppState to initialize keyboard
    final appState = context.read<AppState>();

    setState(() {
      var newKeyboard = KeyboardInstance(
        id: 'keyboard_${_nextId++}',

        // Use CURRENT SESSION STATE for music settings
        root: appState.root,
        viewMode: appState.viewMode,
        scale: appState.scale,
        modeIndex: appState.modeIndex,
        selectedOctaves: Set.from(appState.selectedOctaves),
        selectedIntervals: Set.from(appState.selectedIntervals),

        // Use passed keyboard configuration
        keyCount: widget.keyCount,
        startNote: widget.startNote,
        keyboardType: widget.keyboardType,
        chordType: 'major',
        chordInversion: ChordInversion.root,

        // Standard new keyboard settings
        showScaleStrip: true,
        showNoteNames: false,
        showAdditionalOctaves: false,
        showOctave: false,
        isCompact: false,
      );

      _keyboards.add(newKeyboard);
    });
  }

  void _removeKeyboard(String id) {
    if (_keyboards.length > 1) {
      setState(() {
        _keyboards.removeWhere((k) => k.id == id);
      });
    }
  }

  void _updateKeyboard(String id, KeyboardInstance updated) {
    setState(() {
      final index = _keyboards.indexWhere((k) => k.id == id);
      if (index != -1) {
        _keyboards[index] = updated;
      }
    });
  }

  void _toggleCleanView() {
    setState(() {
      _cleanViewMode = !_cleanViewMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Consumer<AppState>(
      builder: (context, state, child) {
        return Scaffold(
          appBar: TheorieAppBar(
            title: 'Multi-Keyboard View',
            actions: [
              // Page-specific actions
              IconButton(
                icon: Icon(
                  _cleanViewMode ? Icons.visibility_off : Icons.visibility,
                ),
                tooltip: _cleanViewMode
                    ? 'Show Controls'
                    : 'Hide Controls (Clean View)',
                onPressed: _toggleCleanView,
              ),
              if (!_cleanViewMode)
                IconButton(
                  icon: const Icon(Icons.add),
                  tooltip: 'Add Keyboard',
                  onPressed: _addKeyboard,
                ),
            ],
          ),
          body: _keyboards.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : ListView.separated(
                  padding: EdgeInsets.all(_getListPadding(screenWidth)),
                  itemCount: _keyboards.length,
                  separatorBuilder: (context, index) =>
                      SizedBox(height: _getSeparatorHeight(screenWidth)),
                  itemBuilder: (context, index) {
                    final keyboard = _keyboards[index];
                    return _KeyboardCard(
                      key: ValueKey(keyboard.id),
                      keyboard: keyboard,
                      globalState: state,
                      canRemove: _keyboards.length > 1,
                      cleanViewMode: _cleanViewMode,
                      screenWidth: screenWidth,
                      onUpdate: (updated) =>
                          _updateKeyboard(keyboard.id, updated),
                      onRemove: () => _removeKeyboard(keyboard.id),
                    );
                  },
                ),
        );
      },
    );
  }

  double _getListPadding(double screenWidth) {
    if (_cleanViewMode) {
      return ResponsiveConstants.getCleanViewPadding(screenWidth);
    }

    final deviceType = ResponsiveConstants.getDeviceType(screenWidth);
    switch (deviceType) {
      case DeviceType.mobile:
        return 8.0;
      case DeviceType.tablet:
        return 12.0;
      case DeviceType.desktop:
        return 16.0;
    }
  }

  double _getSeparatorHeight(double screenWidth) {
    if (_cleanViewMode) {
      final deviceType = ResponsiveConstants.getDeviceType(screenWidth);
      switch (deviceType) {
        case DeviceType.mobile:
          return 4.0;
        case DeviceType.tablet:
          return 6.0;
        case DeviceType.desktop:
          return 8.0;
      }
    }

    final deviceType = ResponsiveConstants.getDeviceType(screenWidth);
    switch (deviceType) {
      case DeviceType.mobile:
        return 16.0;
      case DeviceType.tablet:
        return 20.0;
      case DeviceType.desktop:
        return 24.0;
    }
  }
}

class _KeyboardCard extends StatelessWidget {
  final KeyboardInstance keyboard;
  final AppState globalState;
  final bool canRemove;
  final bool cleanViewMode;
  final double screenWidth;
  final Function(KeyboardInstance) onUpdate;
  final VoidCallback onRemove;

  const _KeyboardCard({
    super.key,
    required this.keyboard,
    required this.globalState,
    required this.canRemove,
    required this.cleanViewMode,
    required this.screenWidth,
    required this.onUpdate,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    // Check if this mode is not yet implemented
    if (!keyboard.viewMode.isImplemented) {
      return _buildUnimplementedCard(context, keyboard);
    }

    return Card(
      margin: cleanViewMode ? EdgeInsets.zero : null,
      elevation: cleanViewMode ? 0 : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!cleanViewMode) _buildHeader(context, keyboard),
          if (!cleanViewMode && !keyboard.isCompact)
            KeyboardControls(
              instance: keyboard,
              onUpdate: onUpdate,
            ),
          _buildKeyboardSection(context, keyboard),
        ],
      ),
    );
  }

  Widget _buildKeyboardSection(BuildContext context, KeyboardInstance instance) {
    final config = instance.toConfig();

    // Calculate responsive dimensions
    final deviceType = ResponsiveConstants.getDeviceType(screenWidth);
    final availableWidth = screenWidth - _getHorizontalPadding(deviceType);

    // Improved responsive keyboard height calculation
    final isVerySmall = screenWidth < 320;
    final baseHeight = deviceType == DeviceType.mobile 
        ? (isVerySmall ? 100.0 : 120.0) 
        : 150.0;
    final scaleStripHeight = instance.showScaleStrip 
        ? (isVerySmall ? 40.0 : 50.0) 
        : 0.0;
    final totalKeyboardHeight = cleanViewMode 
        ? baseHeight * 1.3 + scaleStripHeight 
        : baseHeight + scaleStripHeight;

    return Container(
      padding: EdgeInsets.all(_getCardPadding()),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        children: [
          // Main keyboard widget with improved sizing
          SizedBox(
            width: availableWidth,
            height: totalKeyboardHeight,
            child: KeyboardWidget(
              config: config.copyWith(
                width: availableWidth,
                height: totalKeyboardHeight,
                showChordName: cleanViewMode && config.isAnyChordMode,
                showScaleStrip: instance.showScaleStrip,
              ),
              onKeyTap: (keyConfig) {
                _handleKeyTap(keyConfig);
              },
            ),
          ),
        ],
      ),
    );
  }

  double _getHorizontalPadding(DeviceType deviceType) {
    switch (deviceType) {
      case DeviceType.mobile:
        return screenWidth < 320 ? 16.0 : 32.0; // Less padding for very small screens
      case DeviceType.tablet:
        return 48.0;
      case DeviceType.desktop:
        return 64.0;
    }
  }

  Widget _buildUnimplementedCard(BuildContext context, KeyboardInstance instance) {
    return Card(
      margin: cleanViewMode ? EdgeInsets.zero : null,
      elevation: cleanViewMode ? 0 : null,
      child: Container(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.construction,
              size: 48,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              '${instance.viewMode.displayName} Mode',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Coming Soon!',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'This mode is currently under development and will be available in a future update.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton.icon(
                  onPressed: () => onUpdate(
                      keyboard.copyWith(viewMode: ViewMode.chordInversions)),
                  icon: const Icon(Icons.piano),
                  label: const Text('Try Chord Inversions'),
                ),
                const SizedBox(width: 16),
                if (canRemove)
                  TextButton.icon(
                    onPressed: onRemove,
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Remove'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  double _getCardPadding() {
    if (cleanViewMode) {
      return ResponsiveConstants.getCleanViewPadding(screenWidth);
    }
    return ResponsiveConstants.getCardPadding(screenWidth, keyboard.isCompact);
  }

  Widget _buildHeader(BuildContext context, KeyboardInstance instance) {
    final config = instance.toConfig();
    String headerText = _getHeaderText(config);
    final deviceType = ResponsiveConstants.getDeviceType(screenWidth);
    final isMobile = deviceType == DeviceType.mobile;
    final isVerySmall = screenWidth < 320;

    // Responsive header font size
    final headerFontSize = ResponsiveConstants.getScaledFontSize(
      isVerySmall ? 12.0 : 16.0, 
      screenWidth
    );

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isVerySmall ? 8.0 : (isMobile ? 12.0 : 16.0),
        vertical: isVerySmall ? 4.0 : (isMobile ? 6.0 : 8.0),
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: isVerySmall 
        ? _buildCompactHeader(context, instance, headerText, headerFontSize)
        : _buildFullHeader(context, instance, headerText, headerFontSize, isMobile),
    );
  }

  Widget _buildCompactHeader(BuildContext context, KeyboardInstance instance, String headerText, double fontSize) {
    return Column(
      children: [
        // First row: expand/collapse and header text
        Row(
          children: [
            IconButton(
              icon: Icon(instance.isCompact ? Icons.expand_more : Icons.expand_less),
              tooltip: instance.isCompact ? 'Show Controls' : 'Hide Controls',
              iconSize: 18.0,
              padding: const EdgeInsets.all(4.0),
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              onPressed: () {
                onUpdate(instance.copyWith(isCompact: !instance.isCompact));
              },
            ),
            Expanded(
              child: Text(
                headerText,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
        // Second row: action buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              icon: Icon(
                instance.showScaleStrip ? Icons.piano : Icons.piano_off,
                color: instance.showScaleStrip ? Theme.of(context).primaryColor : null,
              ),
              iconSize: 18.0,
              padding: const EdgeInsets.all(4.0),
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              tooltip: 'Toggle Scale Strip',
              onPressed: () {
                onUpdate(instance.copyWith(showScaleStrip: !instance.showScaleStrip));
              },
            ),
            IconButton(
              icon: Icon(
                instance.showNoteNames ? Icons.abc : Icons.numbers,
                color: instance.showNoteNames ? Theme.of(context).primaryColor : null,
              ),
              iconSize: 18.0,
              padding: const EdgeInsets.all(4.0),
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              tooltip: instance.showNoteNames ? 'Show Intervals' : 'Show Note Names',
              onPressed: () {
                onUpdate(instance.copyWith(showNoteNames: !instance.showNoteNames));
              },
            ),
            if (canRemove)
              IconButton(
                icon: const Icon(Icons.delete_outline),
                iconSize: 18.0,
                padding: const EdgeInsets.all(4.0),
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                tooltip: 'Remove Keyboard',
                onPressed: onRemove,
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildFullHeader(BuildContext context, KeyboardInstance instance, String headerText, double fontSize, bool isMobile) {
    return Row(
      children: [
        IconButton(
          icon: Icon(instance.isCompact ? Icons.expand_more : Icons.expand_less),
          tooltip: instance.isCompact ? 'Show Controls' : 'Hide Controls',
          iconSize: isMobile ? 20.0 : 24.0,
          onPressed: () {
            onUpdate(instance.copyWith(isCompact: !instance.isCompact));
          },
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            headerText,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: isMobile ? 2 : 1,
          ),
        ),
        IconButton(
          icon: Icon(
            instance.showScaleStrip ? Icons.piano : Icons.piano_off,
            color: instance.showScaleStrip ? Theme.of(context).primaryColor : null,
          ),
          iconSize: isMobile ? 20.0 : 24.0,
          tooltip: 'Toggle Scale Strip',
          onPressed: () {
            onUpdate(instance.copyWith(showScaleStrip: !instance.showScaleStrip));
          },
        ),
        IconButton(
          icon: Icon(
            instance.showNoteNames ? Icons.abc : Icons.numbers,
            color: instance.showNoteNames ? Theme.of(context).primaryColor : null,
          ),
          iconSize: isMobile ? 20.0 : 24.0,
          tooltip: instance.showNoteNames ? 'Show Intervals' : 'Show Note Names',
          onPressed: () {
            onUpdate(instance.copyWith(showNoteNames: !instance.showNoteNames));
          },
        ),
        if (canRemove)
          IconButton(
            icon: const Icon(Icons.delete_outline),
            iconSize: isMobile ? 20.0 : 24.0,
            tooltip: 'Remove Keyboard',
            onPressed: onRemove,
          ),
      ],
    );
  }

  String _getHeaderText(KeyboardConfig config) {
    final deviceType = ResponsiveConstants.getDeviceType(screenWidth);
    final isCompact = deviceType == DeviceType.mobile;

    if (config.isAnyChordMode) {
      if (isCompact) {
        return '${config.currentChordName} - ${config.keyboardType}';
      }
      return '${config.currentChordName} - ${config.keyboardType} (${config.keyCount} keys)';
    } else if (config.isIntervalMode) {
      if (isCompact) {
        return '${config.effectiveRoot} Intervals - ${config.keyboardType}';
      }
      return '${config.effectiveRoot} Intervals - ${config.keyboardType} (${config.keyCount} keys)';
    } else if (config.isScaleMode) {
      if (isCompact) {
        return '${config.effectiveRoot} ${config.currentModeName} - ${config.keyboardType}';
      }
      return '${config.effectiveRoot} ${config.currentModeName} - ${config.keyboardType} (${config.keyCount} keys)';
    } else {
      if (isCompact) {
        return '${config.viewMode.displayName} - ${config.keyboardType}';
      }
      return '${config.viewMode.displayName} - ${config.keyboardType} (${config.keyCount} keys)';
    }
  }

  void _handleKeyTap(KeyConfiguration keyConfig) {
    debugPrint('Keyboard key tapped: ${keyConfig.fullNoteName} (MIDI: ${keyConfig.midiNote})');
    
    // For now, just log the tap - the UX engineer will implement detailed interaction
    // The KeyboardController.handleKeyTap method is available for full interaction logic
  }
}