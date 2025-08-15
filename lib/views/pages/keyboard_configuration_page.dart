// lib/views/pages/keyboard_configuration_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/app_state.dart';
import '../../constants/ui_constants.dart';
import '../../constants/keyboard_constants.dart';
import '../../models/fretboard/fretboard_config.dart'; // For ViewMode
import '../widgets/controls/root_selector.dart';
import '../widgets/controls/view_mode_selector.dart';
import '../widgets/controls/scale_selector.dart';
import '../widgets/common/app_bar.dart';
import 'keyboard_page.dart';

/// Keyboard configuration page following the same pattern as HomePage
/// Allows users to configure keyboard settings before opening the keyboard view
class KeyboardConfigurationPage extends StatefulWidget {
  const KeyboardConfigurationPage({super.key});

  @override
  State<KeyboardConfigurationPage> createState() => _KeyboardConfigurationPageState();
}

class _KeyboardConfigurationPageState extends State<KeyboardConfigurationPage> {
  // Keyboard-specific state
  String _selectedKeyboardType = KeyboardConstants.defaultKeyboardType;
  int _selectedKeyCount = KeyboardConstants.defaultKeyCount;
  String _selectedStartNote = KeyboardConstants.defaultStartNote;

  @override
  void initState() {
    super.initState();
    // Initialize with defaults
    _updateKeyboardDefaults();
  }

