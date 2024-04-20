---
title: Pulse
weight: 12.0
shortcode: p
clades:
    - drum
    - melodic
    - mx.samples
    - mx.synths
    - infinite pad
    - softcut
    - crow
    - midi
    - zassersby
    - oilcan
---

Pulse is used to redefine the number of pulses allocated to a given line. There is an immutable number of 24 pulses per quarter note, but you can define any number of pulses per line. If no pulses are defined then it will be defined as 96 pulses per line by default (4 quarter notes per line). You can use mathematical expressions with pulses, as long as there are no spaces.

## Example 1

In this example, the first line will have 24 pulses (1 whole quarter note), while the second line will have 96 pulses (4 whole quarter notes).

<pre class="shiny">c4 p24
c4 p24*2+48</pre>

When played together, this whole pattern is 96 pulses, or five beats.

## Traditional note lengths

In traditional music note lengths are usually defined as power-of-2 fractions of a measure - with a measure being four notes. There is shorthand for this in the pulse syntax. You can write `m`, `h`, `q`, `s`, `e` for measures, half-notes, quarter-notes, sixteenth-notes respectively. The measure is defined as 96 pulses and everything is a division from that.

You can also use mathematical expressions with pulses. So if you want a line to be one quarter-note less than two measures you can write:

<p class="shiny">c4 d4 e4 f4 p2*m-q</p>

The `p2*m-q` is evaluated as `2*96-24` which is `168` pulses. Its important not to put any spaces when using this syntax.