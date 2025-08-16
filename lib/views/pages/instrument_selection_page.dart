// lib/views/pages/instrument_selection_page.dart
import 'package:flutter/material.dart';
import '../../models/learning/learning_content.dart';
import '../../constants/ui_constants.dart';
import 'home_page.dart'; // This will be the original home page
import 'keyboard_configuration_page.dart'; // Keyboard configuration page

class InstrumentSelectionPage extends StatelessWidget {
  const InstrumentSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final deviceType = ResponsiveConstants.getDeviceType(screenWidth);
    final orientation = MediaQuery.of(context).orientation;
    final isLandscape = orientation == Orientation.landscape;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Select Your Instrument',
          style: TextStyle(
            fontSize: deviceType == DeviceType.mobile ? 18.0 : 20.0,
          ),
        ),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(_getPadding(deviceType, isLandscape)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, deviceType),
              SizedBox(height: deviceType == DeviceType.mobile ? 24.0 : 32.0),
              _buildInstrumentGrid(context, deviceType, isLandscape),
            ],
          ),
        ),
      ),
    );
  }

  double _getPadding(DeviceType deviceType, bool isLandscape) {
    if (isLandscape && deviceType == DeviceType.mobile) {
      return 16.0; // Reduced padding for landscape mobile
    }
    return deviceType == DeviceType.mobile ? 20.0 : 32.0;
  }

  Widget _buildHeader(BuildContext context, DeviceType deviceType) {
    final titleFontSize = deviceType == DeviceType.mobile ? 24.0 : 28.0;
    final subtitleFontSize = deviceType == DeviceType.mobile ? 16.0 : 18.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose Your Instrument',
          style: TextStyle(
            fontSize: titleFontSize,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
        const SizedBox(height: 8),
        // Only show descriptive text on desktop and tablet
        if (deviceType != DeviceType.mobile) ...[
          Text(
            'Select an instrument to explore its interactive fretboard and music theory concepts.',
            style: TextStyle(
              fontSize: subtitleFontSize,
              color: Colors.grey.shade600,
              height: 1.4,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildInstrumentGrid(BuildContext context, DeviceType deviceType, bool isLandscape) {
    final instruments = LearningContentRepository.getAllInstruments();
    
    // Responsive grid layout
    int crossAxisCount;
    double childAspectRatio;
    
    if (deviceType == DeviceType.mobile) {
      if (isLandscape) {
        crossAxisCount = 4; // More columns in landscape
        childAspectRatio = 0.9; // Slightly taller than wide
      } else {
        crossAxisCount = 2; // Two columns in portrait
        childAspectRatio = 1.0; // Square-ish cards
      }
    } else if (deviceType == DeviceType.tablet) {
      crossAxisCount = isLandscape ? 4 : 3;
      childAspectRatio = 1.1; // Slightly wider than tall
    } else {
      crossAxisCount = 4; // Desktop
      childAspectRatio = 1.1; // Slightly wider than tall
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: deviceType == DeviceType.mobile ? 12.0 : 16.0,
        mainAxisSpacing: deviceType == DeviceType.mobile ? 12.0 : 16.0,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: instruments.length,
      itemBuilder: (context, index) {
        final instrument = instruments[index];
        return _buildInstrumentCard(context, instrument, deviceType, isLandscape);
      },
    );
  }

  Widget _buildInstrumentCard(BuildContext context, Instrument instrument, DeviceType deviceType, bool isLandscape) {
    final isAvailable = instrument.isAvailable;
    
    // Mobile-specific styling
    if (deviceType == DeviceType.mobile) {
      return _buildMobileInstrumentCard(context, instrument, isAvailable, isLandscape);
    }
    
    // Desktop/Tablet styling with full descriptions
    return _buildDesktopInstrumentCard(context, instrument, isAvailable, deviceType);
  }

  Widget _buildMobileInstrumentCard(BuildContext context, Instrument instrument, bool isAvailable, bool isLandscape) {
    final titleFontSize = isLandscape ? 16.0 : 18.0;
    final iconSize = isLandscape ? 36.0 : 48.0;

    return Card(
      elevation: 4,
      child: InkWell(
        onTap: isAvailable ? () => _navigateToInstrument(context, instrument) : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: isAvailable ? null : Colors.grey.shade100,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(
                child: Icon(
                  _getInstrumentIcon(instrument),
                  size: iconSize,
                  color: isAvailable 
                      ? Theme.of(context).primaryColor 
                      : Colors.grey.shade400,
                ),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: Text(
                  instrument.displayName,
                  style: TextStyle(
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.bold,
                    color: isAvailable ? null : Colors.grey.shade500,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // No description text on mobile for cleaner look
              if (!isAvailable) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Coming Soon',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.orange.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopInstrumentCard(BuildContext context, Instrument instrument, bool isAvailable, DeviceType deviceType) {
    final titleFontSize = deviceType == DeviceType.tablet ? 18.0 : 20.0;
    final subtitleFontSize = deviceType == DeviceType.tablet ? 14.0 : 16.0;
    final iconSize = deviceType == DeviceType.tablet ? 48.0 : 56.0;

    return Card(
      elevation: 4,
      child: InkWell(
        onTap: isAvailable ? () => _navigateToInstrument(context, instrument) : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: isAvailable ? null : Colors.grey.shade100,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Icon(
                  _getInstrumentIcon(instrument),
                  size: iconSize,
                  color: isAvailable 
                      ? Theme.of(context).primaryColor 
                      : Colors.grey.shade400,
                ),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: Text(
                  instrument.displayName,
                  style: TextStyle(
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.bold,
                    color: isAvailable ? null : Colors.grey.shade500,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: Text(
                  instrument.description,
                  style: TextStyle(
                    fontSize: subtitleFontSize,
                    color: isAvailable 
                        ? Colors.grey.shade600 
                        : Colors.grey.shade400,
                    height: 1.3,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (!isAvailable) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Coming Soon',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  IconData _getInstrumentIcon(Instrument instrument) {
    switch (instrument) {
      case Instrument.guitar:
        return Icons.music_note; // Closest to guitar
      case Instrument.piano:
        return Icons.piano;
      case Instrument.bass:
        return Icons.music_note;
      case Instrument.ukulele:
        return Icons.music_note;
    }
  }

  void _navigateToInstrument(BuildContext context, Instrument instrument) {
    switch (instrument) {
      case Instrument.guitar:
        // Navigate to the original home page (now the guitar page)
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
        break;
      case Instrument.piano:
        // Navigate to keyboard configuration page
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const KeyboardConfigurationPage()),
        );
        break;
      case Instrument.bass:
      case Instrument.ukulele:
        // Show coming soon message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${instrument.displayName} support is coming soon!'),
            backgroundColor: Colors.orange.shade600,
          ),
        );
        break;
    }
  }
}