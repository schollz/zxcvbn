---
title: Audio Out
---

<img src="/static/audioout.png" class="fr">

The `AUDIO OUT` contains several parameters that had extra features to the norns audio out. Namely - there is a EQ stage, a tape slow feature, and a compressor that is capable of sidechaining different routings or clades. There is only one sidechain channel. 

In the `AUDIO OUT` parameters there are options to adjust the sidechaining. The main parameter to change will be `sidechain amt` which is essentially the multiplying factor for the audio input. The higher the value, the more sidechaining. The rest of the values are standard compressor parameters.


<img src="/static/compressing.png" class="fr">

In the `PARAMS` menu of each clade, you can set an audio source to be the sidechaining source by setting `compressing` to `yes`. You can then set the source to be sidechained/compressed by setting `compressible` to `yes`. Any number of sources can be sidechaining/sidechained, but they all happen through a single bus.


