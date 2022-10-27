---
title: mx.samples
weight: 3.0
---

<img src="/static/mx.samples.png" class="fr">

To use this clade you should first install the norns script [*mx.samples*](https://github.com/schollz/mx.samples). Using that script you can individually install instruments. Each of the instruments will install into the `dust/audio/mx.samples` directory. Each instrument installs a selection of `.wav` files in varying pitches and volumes that can then be interpolated by the mx.samples engine.


<img src="/static/mx_select.png" class="fr">

Back in *zxcvbn*, you will be able to select those instruments in the `PARAMS > select instrument`. The engine will automatically utilize the samples for each instrument and interpolate between volumes and use round-robin samples (if available).