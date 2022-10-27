---
title: Pattern
weight: 0.8
command: core
shortcode: qrcode
---

Patterns are useful to group musical expressions. They are most useful when combined with [chains](#chain). Essentially any pattern is created when you have `pattern <name>` where `<name>` can be anything you want.

## Example 1

In this example there is a pattern that plays chords and a pattern that arpeggios the chords. However, there is nothing linking the patterns so it will only play the first. To link the patterns you should use [chain](#chain).
<pre class="shiny">pattern foo
Cm7
Am7/E

pattern bar
c4 eb4 g4 c5
a4 c4 e4 a5
</pre>
