# zxcvbn

branch working well: https://github.com/schollz/zxcvbn/commit/c65c1fad06f9509b79ac1808113394c562a023a6

too little information.

tracker of limited input.

## todo

- [ ] hookup the break effects in the engine
- [ ] add play visual on the left bar
- [ ] show type on the left bar

## tli syntax

all parameters latch until they change again

```
h100 (hold length / gate, %)
i99 (filter open = midi note - 30)
j11 (just for fun (fx))
k10 (attack, ms)
l2000 (decay, ms)
m99 (deci-mater)
n??
o100 (probability, %)
p99 (pan, 0=left, 100 = right)
q?? 
r8 (retrig 8 times)
s100 (compress %)
t100 (compressibility)
u100 (compressing)
v99 (velocity, 0-127)
w99 (stretch, %%)
xud (arp type)
y1  (arp skip)
z6  (arp length)

```

```

file amenbreak_bpm136.wav
bpm 136 
oneshot -> indicates to not play beyond positions when triggering
-> means it will break it into 16 pieces based on onsets to be used

file piano_c_long.wav
note c4 
oneshot -> oneshot indicates to not use the sample-in/sample-out, and only play through to the end (useful for kick)
-> searches for the first file named "piano_c_long.wav" and uses that 

midi op-1
ch 1
-> means it will send to midi device "op-1"

crow 1
-> means it will send to crow 1+2

chain a b a a b
ppq 4 -> pulses per quarter note (creates division of 1/(4*ppq))

pattern a
0
1
2
3 3 3 3 

pattern b 
ppl 16 -> creates '16' spaces per line, (with ppq or 4, this means one line per measure, default)

0 0 0 0 m50 (retrigger, decimated)
0123 iu (create arpeggio of 0,1,2,3)
-
-
-
```



```
Cm7/Eb;4 
```
