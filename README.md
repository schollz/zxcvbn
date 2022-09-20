# zxcvbn

too little information.

tracker of limited input.

## todo

- [ ] test out live controls on the grid
- [ ] add start/stop other buttons on the grid
- [ ] tie the "option" parameters to the fm-stabs / glitches
- [x] e1 changes the kick amount for sample slice
- [ ] create text editor?
- [ ] add routing for the tli
- [x] do note clusterse work for tli? e4b5??
- [ ] hookup the break effects in the engine


## tli syntax


```
l99 (left side (pan))
m99 (decimate)
o99 (filter open)
p50 (amplitude, %)
q10 (attack, ms)
r2000 (release, ms)
s0.0 (compress, %)
t100 (gate, %)
h99 (stretch, %%)
iud (arp type)
k1  (arp skip)
n6  (arp length)
```

```
chain a b a a b

pattern=a
0
1
2
3 3 3 3 

pattern=b division=8

0 0 0 0 m50 (retrigger, decimated)
0123 iu (create arpeggio of 0,1,2,3)
-
-
-
```

```
Cm7/Eb;4 
```