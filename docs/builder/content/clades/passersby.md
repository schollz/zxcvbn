---
title: passersby
weight: 4.0
---

<img src="/static/passersby.png" class="fr">

This clade is a stripped down version of [Passersby](https://github.com/markwheeler/passersby). LFO features and waveshape selection was omitted for CPU usage reasons. Once you select the [passersby](#passersby) clade, you have an option to select LPG or sustain envelope. 

Note: If you only need monophony (one note, like for a bass or arpeggio), there is a parameter `PARAMS > mono release` which you can set to non-zero to make sure that each new note releases the last note with the specified release. This will save a lot of CPU if you have many notes playing fast.