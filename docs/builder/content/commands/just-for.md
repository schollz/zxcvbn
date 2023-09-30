---
title: Just For
weight: 20.0
shortcode: j
range: varies
clades:
    - drum
    - softcut
    - infinite pad
    - mx.synths
---

This command is just for each individual clade - it works differently depending on which clade you are using.

For [softcut](#softcut) this command will activate recording, and the range is 0 to 100 (0% record level to 100% record level).

The [drum](#drum) this command will change the amount of decimation between 0 and 100%.

For [mx.synths](#mx-synths) this command will change the four mods. Each mod has a range of 100 (which is mapped to -1 to 1). So for mod1, the values are 0-100, for mod2 the values are 101-200, etc.

For [infinite pad](#infinite-pad) this command will change the swell. The range is 0 to 100%.

For [MIDI](#midi) this command will send a CC message to the relative MIDI device and channel. The range is 0 to 127.