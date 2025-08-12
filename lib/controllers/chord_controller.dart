// lib/controllers/chord_controller.dart
import 'package:flutter/foundation.dart';
import 'dart:math' as math;
import '../models/music/note.dart';
import '../models/music/chord.dart';
import '../models/fretboard/fret_position.dart';
import '../utils/chord_utils.dart';

/// Controller for chord building and analysis
class ChordController {
  /// Build exact chord voicing with proper inversions
  static List<ChordTone> buildChordVoicing({
    required String root,
    required int chromOctave,
    required String chordType,
    required ChordInversion chordInversion,
    required List<String> tuning,
    required int maxFrets,
  }) {
    final chord = Chord.get(chordType);
    if (chord == null) return [];

    final rootNote = Note.fromString('$root$chromOctave');
    final voicingMidiNotes = chord.buildVoicing(
      root: rootNote,
      inversion: chordInversion,
    );

    if (voicingMidiNotes.isEmpty) {
      debugPrint('ERROR: No voicing notes generated for $root $chordType');
      return [];
    }

    debugPrint('=====================================');
    debugPrint('Building exact chord voicing:');
    debugPrint(
        'Root: $root, Octave: $chromOctave, Type: $chordType, Inversion: ${chordInversion.displayName}');
    debugPrint('Voicing MIDI notes: $voicingMidiNotes');

    final chordTones = <ChordTone>[];
    final preferFlats = rootNote.preferFlats;

    // For each note in the voicing, find ALL fretboard positions
    for (int voicingPos = 0;
        voicingPos < voicingMidiNotes.length;
        voicingPos++) {
      final targetMidi = voicingMidiNotes[voicingPos];
      final targetNote = Note.fromMidi(targetMidi, preferFlats: preferFlats);
      final intervalFromRoot =
          (targetNote.pitchClass - rootNote.pitchClass + 12) % 12;

      // Find which chord tone index this represents
      int chordToneIndex = -1;
      for (int i = 0; i < chord.intervals.length; i++) {
        if (chord.intervals[i] % 12 == intervalFromRoot) {
          chordToneIndex = i;
          break;
        }
      }

      // Find all positions of this exact MIDI note on the fretboard
      for (int stringIndex = 0; stringIndex < tuning.length; stringIndex++) {
        final openStringNote = Note.fromString(tuning[stringIndex]);
        final fretNumber = targetMidi - openStringNote.midi;

        // Check if this note is playable on this string
        if (fretNumber >= 0 && fretNumber <= maxFrets) {
          chordTones.add(ChordTone(
            position: FretPositionEx(
              stringIndex: stringIndex,
              fretNumber: fretNumber,
              midiNote: targetMidi,
              noteName: targetNote.fullName,
            ),
            intervalFromRoot: intervalFromRoot,
            intervalName: ChordUtils.getIntervalLabel(intervalFromRoot),
            isRoot: intervalFromRoot == 0,
            chordToneIndex: chordToneIndex,
            voicingPosition: voicingPos,
          ));

          debugPrint(
              '  Found position: ${targetNote.fullName} at string $stringIndex, fret $fretNumber');
        }
      }
    }

    debugPrint('Total positions found: ${chordTones.length}');
    debugPrint('=====================================');

    return chordTones;
  }

  /// Get optimal fingering for the chord voicing
  static List<ChordTone> getOptimalFingering(List<ChordTone> allTones) {
    if (allTones.isEmpty) return [];

    // Group by voicing position
    final tonesByPosition = <int, List<ChordTone>>{};
    for (final tone in allTones) {
      tonesByPosition.putIfAbsent(tone.voicingPosition, () => []).add(tone);
    }

    // Select one position per voicing note, preferring lower frets and adjacent strings
    final selectedTones = <ChordTone>[];
    int? lastStringIndex;

    for (final entry in tonesByPosition.entries) {
      final options = entry.value;

      // Sort options by preference
      options.sort((a, b) {
        // Prefer lower frets
        final fretComp = a.fretNumber.compareTo(b.fretNumber);
        if (fretComp != 0) return fretComp;

        // Prefer strings close to last used string
        if (lastStringIndex != null) {
          final distA = (a.stringIndex - lastStringIndex).abs();
          final distB = (b.stringIndex - lastStringIndex).abs();
          return distA.compareTo(distB);
        }

        // Otherwise prefer lower strings
        return a.stringIndex.compareTo(b.stringIndex);
      });

      // Select the best option
      if (options.isNotEmpty) {
        final selected = options.first;
        selectedTones.add(selected);
        lastStringIndex = selected.stringIndex;
      }
    }

    return selectedTones;
  }

