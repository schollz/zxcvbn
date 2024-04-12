---
title: oilcan
weight: 4.0
---

<img src="/static/passersby.png" class="fr">

This clade is an integration of zjb-s's awesome [Oilcan Percussion Co.](https://github.com/zjb-s/oilcan/tree/main) drum synth! The only thing that is different from the original is that the Macro controls are not included(except Release) and there is an additional [Decimate] parameter for it with its relevant shortcode.


It has 7 timbres which are really 7 different drum sounds that you can configure and trigger.
This clade **uses [hex](#hex) syntax** which defines the position of the slice (`0-f`). Since the clade has 7 sounds the range of (`0-f`) hex numbers are mapped to (`0-6`) in a loop. 


You can also load oilcan kits which are presets that you can save and move between devices, or import old ones you made using the original mod. 

## example

This triggers Timbres 1 through 7
<p class="shiny">0 1 2 3 4 5 6</p>

This also triggers Timbres 1 through 7
<p class="shiny">7 8 9 a b c d</p>

This triggers Timbres 1 and 2
<p class="shiny">e f</p>

Note: If you only need monophony (one note, like for a bass or arpeggio), there is a parameter `PARAMS > mono release` which you can set to non-zero to make sure that each new note releases the last note with the specified release. This will save a lot of CPU if you have many notes playing fast.
