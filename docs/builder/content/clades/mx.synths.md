---
title: mx.synths
weight: 4.0
---

<img src="/static/mx.synths.png" class="fr">

This clade includes 13 different internal synth engines to choose from. Basically, all the synths that you can find in the  [*mx.synths*](https://github.com/schollz/mx.synths) script are included here. Once you select the `mx.synths` clade, you have an option to select with synth engine. Engine engine its own set of internal parameters that are modulated using the `mod[1-4]` parameters.

Note: If you only need monophony (one note, like for a bass or arpeggio), there is a parameter `PARAMS > mono release` which you can set to non-zero to make sure that each new note releases the last note with the specified release. This will save a lot of CPU if you have many notes playing fast.