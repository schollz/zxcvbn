---
title: CPU usage 
---

Audio dropouts will occur if the CPU usage gets to high. Onboard synths like [mx.synths](#mx-synths), [infinite pad](#infinite-pad)) can incur a lot of CPU usage, especially when used with long release times and with lots of polyphony. 


In *zxcvbn* there are no hard limits on CPU usage, polyphony, or maximum number of simultaneous tracks. Therefore, if you experience audio dropouts the best solution is usually to reduce the release time to decrease overlaps between notes, reduce polyphony of notes, try to off-board instruments with midi or cv, or (last resort) use [multiple norns devices synced together](#syncing-multiple-norns).

If you are using the [mx.synths](#mx-synths) clade, then there is an option to set `mono release` to a nonzero value, which will enable monophonic playback and overlap will not exceed that value. This will often help with CPU usage when using arpeggios or if a long release time is set.