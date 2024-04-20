---
title: Arp steps
weight: 7.2
range: 1 to inf
command: mod
shortcode: s
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
    - zassersby
    - oilcan
---

Steps defines the maximum number of steps in a given arpeggio. For every step that is not in the original chord, the note is increased by one octave. If [time](#time) is not defined, then the pulses per step will be equally divided among the available number of pulses. 

## Example 1

In this example the arpeggio goes up to `c4`, `e4`, `g4`, `c5` because there are four steps.

<p class="shiny">C;4 ru s4</p>

## Example 2

In this example with [hex](#hex) syntax, the arpeggio goes up and down: `0`, `1`, `12`, `13`, `12`, `2`, `1`, `2`. This is because only four steps are defined but each is given 12 pulses out of 96, for 8 total.

<p class="shiny">01 rud s4 t12</p>

