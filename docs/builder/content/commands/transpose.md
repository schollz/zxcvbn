---
title: Transpose
weight: 7.2
range: -127 to 127
command: mod
shortcode: "y"
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

Scales can be modified in the `PARAMS > scale mode`. By default it will be a chromatic scale.

## Example 1

In this example, the C is followed by a C# if in the chromatic scale, or is followed by a D if it is in a major scale.

<p class="shiny">c4 c y1</p>


## Example 2

This example uses [ordered command values](#random-or-ordered-command-values) so the first time the note plays C, and then D (assuming a chromatic scale).

<p class="shiny">c4 y0.2 </p>
