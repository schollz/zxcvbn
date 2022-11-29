---
title: Clades
weight: 3.0
---

"Clades" are the sound engines for *zxcvbn*.

There are eleven different kinds of clades - each with its own sound characteristics and eccentricities. 

The first three clades are synth engines:

1. [mx.synths](#mx-synths) is an engine that lets you manipulate over a dozen hand-crafted SuperCollider patches, each with four available mods and individual filter.
2. [DX7](#dx7) is an engine based on the Yamaha DX7 which lets you choose between over 15,000 patches.
3. [infinite pad](#infinite-pad) is a engine based around a pad-like sound with a swell parameter and filter.

THe next four clades are sample-based engines:

4. [mx-samples](#mx-samples) is a sample-based engine that can load and interpolate between many layers of samples.
5. [melodic](#melodic) is a sample-based engine that you can load any single sample and play it across the musical keyboard.
6.  [drum](#drum) is an engine for splicing samples and playback of small intervals.
7. [softcut](#softcut) is a sample-based engine that is similar to the [drum](#drum) engine but lets you sample live input in real-time.

The last four clades are engines mainly sequence external gear:

8. [crow](#crow) sequences two channels (pitch+envelope for each)
9. [midi](#midi) sequences any attached midi device
10. [w/syn](#wsyn) controls w/ over i2c
11. [just friends](#just-friends) controls just friends over i2c.