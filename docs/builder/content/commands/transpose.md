---
title: Transpose
weight: 7.2
range: -127 to 127
command: mod
shortcode: y
inpattern: true
clades:
    - drum
    - melodic
    - mx.samples
    - mx.synths
    - infinite pad
    - softcut
    - crow
    - midi
---

Transpose will modify the note before it is latched to the current scale. This is useful for transposing keys and staying in the scale, but can also be used to create melodies when using random or ordered command values.

## Example 1

In this example the arpeggio goes up to `c4`, `e4`, `g4`, `c5`, with each note getting 12 pulses (1/8th note).

<p class="shiny">C;4 ru s4 t12</p>

## Example 2

In this example with [hex](#hex) syntax, the arpeggio goes up to `0`, `1`, `12`, `13`.

<p class="shiny">01 rud s4 t8</p>