  /// Analyze chord fingering difficulty
  static Map<String, dynamic> analyzeFingeringDifficulty(
      List<ChordTone> fingering) {
    if (fingering.isEmpty) {
      return {
        'playable': false,
        'difficulty': 'impossible',
        'reason': 'No valid fingering found',
      };
    }

    // Calculate spans
    final strings = fingering.map((t) => t.stringIndex).toSet();
    final frets = fingering
        .where((t) => t.fretNumber > 0)
        .map((t) => t.fretNumber)
        .toSet();

    final stringSpan = strings.isEmpty
        ? 0
        : (strings.reduce(math.max) - strings.reduce(math.min) + 1);
    final fretSpan = frets.isEmpty
        ? 0
        : (frets.reduce(math.max) - frets.reduce(math.min) + 1);

    // Determine difficulty
    String difficulty;
    String? reason;

    if (stringSpan <= 3 && fretSpan <= 3) {
      difficulty = 'easy';
    } else if (stringSpan <= 4 && fretSpan <= 4) {
      difficulty = 'medium';
      if (fretSpan > 3) reason = 'Requires moderate finger stretch';
    } else if (stringSpan <= 5 && fretSpan <= 5) {
      difficulty = 'hard';
      reason = 'Requires significant finger stretch';
    } else {
      difficulty = 'very_hard';
      reason = 'May not be physically playable';
    }

    return {
      'playable': difficulty != 'very_hard',
      'difficulty': difficulty,
      'reason': reason,
      'stringSpan': stringSpan,
      'fretSpan': fretSpan,
      'strings': strings.toList()..sort(),
      'frets': frets.toList()..sort(),
    };
  }

  /// Get chord voicing as tablature notation
  static List<String> getVoicingTablature(
      List<ChordTone> fingering, int stringCount) {
    // Initialize with 'x' for muted strings
    final tab = List.filled(stringCount, 'x');

    for (final tone in fingering) {
      tab[tone.stringIndex] = tone.fretNumber.toString();
    }

    return tab;
  }

  /// Generate chord diagram data
  static Map<String, dynamic> generateChordDiagram(
      List<ChordTone> fingering, int stringCount) {
    final tab = getVoicingTablature(fingering, stringCount);
    final frettedNotes = fingering.where((t) => t.fretNumber > 0).toList();

    // Find the lowest fret to determine diagram position
    final lowestFret = frettedNotes.isEmpty
        ? 0
        : frettedNotes.map((t) => t.fretNumber).reduce(math.min);
    final highestFret = frettedNotes.isEmpty
        ? 0
        : frettedNotes.map((t) => t.fretNumber).reduce(math.max);

    // Determine if we need to show a position marker
    final showPositionMarker = lowestFret > 3;
    final diagramStartFret = showPositionMarker ? lowestFret : 1;

    return {
      'tablature': tab,
      'startFret': diagramStartFret,
      'showPositionMarker': showPositionMarker,
      'fretSpan': highestFret - lowestFret,
      'mutedStrings': tab
          .asMap()
          .entries
          .where((e) => e.value == 'x')
          .map((e) => e.key)
          .toList(),
      'openStrings': tab
          .asMap()
          .entries
          .where((e) => e.value == '0')
          .map((e) => e.key)
          .toList(),
    };
  }

  /// Check if a chord voicing is complete
  static bool isVoicingComplete(List<ChordTone> voicing, String chordType) {
    final chord = Chord.get(chordType);
    if (chord == null) return false;

    final presentToneIndices = voicing.map((t) => t.chordToneIndex).toSet();

    // Check if all chord tones are represented
    for (int i = 0; i < chord.intervals.length; i++) {
      if (!presentToneIndices.contains(i)) {
        return false;
      }
    }

    return true;
  }

  /// Get missing chord tones from a voicing
  static List<String> getMissingChordTones(
      List<ChordTone> voicing, String root, String chordType) {
    final chord = Chord.get(chordType);
    if (chord == null) return [];

    final presentToneIndices = voicing.map((t) => t.chordToneIndex).toSet();
    final missing = <String>[];
    final rootNote = Note.fromString('${root}3');

    for (int i = 0; i < chord.intervals.length; i++) {
      if (!presentToneIndices.contains(i)) {
        final interval = chord.intervals[i];
        final missingNote = rootNote.transpose(interval);
        missing.add(missingNote.name);
      }
    }

    return missing;
  }
}
