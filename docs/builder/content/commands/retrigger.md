---
title: Retrigger
weight: 7.0
range: 1 to 32
command: mod
shortcode: "x"
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

This command will further subdivide the current note as many times as it is retriggered. For example if you retrigger a quarter note twice it will play as two eighth notes.

Retrigger works in conjunction with [volume](#volume) and [pitch](#pitch) in a special way - upon each retrigger it applies the change to volume or pitch again. This way you can create escalating or descalating patterns, or even pseudo-echos.

## Example 1

In this example the note plays `c4` as four sixteenth notes instead of a quarter note.

<p class="shiny">c4 x4 d4 e4 f5</p>

## Example 2

In this example the hex plays the first slice and it echoes 15 times, decreasing in volume each time by 1 dB and increasing one semitone each trigger.

<p class="shiny">0 x16 v-1 n1</p>
