---
title: Note
weight: 1.0
command: core
shortcode: music
clades:
    - mx.samples
    - mx.synths
    - melodic
    - infinite pad
    - midi
    - crow
---

Notes are written in two ways - either as individual notes, or specified via a chord name and color.

Individual notes are specified using lowercase scale letters (“a” through “g”), with an optional number to indicate the octave. If there is no space between notes then the notes will be played together.

Chords are specified by starting with an uppercase letter ("A" through "G") and then defining the chord flavor. The octave can be specified by including a `;<octave>` to the end of the command.

Notes are only applicable on clades that can be specified by musical notes (rather than positions). See [Hex](#hex) for specifying positions.

## Notes example

This will play three notes, individually.

<p class="shiny">c4 e4 g4</p>

The octave is optional, if it is omitted then it will use the octave closest to the last note. So the previous line is identical to this:

<p class="shiny">c4 e g</p>


## Chords example

This will play a C major chord.

<p class="shiny">C</p>


This will play a C major-seventh chord transposed over a E, on the 2nd octave.

<p class="shiny">Cmaj7/E;2</p>

You can also write chords using the notes (lowercase letters), by putting them in without spaces. So this is identical to the previous:

<p class="shiny">e2gbc</p>


