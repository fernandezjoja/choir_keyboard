import 'package:flutter/material.dart';
import 'package:flutter_piano_pro/note_model.dart';
import 'package:flutter_piano_pro/note_names.dart';

class PianoView extends StatelessWidget {
  const PianoView({
    super.key,
    required this.buttonColors,
    required this.noteType,
    required this.whiteButtonWidth,
    required this.whiteButtonHeight,
    required this.noFlatIndexes,
    required this.blackButtonWidth,
    required this.blackButtonHeight,
    required this.noteCount,
    required this.firstNote,
    required this.firstNoteOctave,
    required this.showOctaveNumber,
    required this.showNames,
  });
  final Map<int, Color>? buttonColors;
  final int noteCount;
  final int firstNote;
  final NoteType noteType;
  final double whiteButtonWidth;
  final double whiteButtonHeight;
  final List<int> noFlatIndexes;
  final double blackButtonWidth;
  final double blackButtonHeight;
  final int firstNoteOctave;
  final bool showOctaveNumber;
  final bool showNames;

  @override
  Widget build(BuildContext context) {
    var noteNames = noteType.notes;
    return Stack(
      children: [
        Row(children: [
          ...List.generate(
            noteCount,
            (i) {
              var index = i + firstNote;
              var octaveCounter = i == 0 ? 0 : (index / 7).floor();
              var currentNote = NoteModel(
                  name: noteNames[index % 7],
                  octave: firstNoteOctave + octaveCounter,
                  noteIndex: index % 7,
                  isFlat: false);
              const whiteDefault = Color(0xFFFAF6EC);
              final whiteColor =
                  buttonColors?[currentNote.midiNoteNumber] ?? whiteDefault;
              return TweenAnimationBuilder<Color?>(
                tween: ColorTween(begin: whiteDefault, end: whiteColor),
                duration: const Duration(milliseconds: 80),
                builder: (context, animatedColor, child) => Container(
                  margin:
                      EdgeInsets.symmetric(horizontal: whiteButtonWidth / 100),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 1, vertical: 8),
                  width: whiteButtonWidth - ((whiteButtonWidth / 100) * 2),
                  height: whiteButtonHeight,
                  decoration: BoxDecoration(
                      color: animatedColor ?? whiteColor,
                      borderRadius: BorderRadius.only(
                          bottomRight: Radius.circular(whiteButtonWidth / 7),
                          bottomLeft: Radius.circular(whiteButtonWidth / 7))),
                  child: child,
                ),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: showNames
                      ? Text(
                          showOctaveNumber
                              ? '${currentNote.name}${currentNote.octave}'
                              : currentNote.name,
                          softWrap: false,
                          overflow: TextOverflow.visible,
                          style: TextStyle(
                              color: const Color(0xFF6B6B6B),
                              fontWeight: FontWeight.w500,
                              fontSize: whiteButtonWidth / 3 > 45
                                  ? 45
                                  : whiteButtonWidth / 3),
                        )
                      : const SizedBox(),
                ),
              );
            },
          )
        ]),
        Row(
          children: [
            ...List.generate(
              noteCount,
              (i) {
                var index = i + firstNote;
                var octaveCounter = i == 0 ? 0 : (index / 7).floor();
                if (index % 7 == 0 && i != 0) ++octaveCounter;
                if (!noFlatIndexes.contains((index % 7)) && i != 0) {
                  var currentNote = NoteModel(
                    name:
                        "${noteNames[(index % 7) - 1]}♯\n${noteNames[(index % 7)]}♭",
                    octave: firstNoteOctave + octaveCounter,
                    noteIndex: index % 7,
                    isFlat: true,
                  );
                  const blackDefault = Colors.black;
                  final blackColor =
                      buttonColors?[currentNote.midiNoteNumber] ?? blackDefault;
                  return Row(
                    children: [
                      TweenAnimationBuilder<Color?>(
                        tween: ColorTween(
                            begin: blackDefault, end: blackColor),
                        duration: const Duration(milliseconds: 80),
                        builder: (context, animatedColor, child) => Container(
                          margin: EdgeInsets.symmetric(
                              horizontal: whiteButtonWidth / 100),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          width:
                              blackButtonWidth - (whiteButtonWidth / 100) * 2,
                          height: blackButtonHeight,
                          decoration: BoxDecoration(
                              color: animatedColor ?? blackColor,
                              borderRadius: BorderRadius.only(
                                  bottomLeft:
                                      Radius.circular(blackButtonWidth / 7),
                                  bottomRight:
                                      Radius.circular(blackButtonWidth / 7))),
                          child: child,
                        ),
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: showNames
                              ? Text(
                                  showOctaveNumber
                                      ? currentNote.name
                                          .split('\n')
                                          .map((l) => '$l${currentNote.octave}')
                                          .join('\n')
                                      : currentNote.name,
                                  textAlign: TextAlign.center,
                                  softWrap: false,
                                  overflow: TextOverflow.visible,
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: blackButtonWidth / 4 > 16
                                          ? 16
                                          : blackButtonWidth / 4),
                                )
                              : const SizedBox(),
                        ),
                      ),
                      !(i == noteCount - 1)
                          ? SizedBox(
                              width: whiteButtonWidth - (blackButtonWidth),
                            )
                          : const SizedBox(),
                    ],
                  );
                } else {
                  return i == 0
                      ? SizedBox(
                          width: whiteButtonWidth - (blackButtonWidth / 2),
                        )
                      : SizedBox(
                          width: whiteButtonWidth,
                        );
                }
              },
            )
          ],
        )
      ],
    );
  }
}
