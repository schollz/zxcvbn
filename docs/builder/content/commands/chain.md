---
title: Chain
weight: 0.5
command: core
shortcode: chain
---

Patterns can be chained together using this command. This command must precede all patterns.

You can use `(` or `*` operators to indicate groupings or multiplicative operations on the pattern chain.

## Example 1

In this simple example, the patterns loop between `a`, `b`, and `c`. Each of the patterns only plays a single note, but each pattern can hold as many notes as needed.

<pre class="shiny">chain a b c

pattern a
c4

pattern b
d4

pattern c 
e4
</pre>

## Example 2

In this example, the patterns loop between `a`,`a`, `b` - which is repeated twice, followed by `c`. Instead of writing `a a b a a b c` it can be compressed using the mathematical operators.

<pre class="shiny">
chain (a*2 b)*2 c

pattern a
c4

pattern b
d4

pattern c 
e4
</pre>
