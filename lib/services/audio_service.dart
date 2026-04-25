import 'dart:math';

import 'package:flutter_midi_pro/flutter_midi_pro.dart';

class AudioService {
  static const int _channel = 0;

  final MidiPro _midiPro = MidiPro();
  int _sfId = 0;
  bool _isInitialized = false;
  double _tuningCents = 0;

  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    _sfId = await _midiPro.loadSoundfontAsset(
      assetPath: 'assets/soundfonts/TimGM6mb.sf2',
      bank: 0,
      program: 0,
    );
    _isInitialized = true;
    // CC 7 — channel volume. GM default is 100; push to max to compensate for
    // the lower velocity so notes are louder without sounding harder.
    _midiPro.controlChange(
        sfId: _sfId, channel: _channel, controller: 7, value: 127);
    if (_tuningCents != 0) _applyTuning();
  }

  /// Sets the reference pitch for A4. Standard is 440 Hz; pass 432 for A=432 Hz.
  void setReferenceHz(double hz) {
    _tuningCents = 1200 * (log(hz / 440) / ln2);
    if (_isInitialized) _applyTuning();
  }

  void _applyTuning() {
    _midiPro.setGlobalTuning(sfId: _sfId, cents: _tuningCents);
  }

  void playNote(int midiNote, {int velocity = 95}) {
    if (!_isInitialized) return;
    _midiPro.playNote(sfId: _sfId, channel: _channel, key: midiNote, velocity: velocity);
  }

  void stopNote(int midiNote) {
    if (!_isInitialized) return;
    _midiPro.stopNote(sfId: _sfId, channel: _channel, key: midiNote);
  }

  void dispose() {
    _midiPro.dispose();
  }
}
