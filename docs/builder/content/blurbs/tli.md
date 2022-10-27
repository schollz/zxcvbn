---
title: TLI
weight: 2.0
---

TLI means "**text-limited interface**". It is the basis of *zxcvbn*, as the primary control of this script is through a text editor that receives input from a keyboard. This script is used by entering commands, or collections of commands (called a "[pattern](#pattern)"), or collections of patterns (called a "[chain](#chain)"). The commands are often notes, but they can also be modifiers that augment the way that a note is played.

TLI also means "**too little information**". It is a style of syntax developed for producing oblique rhythms without music theory. TLI at its core is a single line of letters or numbers separated by spaces. The tracker allocates time to each line, and subdivides the time equally among each entity on the line.

Its best learned through examples.

<h2 class="h2under">Example 1 (quarter notes)</h2>
<p class="shiny">c4 d4 e4 g4</p>

In this example there are four notes so each is given 1/4 of the time allotted to the line. If the line is given one measure, then each note will be a quarter note.


<h2 class="h2under">Example 2 (triplets)</h2>
<p class="shiny">c4 d4 e4 c4 d4 e4 c4 d4 e4 c4 d4 e4</p>

In this example there are twelve notes so each is given 1/12 of the time allocated to the line. If the line is given one measure, then this will sound as four triplets.


<h2 class="h2under">Example 3 (rests)</h2>

Rests are important, as they also are an entity given time. If you want a rest between notes you put a *.*. In the example here there are quarter notes played on the first and the fourth beat.

<p class="shiny">c4 . . g4</p>


If instead you want the two notes to be eighth notes, you have to add in more rests to make the line have eight entities.

<p class="shiny">c4 . . . . . . . . g4</p>

Now the two notes play on the first and last eighth note of the series.



<h2 class="h2under">Example 4 (ties)</h2>

Ties are equally important as rests. If you use a tie, you can length the preceding note. So in Example 3, if we want a half note, followed by a rest and then a quarter-note you can use a tie signified by *-*. For example:

<p class="shiny">c4 - . g4</p>

Ties are special too, because they can continue onto the next line. If you want to play out a note for two measures, then you can simply use two lines to express it:


<pre class="shiny">c4
 -
</pre>



<h2 class="h2under">Allocating time in pulses</h2>

In *zxcvbn*, time is discrete and allocated in **pulses**. The number of pulses per quarter-note is immutable - it is defined as **24 pulses per quarter note** (24 ppqn).

Everything in *zxcvbn* is defined by pulses. The TLI syntax lets you split time, but the amount of time to split is given by the definition of the number of pulses per line. This is under your control.

You can define the number of pulses anywhere. If you want each line to be "one measure", with 4 quarter notes per measure, then you can define the number of pulses to be 96 (24 * 4) using the [pulse](#pulse) ([*p*](#pulse)) command:

<p class="shiny">p96</p>

You can also change the number of pulses **per line**. So if you want the number of pulses to change from 4 beats per line to 3 beats per line, you can do that:

<pre class="shiny">c4 d4 e4 f4 p96
 c4 d4 e4 p72
</pre>

The "shortcodes" like the [pulse](#pulse) command ([*p*](#pulse)) are ignored for the purposes of counting subdivisions - only notes are counted. So in this case the first line has four notes with 96 pulses and the second line has three notes with 72 pulses, so this essentially is a 7/4 time signature.

There is nothing stopping you from defining prime numbers of pulses to get oblique rhythms.


<h2 class="h2under">Imperfections in division</h2>

Since the number of pulses is discrete, there can be times where the number of pulses will not evenly divide between notes. In these cases, an euclidean system is used to allocate the notes across the pulses. 

For example, if you define only 8 pulses, but have 3 notes, 
then the pulses will not evenly divide.

<p class="shiny">c4 d4 e4 p8</p>

In this case, an euclidean generator is used to allocate three items across eight slots. The result would look like this in TLI syntax:

<p class="shiny">c4 . . d4 . . e4 . p8</p>

There is a special [offset](#offset) command ([*o*](#offset)) which can be used to offset the result. So if you include *o1* you can offset by 1. For example, this line:

<p class="shiny">c4 d4 e4 p8 o1</p>


Would convert into this:

<p class="shiny">. c4 . . d4 . . e4  p8</p>



<h2 class="h2under">Traditional-music pulses</h2>

In traditional music we mostly define note lengths as power-of-2 fractions of a measure - with a measure being four notes. There is shorthand for this in the pulse syntax. You can write `m`, `h`, `q`, `s`, `e` for measures, half-notes, quarter-notes, sixteenth-notes respectively. The measure is defined as 96 pulses and everything is a division from that.

You can also use mathematical expressions with pulses. So if you want a line to be one quarter-note less than two measures you can write:

<p class="shiny">c4 d4 e4 f4 p2*m-q</p>

The `p2*m-q` is evaluated as `2*96-24` which is `168` pulses. Its important not to put any spaces when using this syntax.