  void _updateKeyboardDefaults() {
    final config = KeyboardConstants.defaultConfigurations[_selectedKeyboardType];
    if (config != null) {
      setState(() {
        _selectedKeyCount = config['keyCount'];
        _selectedStartNote = config['startNote'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final orientation = MediaQuery.of(context).orientation;
    final deviceType = ResponsiveConstants.getDeviceType(screenWidth);
    final isLandscape = orientation == Orientation.landscape;
    
    // Responsive padding following HomePage pattern
    final horizontalPadding = _getHorizontalPadding(deviceType, isLandscape);
    final verticalPadding = _getVerticalPadding(deviceType, isLandscape);
    
    return Scaffold(
      appBar: const TheorieAppBar(
        title: 'Piano Theory Configuration',
        showSettings: true,
        showThemeToggle: true,
        showLogout: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: verticalPadding,
          ),
          child: _buildContent(context, deviceType, isLandscape, screenWidth, screenHeight),
        ),
      ),
    );
  }

  double _getHorizontalPadding(DeviceType deviceType, bool isLandscape) {
    if (isLandscape && deviceType == DeviceType.mobile) {
      return 24.0;
    }
    return deviceType == DeviceType.mobile ? 16.0 : 32.0;
  }

  double _getVerticalPadding(DeviceType deviceType, bool isLandscape) {
    if (isLandscape && deviceType == DeviceType.mobile) {
      return 8.0;
    }
    return deviceType == DeviceType.mobile ? 16.0 : 24.0;
  }

  Widget _buildContent(BuildContext context, DeviceType deviceType, bool isLandscape, double screenWidth, double screenHeight) {
    return Column(
      children: [
        // Title section
        if (isLandscape && deviceType == DeviceType.mobile)
          _buildCompactTitleSection(context, deviceType)
        else
          _buildTitleSection(context, deviceType),
        
        SizedBox(height: deviceType == DeviceType.mobile && !isLandscape ? 32.0 : 48.0),

        // Keyboard configuration section
        if (isLandscape && deviceType == DeviceType.mobile)
          _buildCompactKeyboardConfigSection(context, deviceType, screenWidth)
        else
          _buildKeyboardConfigSection(context, deviceType, screenWidth),
        
        const SizedBox(height: 24.0),

        // Music theory settings section
        if (isLandscape && deviceType == DeviceType.mobile)
          _buildCompactMusicTheorySection(context, deviceType, screenWidth)
        else
          _buildMusicTheorySection(context, deviceType, screenWidth),
        
        SizedBox(height: deviceType == DeviceType.mobile ? 24.0 : 32.0),

        // Open keyboard button
        _buildActionButton(context, deviceType),
        
        // Bottom padding
        const SizedBox(height: 32.0),
      ],
    );
  }

  Widget _buildCompactTitleSection(BuildContext context, DeviceType deviceType) {
    return Column(
      children: [
        Text(
          'Piano Theory',
          style: UIConstants.headingStyle.copyWith(fontSize: 24.0),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          'Interactive Piano Keyboard Theory',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                fontSize: 14.0,
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildTitleSection(BuildContext context, DeviceType deviceType) {
    final titleFontSize = deviceType == DeviceType.mobile ? 28.0 : 32.0;
    final subtitleFontSize = deviceType == DeviceType.mobile ? 16.0 : 18.0;
    
    return Column(
      children: [
        Text(
          'Piano Theory',
          style: UIConstants.headingStyle.copyWith(fontSize: titleFontSize),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Interactive Piano Keyboard Theory',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                fontSize: subtitleFontSize,
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildCompactKeyboardConfigSection(BuildContext context, DeviceType deviceType, double screenWidth) {
    return Center(
      child: Container(
        constraints: BoxConstraints(
          maxWidth: deviceType == DeviceType.mobile ? screenWidth * 0.95 : 600.0,
        ),
        child: Card(
          elevation: 2,
          child: Padding(
            padding: EdgeInsets.all(deviceType == DeviceType.mobile ? 8.0 : 12.0),
            child: Column(
              children: [
                // Use flexible layout for very small screens
                screenWidth < 320 
                  ? Column(
                      children: [
                        _buildSmallSettingItem(context, 'Keyboard:', _buildKeyboardTypeSelector()),
                        const SizedBox(height: 12),
                        _buildSmallSettingItem(context, 'Start Note:', _buildStartNoteSelector()),
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(
                          flex: 2, // Give more space to keyboard type
                          child: _buildSmallSettingItem(context, 'Keyboard:', _buildKeyboardTypeSelector()),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 1, // Less space for start note
                          child: _buildSmallSettingItem(context, 'Start Note:', _buildStartNoteSelector()),
                        ),
                      ],
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKeyboardConfigSection(BuildContext context, DeviceType deviceType, double screenWidth) {
    final isCompact = deviceType == DeviceType.mobile || screenWidth < 400;
    final isVerySmall = screenWidth < 320;
    
    return Center(
      child: Container(
        constraints: BoxConstraints(
          maxWidth: deviceType == DeviceType.mobile 
              ? screenWidth * 0.95 
              : 400.0,
        ),
        child: Card(
          elevation: 2,
          child: Padding(
            padding: EdgeInsets.all(
              isVerySmall ? 12.0 : 
              deviceType == DeviceType.mobile ? 16.0 : 24.0
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Keyboard Configuration',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: isVerySmall ? 14.0 : null,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: isVerySmall ? 12.0 : 16.0),
                
                if (isCompact) ...[
                  _buildSettingItem(context, 'Keyboard Type:', _buildKeyboardTypeSelector()),
                  SizedBox(height: isVerySmall ? 12.0 : 16.0),
                  _buildSettingItem(context, 'Start Note:', _buildStartNoteSelector()),
                ] else ...[
                  _SettingRow(
                    label: 'Keyboard Type:',
                    child: SizedBox(
                      width: 180,
                      child: _buildKeyboardTypeSelector(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _SettingRow(
                    label: 'Start Note:',
                    child: SizedBox(
                      width: 100,
                      child: _buildStartNoteSelector(),
                    ),
                  ),
                ],
                SizedBox(height: isVerySmall ? 8.0 : 12.0),
                _buildKeyboardInfo(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactMusicTheorySection(BuildContext context, DeviceType deviceType, double screenWidth) {
    final isVerySmall = screenWidth < 320;
    
    return Center(
      child: Container(
        constraints: BoxConstraints(
          maxWidth: deviceType == DeviceType.mobile ? screenWidth * 0.95 : 600.0,
        ),
        child: Card(
          elevation: 2,
          child: Padding(
            padding: EdgeInsets.all(isVerySmall ? 8.0 : 12.0),
            child: Column(
              children: [
                // First row: Root and View Mode
                isVerySmall
                  ? Column(
                      children: [
                        _buildSmallSettingItem(context, 'Root:', const RootSelector()),
                        const SizedBox(height: 8),
                        _buildSmallSettingItem(context, 'View Mode:', const ViewModeSelector()),
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: _buildSmallSettingItem(context, 'Root:', const RootSelector()),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2, // Give more space to view mode
                          child: _buildSmallSettingItem(context, 'View Mode:', const ViewModeSelector()),
                        ),
                      ],
                    ),
                SizedBox(height: isVerySmall ? 8.0 : 12.0),
                
                // Second row: Scale (if needed)
                Consumer<AppState>(
                  builder: (context, state, child) {
                    if (state.isScaleMode) {
                      return _buildSmallSettingItem(context, 'Scale:', const ScaleSelector());
                    } else if (_isAnyChordMode(state.viewMode)) {
                      return _buildChordModeInfo(context, state.viewMode, compact: true);
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMusicTheorySection(BuildContext context, DeviceType deviceType, double screenWidth) {
    final isCompact = deviceType == DeviceType.mobile || screenWidth < 400;
    
    return Center(
      child: Container(
        constraints: BoxConstraints(
          maxWidth: deviceType == DeviceType.mobile ? double.infinity : 400.0,
        ),
        child: Card(
          elevation: 2,
          child: Padding(
            padding: EdgeInsets.all(deviceType == DeviceType.mobile ? 16.0 : 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Music Theory Settings',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                
                if (isCompact) ...[
                  _buildSettingItem(context, 'Root:', const RootSelector()),
                  const SizedBox(height: 16),
                  _buildSettingItem(context, 'View Mode:', const ViewModeSelector()),
                  const SizedBox(height: 16),
                  Consumer<AppState>(
                    builder: (context, state, child) {
                      if (state.isScaleMode) {
                        return _buildSettingItem(context, 'Scale:', const ScaleSelector());
                      } else if (_isAnyChordMode(state.viewMode)) {
                        return _buildChordModeInfo(context, state.viewMode, compact: true);
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ] else ...[
                  _SettingRow(
                    label: 'Root:',
                    child: SizedBox(
                      width: 80,
                      child: RootSelector(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _SettingRow(
                    label: 'View Mode:',
                    child: SizedBox(
                      width: 160,
                      child: ViewModeSelector(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Consumer<AppState>(
                    builder: (context, state, child) {
                      if (state.isScaleMode) {
                        return Column(
                          children: [
                            _SettingRow(
                              label: 'Scale:',
                              child: SizedBox(
                                width: 160,
                                child: ScaleSelector(),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                        );
                      } else if (_isAnyChordMode(state.viewMode)) {
                        return _buildChordModeInfo(context, state.viewMode);
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKeyboardTypeSelector() {
    return DropdownButtonFormField<String>(
      value: _selectedKeyboardType,
      decoration: const InputDecoration(
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      isExpanded: true, // Prevent overflow
      items: KeyboardConstants.keyboardTypes.keys.map((String type) {
        final keyCount = KeyboardConstants.keyboardTypes[type]!;
        return DropdownMenuItem<String>(
          value: type,
          child: Text(
            '$type ($keyCount keys)',
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        );
      }).toList(),
      onChanged: (String? newValue) {
        if (newValue != null) {
          setState(() {
            _selectedKeyboardType = newValue;
            _updateKeyboardDefaults();
          });
        }
      },
    );
  }

  Widget _buildStartNoteSelector() {
    return DropdownButtonFormField<String>(
      value: _selectedStartNote,
      decoration: const InputDecoration(
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      isExpanded: true, // Prevent overflow
      items: KeyboardConstants.commonStartNotes.map((String note) {
        return DropdownMenuItem<String>(
          value: note,
          child: Text(
            note,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        );
      }).toList(),
      onChanged: (String? newValue) {
        if (newValue != null) {
          setState(() {
            _selectedStartNote = newValue;
          });
        }
      },
    );
  }

  Widget _buildKeyboardInfo() {
    final octaveCount = KeyboardConstants.getOctaveCount(_selectedKeyCount);
    final description = KeyboardConstants.getKeyboardDescription(_selectedKeyboardType);
    
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Keys: $_selectedKeyCount'),
              Text('Range: ${octaveCount.toStringAsFixed(1)} octaves'),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSmallSettingItem(BuildContext context, String label, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        child,
      ],
    );
  }

  Widget _buildSettingItem(BuildContext context, String label, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  bool _isAnyChordMode(ViewMode viewMode) {
    return viewMode == ViewMode.chordInversions ||
           viewMode == ViewMode.openChords ||
           viewMode == ViewMode.barreChords ||
           viewMode == ViewMode.advancedChords;
  }

  Widget _buildChordModeInfo(BuildContext context, ViewMode viewMode, {bool compact = false}) {
    String message;
    IconData icon;
    Color? iconColor;

    if (viewMode == ViewMode.chordInversions) {
      message = 'Open keyboard for chord inversions';
      icon = Icons.piano;
      iconColor = Theme.of(context).colorScheme.primary;
    } else if (!viewMode.isImplemented) {
      message = '${viewMode.displayName} mode coming soon!';
      icon = Icons.construction;
      iconColor = Theme.of(context).colorScheme.secondary;
    } else {
      message = 'Open keyboard for chord selection';
      icon = Icons.info_outline;
      iconColor = Theme.of(context).colorScheme.primary;
    }

    return Container(
      padding: EdgeInsets.all(compact ? 8.0 : 12.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: compact ? 16 : 20,
            color: iconColor,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              message,
              style: TextStyle(
                fontSize: compact ? 12.0 : 14.0,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, DeviceType deviceType) {
    final buttonHeight = deviceType == DeviceType.mobile ? 48.0 : 56.0;
    final fontSize = deviceType == DeviceType.mobile ? 16.0 : 18.0;
    
    return Center(
      child: SizedBox(
        width: deviceType == DeviceType.mobile ? double.infinity : 300.0,
        height: buttonHeight,
        child: ElevatedButton.icon(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => KeyboardPage(
                  keyboardType: _selectedKeyboardType,
                  keyCount: _selectedKeyCount,
                  startNote: _selectedStartNote,
                ),
              ),
            );
          },
          icon: const Icon(Icons.piano),
          label: Text(
            'Open Keyboard',
            style: TextStyle(fontSize: fontSize),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  final String label;
  final Widget child;

  const _SettingRow({
    required this.label,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        child,
      ],
    );
  }
}