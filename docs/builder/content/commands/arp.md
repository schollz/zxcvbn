---
title: Arp type
weight: 7.1
range: various
command: mod
shortcode: r
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

Arpeggio lets you create arpeggios. You can use arpeggio with a collection of notes (or hex), or a chord. The arpeggio will last as long as defined by [tli](#tli). These are the available arpeggio options and their shortcodes:

- up (u)
- down (d)
- up-down (ud)
- down-up (du)
- convergent (co)
- divergent (di)
- convergent-divergent (codi)
- divergent-convergent (dico)
- pinky-up (pu)
- pinky-up-down (pud)
- thumb-up (tu)
- thumb-up-down (tud)
- random (r)

By default, the arp will equally divide the number of notes according to the defined number of pulses. This can be changed by utilizing this command along with [steps](#steps) to change the number of steps or [time](#time) to change the length of each note in the arpeggio.

## Example 1

This example does an up-down arpeggio on a Cm7 chord.

<p class="shiny">Cm7 rud</p>

## Example 2

This example plays a pinky-based arpeggio on the first four slices (in hex notation).

<p class="shiny">0123 rpu</p>
