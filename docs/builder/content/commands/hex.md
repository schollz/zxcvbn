---
title: Hex
weight: 2.0
command: core
shortcode: hashtag
clades:
    - drum
    - softcut
    - oilcan
---

Hex is used instead of [Note](#note) for clades that involve positions - namely [drum](#drum), [softcut](#softcut) and [oilcan](#oilcan). In [drum] and [softcute], there are up to 16 available positions. For [oilcan] there are only 7. The commands to playback at a certain position is simply a hex value, `0-9a-f` where `0` is position 1 and `f` is position 16.

The usage of Hex commands is similar to [Note](#note) in that you can use them with arps, you remove spaces in between to play things together, etc.

## Example 1

In this example, play position 1, 2, 3, 4 in order.

<p class="shiny">0 1 2 3</p>


## Example 2

In this example, position 1 and 16 are played together.

<p class="shiny">0f</p>

## Example 3

This is the same as Example 1. The commands do not have spaces in between them, but they do not play together and are instead modified by the [Arp](#arp-type) command which plays them up once.

<p class="shiny">0123 ru</p>

