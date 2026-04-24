import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_piano_pro/flutter_piano_pro.dart';
import 'package:flutter_piano_pro/note_model.dart';

import '../services/audio_service.dart';

class _TapState {
  _TapState(this.playing);
  NoteModel playing;
  NoteModel? pending;
  Timer? timer;
}

class PianoScreen extends StatefulWidget {
  const PianoScreen({super.key});

  @override
  State<PianoScreen> createState() => _PianoScreenState();
}

class _PianoScreenState extends State<PianoScreen> {
  static const Duration _switchHysteresis = Duration(milliseconds: 15);
  static const Color _pressedWhiteColor = Color(0xFFC4BDA8);
  static const Color _pressedBlackColor = Color(0xFF5A5A5A);

  final AudioService _audioService = AudioService();
  final Map<int, _TapState> _taps = {};
  bool _isLoading = true;
  bool _is432 = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _audioService.initialize();
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    for (final tap in _taps.values) {
      tap.timer?.cancel();
    }
    _audioService.dispose();
    super.dispose();
  }

  void _onTapDown(NoteModel? note, int tapId) {
    if (note == null) return;
    _taps[tapId]?.timer?.cancel();
    _audioService.playNote(note.midiNoteNumber);
    setState(() {
      _taps[tapId] = _TapState(note);
    });
  }

  void _onTapUpdate(NoteModel? note, int tapId) {
    if (note == null) return;
    final tap = _taps[tapId];
    if (tap == null) return;
    if (note == tap.playing) {
      // Finger is back on the already-sounding note — abort any pending switch.
      tap.timer?.cancel();
      tap.timer = null;
      tap.pending = null;
      return;
    }
    if (note == tap.pending) return; // Same candidate still waiting.
    tap.timer?.cancel();
    tap.pending = note;
    tap.timer = Timer(_switchHysteresis, () {
      _audioService.stopNote(tap.playing.midiNoteNumber);
      _audioService.playNote(note.midiNoteNumber);
      if (!mounted) {
        tap.playing = note;
        tap.pending = null;
        tap.timer = null;
        return;
      }
      setState(() {
        tap.playing = note;
        tap.pending = null;
        tap.timer = null;
      });
    });
  }

  void _onTapUp(int tapId) {
    final tap = _taps.remove(tapId);
    if (tap == null) return;
    tap.timer?.cancel();
    _audioService.stopNote(tap.playing.midiNoteNumber);
    if (mounted) setState(() {});
  }

  Map<int, Color> _buildPressedColors() {
    final result = <int, Color>{};
    for (final tap in _taps.values) {
      final note = tap.playing;
      result[note.midiNoteNumber] =
          note.isFlat ? _pressedBlackColor : _pressedWhiteColor;
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => Row(
            children: [
              RotatedBox(
                quarterTurns: 3,
                child: SizedBox(
                  width: constraints.maxHeight,
                  height: kToolbarHeight,
                  child: AppBar(
                    primary: false,
                    actions: [
                      Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: Row(
                          children: [
                            Text(_is432 ? '432 Hz' : '440 Hz'),
                            Switch(
                              value: _is432,
                              onChanged: (v) {
                                setState(() => _is432 = v);
                                _audioService.setReferenceHz(v ? 432 : 440);
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, pianoConstraints) => RotatedBox(
                    quarterTurns: 3,
                    child: PianoPro(
                      noteCount: 15,
                      firstNoteIndex: 0,
                      firstOctave: 3,
                      whiteHeight: pianoConstraints.maxWidth,
                      blackHeightRatio: 1.55,
                      blackWidthRatio: 1.4,
                      showNames: true,
                      showOctave: true,
                      buttonColors: _buildPressedColors(),
                      onTapDown: _onTapDown,
                      onTapUpdate: _onTapUpdate,
                      onTapUp: _onTapUp,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
