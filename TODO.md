# TODO

- [ ] softcut sync record head to playback head
- [ ] automatic patch of norns using `sed`
- [ ] TEST controlling two norns with one keyboard
- [ ] combine crow 1+2 and crow 3+4 in the track
- [ ] should work without pattern or chain declaration
- [ ] mute working
- [ ] rate changes (reversing??)
- [ ] get reverb send working
- [ ] add mx.synths and special shortcode to change the parameters j???
- [ ] TEST midi use a clock to decrement a duration counter for turning off notes (instead of using note_off)
- [ ] have tli keep track of originating line and highlight it
- [ ] use blend_mode to highlight the region being played
- [ ] on mutes, do note off
- [ ] cache parsers for notes and chain
- [ ] allow chains to playthrough only once
- [ ] Mute groups with alt+#
- [ ] TEST retrig/volume w/ crow
- [ ] TEST retrig/volume w/ midi
- [ ] TEST retrig/volume w/ melodic
- [ ] random parameter choices with '?' (e.g. m?)
- [ ] padfx as a global reverb send?
- [ ] padfx + audioin as options?
- [x] add sample selector from old one
- [x] TEST wedges define wedges per-line, everything runs at 24ppqn wedge = pulses per line
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
- [x] p1-1000 (pulse)
- [x] q100  (probability, %)
- [x] r8 (arp type)
- [x] s100 (arp skip)
- [x] t1 (arp time (in steps))
- [ ] u100 (rate)
- [x] v99 (volume add, db	)
- [x] w10 (way pan, 0-100 = -1,1)
- [x] x8 (retrig 8 times) (v-1 makes a delay type thing)
- [ ] y11 (stretchy)()
- [ ] z6  reverb send

