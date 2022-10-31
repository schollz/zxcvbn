# To Do Now (Critical)

- [ ] META > make bundle / load bundle (goes through and produces a shareable PSET, samples, dats, pngs, in a single file)
- [ ] TEST midi use a clock to decrement a duration counter for turning off notes (instead of using note_off)
- [ ] TEST retrig/volume w/ crow
- [ ] TEST retrig/volume w/ midi
- [ ] TEST retrig/volume w/ melodic

# To Do Now (Not Critical)

- [ ] allow chains to playthrough only once

# To Do Later (Critical)

# To Do Later (Not Critical)

- [ ] slice stretch synthdef (Using WarpZ)
- [ ] have tli keep track of originating line and highlight it
- [ ] use blend_mode to highlight the region being played

# DONE

- [x] option to automatically load default
- [x] K2/K3 mute/play?
- [x] E1/E2/E3 parameters (volume/filter/clade specific)
- [x] drum: drive, melodic: drive?, softcut: rec_level, 
- [x] TEST softcut save
- ~~[ ] Phasor for WarpZ gets input from a stretch bus~~
- [x] command add notes/chords without octave information
- [x] update NOTE and HEX information
- [x] Tapestop?? (Buffer constantly writing/reading)
- [x] map K's to softcut find offsets
- [x] add mx.synths and special shortcode to change the parameters j???
- [x] TEST should work without pattern or chain declaration
- [x] get reverb send working
- [x] TEST softcut sync record head to playback head
- [x] on mutes, do note off
- [x] cache parsers for notes and chain
- [x] Mute groups with alt+#
- [x] padfx as a global reverb send?
- [x] padfx + audioin as options?
- [x] random parameter choices with '?' (e.g. m?)
- [x] mute working
- [x] rate changes (reversing??)
- [x] combine crow 1+2 and crow 3+4 in the track
- [x] automatic patch of norns using `sed`
- [x] TEST controlling two norns with one keyboard
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
