# zxcvbn

too little information.

tracker of limited input.

## todo

- [ ] cache parsers for notes and chain
- [ ] allow chains to playthrough only once
- [ ] Mute groups with alt+#
- [ ] TEST retrig/volume w/ crow
- [ ] TEST retrig/volume w/ midi
- [ ] TEST retrig/volume w/ melodic
- [ ] random parameter choices with '?' (e.g. m?)
- [ ] padfx as a global reverb send?
- [x] slice should send duration_total as well as duration_slice (duration_slice is switched by type and not affected by retrig rate) (need to test)
- [x] in chaining, support "*" to multiply patterns?
- [x] delete key should move previous line to current line
- [x] ppl addressed in the meta
- [x] ~~hookup the break effects in the engine~~ break effects are less interesting
- [x] ~~add play visual on the left bar~~
- [x] ~~retrigger should start at 1, not 0~~ nvm
- [x] ~~scroll shows hex for sample type =1?~~ 
- [ ] ~~show type on the left bar~~ nvm
- [x] TEST Ctrl N makes new (can be undoed)
- [x] TEST copy / paste
- [x] TEST undo / redo
- [x] yedilik drum load (place slices)
- [x] if nothing is playing then reset clock when playing starts
- [x] why is source bpm off


## tli syntax

some parameters latch until they change again.

some parameters are not available for all instruments.

- [ ] h100 (hold length / gate, %)
- [ ] i99 (filter open = midi note - 30)
- [ ] j11 (just for fun (fx))
- [x] k10 (attack, ms)
- [x] l2000 (decay, ms)
- [x] m99 (deci-mater)
- [x] n?? (note change,-12-12)
- [x] o100 (er offset)
- [ ] p99 (pan, 0=left, 100 = right)
- [x] q100  (probability, %)
- [x] r8 (arp type)
- [x] s100 (arp skip)
- [x] t1 (arp time (in steps))
- [ ] u??
- [x] v99 (volume add, db	)
- [ ] w11 (stretch)()
- [x] x8 (retrig 8 times) (v-1 makes a delay type thing)
- [ ] y1 
- [ ] z6  reverb send



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
