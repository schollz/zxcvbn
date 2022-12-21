---
title: Grid
weight: 3.0
---

The [monome grid]() holds sequences of notes that are synchronized, but separate, from all the tracks. 

There are four zones:

1. The bottomost left button (a single button) toggles playing.
2. The left toggles time and polyphony.
3. The bottom toggles the measure. 
4. The rest of the keys toggle notes to play.

There are six actions:

- Change the pulses in a measure by clicking on the left side (rows 1-7). Each row has a different number of pulses. The top is faster and bottom is slower.
- Change between monophonic mode and polyphonic mode by holding down a button on the left side for at least 1 second. The selected pulses-per-measure button will blink in monophonic mode. This attribute is step-specific.
- Add/remove notes by pressing any note in the middle area. If in monophonic mode the notes are played in the order received.
- Play notes by pressing the bottomost-left button. This will play through all the notes in each of the activated measures.
- Activate a measure by hold on the specified bottom note for more than 1 second.
- Change to a different measure by quickly pressing any bottom note. 
- Clear all the notes from a measure by holding the bottomost leftmost button for one second. Clear everything by holding the same button for more than three seconds.

The sequences from the grid are synchronized with the zxcvbn tracks but they do not share mutes/plays. The grid sequences can only be started or stopped with the bottomost left grid button.


[grid station](https://tyleretters.github.io/GridStation/)

```
16 8 #bbbbbb #fcb400 #ffffff #000000 20 20 4 1 1
a 0 0 2 0 0 0 0 0 0 0 0 0 0 0 0
5 0 0 2 0 0 0 0 0 0 0 0 0 0 0 0
5 0 0 2 0 0 0 0 0 0 0 5 f 0 0 0
5 0 0 2 0 0 0 0 5 5 0 0 0 0 0 0
5 0 0 2 0 0 5 0 0 0 0 f 0 0 0 0
5 0 0 2 0 0 0 0 0 0 0 0 0 0 0 0
5 0 0 2 0 0 0 0 0 0 0 0 0 0 0 0
d 5 e e 5 e 5 5 5 5 5 5 5 5 5 5
```