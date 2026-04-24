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

  static const int _noteCount = 15;
  static const int _firstNoteIndex = 0;
  static const int _firstOctave = 3;

  final AudioService _audioService = AudioService();
  final Map<int, _TapState> _taps = {};
  bool _isLoading = true;
  bool _is432 = false;
  double _zoom = 1.0;
  double _scrollOffset = 0.5;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      await _audioService.initialize();
    } catch (e, st) {
      debugPrint('AudioService.initialize failed: $e\n$st');
    }
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
          builder: (context, constraints) {
            return Row(
            children: [
              RotatedBox(
                quarterTurns: 3,
                child: SizedBox(
                  width: constraints.maxHeight,
                  height: kToolbarHeight,
                  child: AppBar(
                    primary: false,
                    titleSpacing: 0,
                    title: Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 1,
                            child: Slider(
                              value: _zoom,
                              min: 1.0,
                              max: 3.0,
                              onChanged: (v) => setState(() => _zoom = v),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 3,
                            child: SizedBox(
                              height: kToolbarHeight - 16,
                              child: _MiniPianoScrollbar(
                                whiteKeyCount: _noteCount,
                                firstNoteIndex: _firstNoteIndex,
                                zoom: _zoom,
                                scrollOffset: _scrollOffset,
                                onScrollChanged: (v) =>
                                    setState(() => _scrollOffset = v),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                      ),
                    ),
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
                  builder: (context, pianoConstraints) {
                    final availH = pianoConstraints.maxHeight;
                    final scrollPixels =
                        (1 - _scrollOffset.clamp(0.0, 1.0)) *
                            availH *
                            (_zoom - 1);
                    return ClipRect(
                      child: OverflowBox(
                        minWidth: 0,
                        maxWidth: pianoConstraints.maxWidth,
                        minHeight: 0,
                        maxHeight: availH * _zoom,
                        alignment: Alignment.topCenter,
                        child: Transform.translate(
                          offset: Offset(0, -scrollPixels),
                          child: RotatedBox(
                            quarterTurns: 3,
                            child: PianoPro(
                              noteCount: _noteCount,
                              firstNoteIndex: _firstNoteIndex,
                              firstOctave: _firstOctave,
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
                    );
                  },
                ),
              ),
            ],
          );
          },
        ),
      ),
    );
  }
}

class _MiniPianoScrollbar extends StatelessWidget {
  const _MiniPianoScrollbar({
    required this.whiteKeyCount,
    required this.firstNoteIndex,
    required this.zoom,
    required this.scrollOffset,
    required this.onScrollChanged,
  });

  final int whiteKeyCount;
  final int firstNoteIndex;
  final double zoom;
  final double scrollOffset;
  final ValueChanged<double> onScrollChanged;

  double _widthFromContext(BuildContext context) {
    final box = context.findRenderObject();
    if (box is RenderBox && box.hasSize) return box.size.width;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanUpdate: (details) {
        if (zoom <= 1) return;
        final width = _widthFromContext(context);
        if (width <= 0) return;
        // Window travels `width * (1 - 1/zoom)` px for a full scrollOffset 0→1.
        // Dividing finger delta by that range makes the highlight track 1:1.
        final travel = width * (1 - 1 / zoom);
        if (travel <= 0) return;
        final newOffset =
            (scrollOffset + details.delta.dx / travel).clamp(0.0, 1.0);
        onScrollChanged(newOffset);
      },
      onTapDown: (details) {
        if (zoom <= 1) return;
        final width = _widthFromContext(context);
        if (width <= 0) return;
        final visibleFraction = 1 / zoom;
        final center = details.localPosition.dx / width;
        final newOffset = ((center - visibleFraction / 2) /
                (1 - visibleFraction))
            .clamp(0.0, 1.0);
        onScrollChanged(newOffset);
      },
      child: CustomPaint(
        painter: _MiniPianoPainter(
          whiteKeyCount: whiteKeyCount,
          firstNoteIndex: firstNoteIndex,
          zoom: zoom,
          scrollOffset: scrollOffset,
          borderColor: Theme.of(context).colorScheme.primary,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _MiniPianoPainter extends CustomPainter {
  _MiniPianoPainter({
    required this.whiteKeyCount,
    required this.firstNoteIndex,
    required this.zoom,
    required this.scrollOffset,
    required this.borderColor,
  });

  final int whiteKeyCount;
  final int firstNoteIndex;
  final double zoom;
  final double scrollOffset;
  final Color borderColor;

  static const List<int> _noFlatIndexes = [0, 3]; // C, F

  static const Color _dimWhite = Color(0xFF8F8F8F);
  static const Color _brightWhite = Color(0xFFFAF6EC);
  static const Color _dimBlack = Color(0xFF3A3A3A);
  static const Color _brightBlack = Color(0xFF000000);

  @override
  void paint(Canvas canvas, Size size) {
    final whiteKeyW = size.width / whiteKeyCount;
    final blackKeyW = whiteKeyW * 0.6;
    final blackKeyH = size.height * 0.6;

    final visibleFraction = (1.0 / zoom).clamp(0.0, 1.0);
    final visibleStart =
        scrollOffset.clamp(0.0, 1.0) * (1 - visibleFraction) * size.width;
    final visibleEnd = visibleStart + visibleFraction * size.width;

    final dimWhitePaint = Paint()..color = _dimWhite;
    final brightWhitePaint = Paint()..color = _brightWhite;
    final dimBlackPaint = Paint()..color = _dimBlack;
    final brightBlackPaint = Paint()..color = _brightBlack;

    void paintKeys(Paint whitePaint, Paint blackPaint) {
      for (int i = 0; i < whiteKeyCount; i++) {
        final x = i * whiteKeyW;
        canvas.drawRect(
          Rect.fromLTWH(x + 0.5, 0, whiteKeyW - 1, size.height),
          whitePaint,
        );
      }
      for (int i = 0; i < whiteKeyCount - 1; i++) {
        final nextNoteIndex = (i + 1 + firstNoteIndex) % 7;
        if (_noFlatIndexes.contains(nextNoteIndex)) continue;
        final x = (i + 1) * whiteKeyW - blackKeyW / 2;
        canvas.drawRect(
          Rect.fromLTWH(x, 0, blackKeyW, blackKeyH),
          blackPaint,
        );
      }
    }

    // Dim everything.
    paintKeys(dimWhitePaint, dimBlackPaint);

    // Overpaint the visible range in bright colors, clipped to the window so
    // partial keys split cleanly at the border.
    canvas.save();
    canvas.clipRect(
      Rect.fromLTWH(visibleStart, 0, visibleEnd - visibleStart, size.height),
    );
    paintKeys(brightWhitePaint, brightBlackPaint);
    canvas.restore();

    // Highlight border around the visible range.
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRect(
      Rect.fromLTWH(
        visibleStart + 1,
        1,
        (visibleEnd - visibleStart) - 2,
        size.height - 2,
      ),
      borderPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _MiniPianoPainter old) {
    return old.whiteKeyCount != whiteKeyCount ||
        old.firstNoteIndex != firstNoteIndex ||
        old.zoom != zoom ||
        old.scrollOffset != scrollOffset ||
        old.borderColor != borderColor;
  }
}
