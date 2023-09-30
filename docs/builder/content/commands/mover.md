---
title: Mover
weight: 7.0
range: <mod><per>[,<min>][,<max>]
command: mod
shortcode: m
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

Mover is a special command that enacts a LFO on almost any of the other commands. Its syntax is different than all the other commands. It requires specifying the one-letter character of the command that is to be modified and a period (in beats). Then, optionallyl, a minimum and maximum can be specified.

The mover LFO is only implemented until the command that is being modified is coded in another cell.
LFO shape can also be changed to 'sine', 'triangle', 'saw', 'square' or 'random' at the bottom of the settings page.

## Example 1

In this example the volume of the "c4" note is oscillating the volume ([v](#volume)) between -10 and 0 dB at 10 beats/cycle for the first measure and set to -5 db for the second measure.

<pre class="shiny">
c4 mv10,-10,0
c4 v-5
</pre>

Note that the minimum and the maximum pertain to that particular command (in this example it is the volume).
