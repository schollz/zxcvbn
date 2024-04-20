---
title: Gate
weight: 15.0
shortcode: h
range: 0 to 100
clades:
    - drum
    - melodic
    - mx.samples
    - mx.synths
    - infinite pad
    - midi
    - crow
    - oilcan
    - zassersby
---

The gate determine how long a note is held. Each note is given a time according to how it is parsed by [tli](#tli), but the time allotted can be further truncated using the gate and defining a value less than 100.

For [zassersby](#zassersby) this will only be applicable for sustain mode, not lpg mode.

## Example 1

In this example, `c4` plays for a quarter note, while `d4` plays for a half note.

<p class="shiny">c4 h50 d4</p>
