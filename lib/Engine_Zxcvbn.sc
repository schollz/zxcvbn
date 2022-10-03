// Engine_Zxcvbn

// Inherit methods from CroneEngine
Engine_Zxcvbn : CroneEngine {

    // Zxcvbn specific v0.1.0
    var buses;
    var syns;
    var bufs; 
    var oscs;
    var mx;
    // Zxcvbn ^

    *new { arg context, doneCallback;
        ^super.new(context, doneCallback);
    }

    alloc {
        // Zxcvbn specific v0.0.1
        var s=context.server;


        buses = Dictionary.new();
        syns = Dictionary.new();
        bufs = Dictionary.new();
        oscs = Dictionary.new();

        oscs.put("position",OSCFunc({ |msg| NetAddr("127.0.0.1", 10111).sendMsg("progress",msg[3],msg[3]); }, '/position'));
        oscs.put("audition",OSCFunc({ |msg| NetAddr("127.0.0.1", 10111).sendMsg("audition",msg[3],msg[3]); }, '/audition'));

        context.server.sync;


        // <mx.synths>
		SynthDef("synthy",{
			arg hz=220,amp=1.0,gate=1,sub=0,portamento=1,bend=0,
			attack=0.01,decay=0.2,sustain=0.9,release=5,
			mod1=0,mod2=0,mod3=0,mod4=0,pan=0,duration=600;
			var snd,note,env,detune,stereo,lowcut,chorus,res;
			mod1=Lag.kr(mod1);mod2=Lag.kr(mod2);mod3=Lag.kr(mod3);mod4=Lag.kr(mod4);
			note=Lag.kr(hz,portamento).cpsmidi+bend;
			env=EnvGen.ar(Env.adsr(attack,decay,sustain,release),(gate-EnvGen.kr(Env.new([0,0,1],[duration,0]))),doneAction:2);
			sub=Lag.kr(sub,1);
			snd=Pan2.ar(Pulse.ar((note-12).midicps,LinLin.kr(LFTri.kr(0.5),-1,1,0.2,0.8))*sub);
			stereo=LinLin.kr(mod1,-1,1,0,1);
			lowcut=LinExp.kr(mod2,-1,1,25,11000);
			res=LinExp.kr(mod3,-1,1,0.25,1.75);
			detune=LinExp.kr(mod4,-1,1,0.00001,0.3);
			snd=snd+Mix.ar({
				arg i;
				var snd2;
				snd2=SawDPW.ar((note+(detune*(i*2-1))).midicps);
				snd2=RLPF.ar(snd2,LinExp.kr(SinOsc.kr(rrand(1/30,1/10),rrand(0,2*pi)),-1,1,lowcut,12000),res);
				snd2=DelayC.ar(snd2, rrand(0.01,0.03), LFNoise1.kr(Rand(5,10),0.01,0.02)/15);
				Pan2.ar(snd2,VarLag.kr(LFNoise0.kr(1/3),3,warp:\sine)*stereo)
			}!2);
			snd = Balance2.ar(snd[0],snd[1],Lag.kr(pan,0.1));
            snd = snd * env * amp / 8;
            Out.ar(\out.kr(0),\compressible.kr(0)*snd);
            Out.ar(\outsc.kr(0),\compressing.kr(0)*snd);
            Out.ar(\outnsc.kr(0),(1-\compressible.kr(0))*snd);
            Out.ar(\outreverb.kr(0),\sendreverb.kr(0)*snd);
		}).add;

		SynthDef("casio",{
			arg hz=220,amp=1.0,gate=1,sub=0,portamento=1,bend=0,
			attack=0.01,decay=0.2,sustain=0.9,release=5,
			mod1=0,mod2=0,mod3=0,mod4=0,pan=0,duration=600;
			var freq, env, freqBase, freqRes, pdbase, pd, pdres, pdi, snd,res,detuning,artifacts,phasing;
			hz=(Lag.kr(hz,portamento).cpsmidi + bend).midicps;
			mod1=Lag.kr(mod1);mod2=Lag.kr(mod2);mod3=Lag.kr(mod3);mod4=Lag.kr(mod4);
			env=EnvGen.ar(Env.adsr(attack,decay,sustain,release),(gate-EnvGen.kr(Env.new([0,0,1],[duration,0]))),doneAction:2);
			artifacts=LinLin.kr(mod1,-1,1,1,10);
			phasing=LinExp.kr(mod2,-1,1,0.125,8);
			res=LinExp.kr(mod3,-1,1,0.1,10);
			detuning=LinExp.kr(mod4,-1,1,0.000001,0.02);
			freq=[hz*(1-detuning),hz*(1+detuning)];
			freqBase=freq;
			freqRes=SinOsc.kr(Rand(0.01,0.2),0).range(freqBase/2,freqBase*2)*res;
			pdbase=Impulse.ar(freqBase);
			pd=Phasor.ar(pdbase,2*pi*freqBase/context.server.sampleRate*phasing,0,2pi);
			pdres=Phasor.ar(pdbase,2*pi*freqRes/context.server.sampleRate*phasing,0,2pi);
			pdi=LinLin.ar((2pi-pd).max(0),0,2pi,0,1);
			snd=Lag.ar(SinOsc.ar(0,pdres)*pdi,1/freqBase);
			snd = LPF.ar(snd,Clip.kr(hz*artifacts,20,18000));
			snd = Pan2.ar(snd,Lag.kr(pan,0.1));
            snd = snd * env * amp / 5;
            Out.ar(\out.kr(0),\compressible.kr(0)*snd);
            Out.ar(\outsc.kr(0),\compressing.kr(0)*snd);
            Out.ar(\outnsc.kr(0),(1-\compressible.kr(0))*snd);  
            Out.ar(\outreverb.kr(0),\sendreverb.kr(0)*snd);
		}).add;

		SynthDef("icarus",{
			arg hz=220,amp=1.0,gate=1,sub=1.0,portamento=1,bend=0,
			attack=0.1,decay=0.2,sustain=0.9,release=5,
			mod1=0,mod2=0,mod3=0,mod4=0,pan=0,duration=1;
			var bass,basshz,feedback=0.5,delaytime=0.25, delaytimelag=0.1;
			var ender,snd,local,in,ampcheck,env,detuning=0.1,pwmcenter=0.5,pwmwidth=0.4,pwmfreq=1.5;
			mod1=Lag.kr(mod1);mod2=Lag.kr(mod2);mod3=Lag.kr(mod3);mod4=Lag.kr(mod4);

			feedback=LinLin.kr(mod1,-1,1,0.1,2);
			delaytime=LinLin.kr(mod2,-1,1,0.05,0.6);
			pwmwidth=LinLin.kr(mod3,-1,1,0.1,0.9);
			detuning=LinExp.kr(mod4,-1,1,0.01,1);

			hz=(Lag.kr(hz,portamento).cpsmidi + bend).midicps;
			snd=Mix.new({VarSaw.ar(
				hz+(SinOsc.kr(LFNoise0.kr(1),Rand(0,3))*
					(((hz).cpsmidi+1).midicps-(hz))*detuning),
				width:LFTri.kr(pwmfreq+rrand(0.1,0.3),mul:pwmwidth/2,add:pwmcenter),
				mul:0.25
			)}!2);
			snd=snd+Mix.new({VarSaw.ar(
				hz/2+(SinOsc.kr(LFNoise0.kr(1),Rand(0,3))*
					(((hz/2).cpsmidi+1).midicps-(hz/2))*detuning),
				width:LFTri.kr(pwmfreq+rrand(0.1,0.3),mul:pwmwidth/2,add:pwmcenter),
				mul:0.15
			)}!2);

			basshz=hz;
			basshz=Select.kr(basshz>90,[basshz,basshz/2]);
			basshz=Select.kr(basshz>90,[basshz,basshz/2]);
			bass=PulseDPW.ar(basshz,width:SinOsc.kr(1/3).range(0.2,0.4));
			bass=bass+LPF.ar(WhiteNoise.ar(SinOsc.kr(1/rrand(3,4)).range(1,rrand(3,4))),2*basshz);
			bass = Pan2.ar(bass,LFTri.kr(1/6.12).range(-0.2,0.2));
			bass = HPF.ar(bass,20);
			bass = LPF.ar(bass,SinOsc.kr(0.1).range(2,5)*basshz);


			ampcheck = Amplitude.kr(Mix.ar(snd));
			snd = snd * (ampcheck > 0.02); // noise gate
			local = LocalIn.ar(2);
			local = OnePole.ar(local, 0.4);
			local = OnePole.ar(local, -0.08);
			local = Rotate2.ar(local[0], local[1],0.2);
			local = DelayC.ar(local, 0.5,
				Lag.kr(delaytime,0.2)
			);
			local = LeakDC.ar(local);
			local = ((local + snd) * 1.25).softclip;

			LocalOut.ar(local*Lag.kr(feedback,1));


			snd= Balance2.ar(local[0],local[1],pan);
			snd=snd+(SinOsc.kr(0.123,Rand(0,3)).range(0.2,1.0)*bass*sub);

			env=EnvGen.ar(Env.adsr(attack,decay,sustain,release),(gate-EnvGen.kr(Env.new([0,0,1],[duration,0]))),doneAction:2);

            snd = snd * env * amp / 8;
            Out.ar(\out.kr(0),\compressible.kr(0)*snd);
            Out.ar(\outsc.kr(0),\compressing.kr(0)*snd);
            Out.ar(\outnsc.kr(0),(1-\compressible.kr(0))*snd);  
            Out.ar(\outreverb.kr(0),\sendreverb.kr(0)*snd);
		}).add;

		// port of STK's Rhodey (yamaha DX7-style Fender Rhodes) https://sccode.org/1-522
		SynthDef("epiano",{
			arg hz=220,amp=1.0,gate=1,sub=0,portamento=1,bend=0,
			attack=0.01,decay=0.2,sustain=0.9,release=5,
			mod1=0,mod2=0,mod3=0,mod4=0,pan=0,duration=600;

			// all of these range from 0 to 1
			var vel = 0.8, modIndex = 0.2, mix = 0.2, lfoSpeed = 0.4, lfoDepth = 0.1;
			var env1, env2, env3, env4;
			var osc1, osc2, osc3, osc4, snd;
			var env;
			env=EnvGen.ar(Env.adsr(attack,decay,sustain,release),(gate-EnvGen.kr(Env.new([0,0,1],[duration,0]))),doneAction:2);
			mod1=Lag.kr(mod1);mod2=Lag.kr(mod2);mod3=Lag.kr(mod3);mod4=Lag.kr(mod4);
			hz=(Lag.kr(hz,portamento).cpsmidi + bend).midicps;
			lfoDepth=LinExp.kr(mod1,-1,1,0.01,1);
			mix=LinLin.kr(mod2,-1,1,0.0,0.4);
			modIndex=LinExp.kr(mod3,-1,1,0.01,4);
			lfoSpeed=LinLin.kr(mod4,-1,1,0,0.5);

			lfoSpeed = lfoSpeed * 12;

			hz = hz * 2;

			env1 = EnvGen.ar(Env.adsr(0.001, 1.25, 0.5, release, curve: \lin),gate);
			env2 = EnvGen.ar(Env.adsr(0.001, 1.00, 0.5, release, curve: \lin),gate);
			env3 = EnvGen.ar(Env.adsr(0.001, 1.50, 0.5, release, curve: \lin),gate);
			env4 = EnvGen.ar(Env.adsr(0.001, 1.50, 0.5, release, curve: \lin),gate);

			osc4 = SinOsc.ar(hz * 0.5) * 2pi * 2 * 0.535887 * modIndex * env4 * vel;
			osc3 = SinOsc.ar(hz, osc4) * env3 * vel;
			osc2 = SinOsc.ar(hz * 15) * 2pi * 0.05 * env2 * vel;
			osc1 = SinOsc.ar(hz, osc2) * env1 * vel;
			snd = Mix((osc3 * (1 - mix)) + (osc1 * mix));
			snd = snd * (SinOsc.ar(lfoSpeed) * lfoDepth + 1);

			snd = Pan2.ar(snd,Lag.kr(pan,0.1));

            snd = snd * env * amp / 8;
            Out.ar(\out.kr(0),\compressible.kr(0)*snd);
            Out.ar(\outsc.kr(0),\compressing.kr(0)*snd);
            Out.ar(\outnsc.kr(0),(1-\compressible.kr(0))*snd);  
            Out.ar(\outreverb.kr(0),\sendreverb.kr(0)*snd);
		}).add;


		SynthDef("toshiya",{
			arg hz=220,amp=1.0,gate=1,sub=0,portamento=1,bend=0,
			attack=0.01,decay=0.2,sustain=0.9,release=5,
			mod1=0,mod2=0,mod3=0,mod4=0,pan=0,duration=600;
			var snd,note,env,detune,stereo,lowcut,chorus,klanky,klankyvol;
			mod1=Lag.kr(mod1);mod2=Lag.kr(mod2);mod3=Lag.kr(mod3);mod4=Lag.kr(mod4);
			detune=LinExp.kr(mod1,-1,1,0.001,0.1);
			klankyvol=LinLin.kr(mod2,-1,1,0,2);
			lowcut=LinExp.kr(mod3,-1,1,25,11000);
			chorus=LinExp.kr(mod4,-1,1,0.2,5);

			note=Lag.kr(hz,portamento).cpsmidi + bend;
			env=EnvGen.ar(Env.adsr(attack,decay,sustain,release),(gate-EnvGen.kr(Env.new([0,0,1],[duration,0]))),doneAction:2);
			sub=Lag.kr(sub,1);
			snd=Pan2.ar(SinOsc.ar((note-12).midicps,LinLin.kr(LFTri.kr(0.5),-1,1,0.2,0.8))/12*amp,SinOsc.kr(0.1,mul:0.2))*sub;
			snd=snd+Mix.ar({
				arg i;
				var snd2;
				snd2=SinOsc.ar((note+(detune*(i*2-1))).midicps);
				snd2=LPF.ar(snd2,LinExp.kr(SinOsc.kr(rrand(1/30,1/10),rrand(0,2*pi)),-1,1,lowcut,12000),2);
				snd2=DelayC.ar(snd2, rrand(0.01,0.03), LFNoise1.kr(Rand(5,10),0.01,0.02)/NRand(10,20,3)*chorus );
				Pan2.ar(snd2,VarLag.kr(LFNoise0.kr(1/3),3,warp:\sine))
			}!2);
			snd=snd+(Amplitude.kr(snd)*VarLag.kr(LFNoise0.kr(1),1,warp:\sine).range(0.1,1.0)*klankyvol*Klank.ar(`[[hz, hz*2+2, hz*4+5, hz*8+2], nil, [1, 1, 1, 1]], PinkNoise.ar([0.007, 0.007])));
			snd = Balance2.ar(snd[0],snd[1],Lag.kr(pan,0.1));
            snd = snd * env * amp / 8;
            Out.ar(\out.kr(0),\compressible.kr(0)*snd);
            Out.ar(\outsc.kr(0),\compressing.kr(0)*snd);
            Out.ar(\outnsc.kr(0),(1-\compressible.kr(0))*snd);  
            Out.ar(\outreverb.kr(0),\sendreverb.kr(0)*snd);
		}).add;

		SynthDef("malone",{
			arg hz=220,amp=1.0,gate=1,sub=0,portamento=1,bend=0,
			attack=0.01,decay=0.2,sustain=0.9,release=5,
			mod1=0,mod2=0,mod3=0,mod4=0,pan=0,duration=600;
			var snd,note,env, basshz,bass, detuning,pw, res,filt,detuningSpeed;
			mod1=Lag.kr(mod1);mod2=Lag.kr(mod2);mod3=Lag.kr(mod3);mod4=Lag.kr(mod4);

			detuningSpeed=LinExp.kr(mod1,-1,1,0.1,10);
			filt=LinLin.kr(mod2,-1,1,2,10);
			res=LinExp.kr(mod3,-1,1,0.25,4);
			detuning=LinExp.kr(mod4,-1,1,0.002,0.8);
			hz=(Lag.kr(hz,portamento).cpsmidi + bend).midicps;
			note=hz.cpsmidi;
			env=EnvGen.ar(Env.adsr(attack,decay,sustain,release),(gate-EnvGen.kr(Env.new([0,0,1],[duration,0]))),doneAction:2);
			snd=Mix.ar(Array.fill(2,{
				arg i;
				var hz_,snd_;
				hz_=((2*hz).cpsmidi+SinOsc.kr(detuningSpeed*Rand(0.1,0.5),Rand(0,pi)).range(detuning.neg,detuning)).midicps;
				snd_=PulseDPW.ar(hz_,0.17);
				snd_=snd_+PulseDPW.ar(hz_/2,0.17);
				snd_=snd_+PulseDPW.ar(hz_*2,0.17);
				snd_=snd_+LFTri.ar(hz_/4);
				snd_=RLPF.ar(snd_,Clip.kr(hz_*filt,hz_*1.5,16000),Clip.kr(LFTri.kr([0.5,0.45]).range(0.3,1)*res,0.2,2));
				Pan2.ar(snd_,VarLag.kr(LFNoise0.kr(1/3),3,warp:\sine))/10
			}));


			basshz=hz;
			basshz=Select.kr(basshz>90,[basshz,basshz/2]);
			basshz=Select.kr(basshz>90,[basshz,basshz/2]);
			bass=PulseDPW.ar(basshz,width:SinOsc.kr(1/3).range(0.2,0.4));
			bass=bass+LPF.ar(WhiteNoise.ar(SinOsc.kr(1/rrand(3,4)).range(1,rrand(3,4))),2*basshz);
			bass = Pan2.ar(bass,LFTri.kr(1/6.12).range(-0.2,0.2));
			bass = HPF.ar(bass,20);
			bass = LPF.ar(bass,SinOsc.kr(0.1).range(2,5)*basshz);
			snd=snd+(SinOsc.kr(0.123).range(0.2,1.0)*bass*sub);

			snd = Balance2.ar(snd[0],snd[1],Lag.kr(pan,0.1));
            snd = snd * env * amp / 8;
            Out.ar(\out.kr(0),\compressible.kr(0)*snd);
            Out.ar(\outsc.kr(0),\compressing.kr(0)*snd);
            Out.ar(\outnsc.kr(0),(1-\compressible.kr(0))*snd);  
            Out.ar(\outreverb.kr(0),\sendreverb.kr(0)*snd);
		}).add;

		// http://sccode.org/1-51n
		SynthDef("kalimba",{
			arg hz=220,amp=1.0,gate=1,sub=0,portamento=1,bend=0,
			attack=0.01,decay=0.2,sustain=0.9,release=0.8,
			mod1=0,mod2=0,mod3=0,mod4=0,pan=0,duration=0.5;
			var snd,env,click,mix;
			mod1=Lag.kr(mod1);mod2=Lag.kr(mod2);mod3=Lag.kr(mod3);mod4=Lag.kr(mod4);
			hz=(Lag.kr(hz,portamento).cpsmidi + bend).midicps;
			env=EnvGen.ar(Env.adsr(attack,0,1.0,release),(gate-EnvGen.kr(Env.new([0,0,1],[duration,0]))),doneAction:2);
			mix=LinLin.kr(mod4,-1,1,0.01,0.4);

			// Basic tone is a SinOsc
			snd = SinOsc.ar((hz.cpsmidi+mod4).midicps);
			snd = HPF.ar( LPF.ar(snd, 380), 40);
			// The "clicking" sounds are modeled with a bank of resonators excited by enveloped white noise
			click = DynKlank.ar(`[
				// the resonant frequencies are randomized a little to add variation
				// there are two high resonant freqs and one quiet "bass" freq to give it some depth
				[240*ExpRand(0.97, 1.02), 2020*ExpRand(0.97, 1.02), 3151*ExpRand(0.97, 1.02)],
				[-9, 0, -5].dbamp,
				[0.8, 0.07, 0.08]
			], BPF.ar(PinkNoise.ar, Rand(5500,8500), Rand(0.05,0.2)) * EnvGen.ar(Env.perc(0.001, 0.01)));
			snd = (snd*mix) + (click*(1-mix));
			snd = Splay.ar(snd,center:Rand(-1,1)*LinLin.kr(mod1,-1,1,0,1));

			snd=Vibrato.ar(
				snd,
				rate:LinExp.kr(mod2,-1,1,0.0001,20),
				depth:LinExp.kr(mod3,-1,1,0.0001,1)
			);

			snd = Balance2.ar(snd[0],snd[1],Lag.kr(pan,0.1));
            snd = snd * env * amp;
            Out.ar(\out.kr(0),\compressible.kr(0)*snd);
            Out.ar(\outsc.kr(0),\compressing.kr(0)*snd);
            Out.ar(\outnsc.kr(0),(1-\compressible.kr(0))*snd);  
            Out.ar(\outreverb.kr(0),\sendreverb.kr(0)*snd);
		}).add;

		SynthDef("mdapiano",{
			arg hz=220,amp=1.0,gate=1,sub=0,portamento=1,
			attack=0.01,decay=0.2,sustain=0.9,release=5,
			mod1=0,mod2=0,mod3=0,mod4=0,pan=0,duration=600;
			var snd,env,tuning;
			mod1=Lag.kr(mod1);mod2=Lag.kr(mod2);mod3=Lag.kr(mod3);mod4=Lag.kr(mod4);
			hz=Lag.kr(hz,portamento);
			env=EnvGen.ar(Env.adsr(attack,0,1.0,release),(gate-EnvGen.kr(Env.new([0,0,1],[duration,0]))),doneAction:2);

			tuning=LinLin.kr(Clip.kr(mod4),0,1,0,1);
			snd=MdaPiano.ar(
				freq:hz,
				gate:gate,
				decay:decay,
				release:release,
				stereo:LinLin.kr(mod1,-1,1,0.3,1),
				vel:Rand(40,80),
				tune:Rand(0.5+tuning.neg,0.5+tuning)
			);
			snd=Vibrato.ar(
				snd,
				rate:LinExp.kr(mod2,-1,1,0.0001,20),
				depth:LinExp.kr(mod3,-1,1,0.0001,1)
			);
			snd = Pan2.ar(snd,Lag.kr(pan,0.1));
            snd = snd * env * amp / 6;
            Out.ar(\out.kr(0),\compressible.kr(0)*snd);
            Out.ar(\outsc.kr(0),\compressing.kr(0)*snd);
            Out.ar(\outnsc.kr(0),(1-\compressible.kr(0))*snd);  
            Out.ar(\outreverb.kr(0),\sendreverb.kr(0)*snd);
		}).add;

		// https://github.com/monome/dust/blob/master/lib/sc/Engine_PolyPerc.sc
		SynthDef("polyperc",{
			arg hz=220,amp=1.0,gate=1,sub=0,portamento=1,bend=0,
			attack=0.01,decay=0.2,sustain=0.9,release=5,
			mod1=0,mod2=0,mod3=0,mod4=0,pan=0,duration=600;
			var snd,filt,env,pw,co,gain,detune,note;
			mod1=Lag.kr(mod1);mod2=Lag.kr(mod2);mod3=Lag.kr(mod3);mod4=Lag.kr(mod4);
			hz=Lag.kr(hz,portamento);
			pw=LinLin.kr(mod1,-1,1,0.3,0.7);
			co=LinExp.kr(mod2,-1,1,hz,Clip.kr(10*hz,200,18000));
			gain=LinLin.kr(mod3,-1,1,0.25,3);
			detune=LinExp.kr(mod4,-1,1,0.00001,0.3);
			note=hz.cpsmidi + bend;
			snd = Pulse.ar([note-detune,note+detune].midicps, pw);
			snd = MoogFF.ar(snd,co,gain);
			env=EnvGen.ar(Env.adsr(attack,decay,sustain,release),(gate-EnvGen.kr(Env.new([0,0,1],[duration,0]))),doneAction:2);
			snd = Pan2.ar(snd,Lag.kr(pan,0.1));
            snd = snd * env * amp / 12;
            Out.ar(\out.kr(0),\compressible.kr(0)*snd);
            Out.ar(\outsc.kr(0),\compressing.kr(0)*snd);
            Out.ar(\outnsc.kr(0),(1-\compressible.kr(0))*snd);  
            Out.ar(\outreverb.kr(0),\sendreverb.kr(0)*snd);
		}).add;

		// https://github.com/catfact/zebra/blob/master/lib/Engine_DreadMoon.sc#L20-L41
		SynthDef("dreadpiano",{
			arg hz=220,amp=1.0,pan=0,gate=1,
			sub=0,portamento=1,bend=0,
			attack=0.01,decay=0.2,sustain=0.9,release=5,
			mod1=0,mod2=0,mod3=0,mod4=0,duration=600;
			var snd,note,env, damp;
			var noise, string, delaytime, lpf, noise_env, damp_mul;
			var noise_hz = 4000, noise_attack=0.002, noise_decay=0.06,
			tune_up = 1.0005, tune_down = 0.9996, string_decay=3.0,
			lpf_ratio=2.0, lpf_rq = 4.0, hpf_hz = 40, damp_time=0.1;
			mod1=Lag.kr(mod1);mod2=Lag.kr(mod2);mod3=Lag.kr(mod3);mod4=Lag.kr(mod4);

			// mods
			string_decay=LinLin.kr(mod1,-1,1,0.1,6);
			noise_hz=LinExp.kr(mod2,-1,1,200,16000);
			lpf_rq=LinLin.kr(mod3,-1,1,0.1,8);
			tune_up=1+LinLin.kr(mod4,-1,1,0.0001,0.0005*4);
			tune_down=1-LinLin.kr(mod4,-1,1,0.00005,0.0004*4);

			hz=(Lag.kr(hz,portamento).cpsmidi + bend).midicps;
			env=EnvGen.ar(Env.adsr(attack,decay,sustain,release),(gate-EnvGen.kr(Env.new([0,0,1],[duration,0]))),doneAction:2);

			damp = 0;
			damp_mul = LagUD.ar(K2A.ar(1.0 - damp), 0, damp_time);

			noise_env = Decay2.ar(Impulse.ar(0));
			noise = LFNoise2.ar(noise_hz) * noise_env;

			delaytime = 1.0 / (hz * [tune_up, tune_down]);
			string = Mix.new(CombL.ar(noise, delaytime, delaytime, string_decay * damp_mul));

			snd = RLPF.ar(string, lpf_ratio * hz, lpf_rq);
			snd = HPF.ar(snd, hpf_hz);
			snd = Pan2.ar(snd,Lag.kr(pan,0.1));

            snd = snd * env * amp / 5;
            Out.ar(\out.kr(0),\compressible.kr(0)*snd);
            Out.ar(\outsc.kr(0),\compressing.kr(0)*snd);
            Out.ar(\outnsc.kr(0),(1-\compressible.kr(0))*snd);  
            Out.ar(\outreverb.kr(0),\sendreverb.kr(0)*snd);
		}).add;

		SynthDef("aaaaaa",{
			arg out=0,hz=220,amp=1.0,pan=0,gate=1,
			sub=0,portamento=1,bend=0,
			attack=0.01,decay=0.2,sustain=0.9,release=5,
			mod1=0,mod2=0,mod3=0,mod4=0,duration=600;
	    var saw, wiggle, snd;
	    // frequencies drawn from https://slideplayer.com/slide/15020921/
	    var f1a = [290, 420, 580, 720, 690, 550, 400, 280];
	    var f2a = [750, 1000, 790, 1100, 1600, 1750, 1900, 2200];
	    var f3a = [2300, 2350, 2400, 2500, 2600, 2700, 2800, 3300];
	    var f4a = [3500, 3500, 3500, 3500, 3500, 3500, 3500, 3500];
	    var f1b = [390, 435, 590, 850, 860, 600, 420, 360];
	    var f2b = [900, 1100, 850, 1200, 2200, 2350, 2500, 2750];
	    var f3b = [2850, 2900, 3000, 3000, 3100, 3200, 3300, 3800];
	    var f4b = [4000, 4000, 4000, 4000, 4000, 4000, 4000, 4000];
	    var f1c = [420, 590, 640, 1100, 1000, 700, 575, 375];
	    var f2c = [1200, 1300, 1100, 1300, 2500, 2700, 2800, 3200];
	    var f3c = [3200, 3250, 3300, 3400, 3500, 3600, 3700, 4200];
	    var f4c = [4500, 4500, 4500, 4500, 4500, 4500, 4500, 4500];
	    var f1, f2, f3, f4;
	    var a1, a2, a3, a4;
	    var q1, q2, q3, q4;
	    var voice, vowel, tilt, cons, detune, focus, div, reso;
	    var env;
	    mod1=Lag.kr(mod1);mod2=Lag.kr(mod2);mod3=Lag.kr(mod3);mod4=Lag.kr(mod4);
	    voice=Select.kr( (mod1 > -0.99), [hz.explin(100, 1000, 0, 2), LinLin.kr(mod1, -1, 1, 0, 2)]);
	    vowel=LinLin.kr(mod2, -1, 1, 0, 7);
	    tilt=LinLin.kr(mod2, -1, 1, 0.3, 0.6) * LinLin.kr(mod4, -1, 1, 0.6, 1.1);
	    reso = LinLin.kr(mod4, -1, 1, 0.1, 0.23);
	    detune = LinLin.kr(mod3, -1, 1, 0, 0.015);
	    focus = -1 * LinLin.kr(mod3, -1, 1, 0, 1);
	    div = LinLin.kr(mod3, -1, 1, 1, 7).sqrt;
	    cons = mod4.linlin(-1, 1, -0.5, 0.8);

	    f1 = LinSelectX.kr(voice, LinSelectX.kr(vowel, [f1a, f1b, f1c].flop));
	    f2 = LinSelectX.kr(voice, LinSelectX.kr(vowel, [f2a, f2b, f2c].flop));
	    f3 = LinSelectX.kr(voice, LinSelectX.kr(vowel, [f3a, f3b, f3c].flop));
	    f4 = LinSelectX.kr(voice, LinSelectX.kr(vowel, [f4a, f4b, f4c].flop));
	    a1 = 1;
	    a2 = tilt;
	    a3 = tilt ** 1.5;
	    a4 = tilt ** 2;
	    q1 = reso;
	    q2 = q1/1.5;
	    q3 = q2/1.5;
	    q4 = reso/10;

			hz=(Lag.kr(hz,portamento).cpsmidi + bend).midicps;
	    saw = VarSaw.ar(hz*(1+ (detune * [-1, 0.7, -0.3, 0, 0.3, -0.7, 1])), width: 0).collect({ |item, index|
	      Pan2.ar(item, index.linlin(0, 6, -1, 1)*SinOsc.kr(Rand.new(0.1, 0.3))*focus)
	    });
	    wiggle = EnvGen.kr(Env.perc(attackTime: 0.0, releaseTime: 0.15), doneAction: Done.none);
	    saw.postln;
	    snd = HPF.ar(
		    Mix.new(BBandPass.ar(saw, ([
		    f1,
		    f2 * (1 + (cons*wiggle)),
		    f3,
		    f4]!2).flop,
		    ([q1, q2, q3, q4]!2).flop) * ([a1, a2, a3, a4]!2).flop),
		  20);
		  snd.postln;

			env=EnvGen.ar(Env.adsr(attack,decay,sustain,release),(gate-EnvGen.kr(Env.new([0,0,1],[duration,0]))),doneAction:2);

			snd = Balance2.ar(snd[0], snd[1], Lag.kr(pan,0.1)).tanh;

            snd = snd * env * amp / 5;
            Out.ar(\out.kr(0),\compressible.kr(0)*snd);
            Out.ar(\outsc.kr(0),\compressing.kr(0)*snd);
            Out.ar(\outnsc.kr(0),(1-\compressible.kr(0))*snd);  
            Out.ar(\outreverb.kr(0),\sendreverb.kr(0)*snd);
		}).add;

		SynthDef("triangles",{
			arg out=0,hz=220,amp=1.0,gate=1,sub=0,portamento=1,
			attack=0.01,decay=0.2,sustain=0.9,release=5,
			mod1=0,mod2=0,mod3=0,mod4=0,pan=0,duration=600;
			var snd,env,bellow_env,bellow,
			detune_cents,detune_semitones,
			f_cents,freq_a,freq_b,decimation_bits,decimation_rate,
			noise_level,vibrato_rate,vibrato_depth;
			mod1=Lag.kr(mod1);mod2=Lag.kr(mod2);mod3=Lag.kr(mod3);mod4=Lag.kr(mod4);
			hz=Lag.kr(hz,portamento);
			env=EnvGen.ar(Env.adsr(attack,decay,sustain,release),(gate-EnvGen.kr(Env.new([0,0,1],[duration,0]))),doneAction:2);

			bellow=LinLin.kr(mod1,-1,1,0,1);
			decimation_bits = LinLin.kr(mod2, -1, 1, 24, 4);
			decimation_rate = LinLin.kr(mod2, -1, 1, 44100, 8000);
			noise_level = LinLin.kr(mod2, -1, 1, 0, 0.5);
			detune_semitones = LinLin.kr(mod3, -1, 1, -24, 24);
			vibrato_rate = LinLin.kr(mod4, -1, 1, 0, 5);
			vibrato_depth = LinExp.kr(mod4, -1, 1, 0.001, 0.3);

			bellow_env = EnvGen.kr(Env.step([bellow, 1-bellow], [attack, release], 1), gate: gate);
			freq_a = hz;
			freq_b = (hz.cpsmidi + detune_semitones.round).midicps;

			snd = Mix.new([
				SelectX.ar(bellow_env.lag, [
					DPW3Tri.ar(Vibrato.ar(freq_a, vibrato_rate, vibrato_depth)),
					DPW3Tri.ar(Vibrato.ar(freq_b, vibrato_rate, vibrato_depth)),
				]),
				PinkNoise.ar(noise_level),
			]);

			snd = Decimator.ar(snd, decimation_rate, decimation_bits);

			snd = Pan2.ar(snd,Lag.kr(pan,0.1));
            snd = snd * env * amp / 8;
            Out.ar(\out.kr(0),\compressible.kr(0)*snd);
            Out.ar(\outsc.kr(0),\compressing.kr(0)*snd);
            Out.ar(\outnsc.kr(0),(1-\compressible.kr(0))*snd); 
            Out.ar(\outreverb.kr(0),\sendreverb.kr(0)*snd);
		}).add;

        // </mx.synths>


        (1..2).do({arg ch;
        SynthDef("playerOneShot"++ch,{ 
            arg bufnum, id=0.0,amp=0.25, rate=1.0,sampleStart=0.0,sampleEnd=1.0, watch=0.0, xfade=0.01,t_free=0,attack=0.005,release=1000000;

            // vars
            var snd,pos,sampleDuration,sampleInit;
            var duration=BufDur.ir(bufnum);
            var frames=BufFrames.ir(bufnum);

            sampleStart=sampleStart-(xfade/2);
            sampleInit=Select.kr(sampleStart<0,[sampleStart,sampleStart+sampleEnd]);
            sampleStart=Select.kr(sampleStart<0,[sampleStart,0]);
            sampleEnd=sampleEnd+(xfade/2);
            sampleEnd=Select.kr(sampleEnd>duration,[sampleEnd,duration]);
            sampleDuration=(sampleEnd-sampleStart)/rate.abs;

            pos=Phasor.ar(
                trig:Impulse.kr(0),
                rate:rate/context.server.sampleRate,
                start:((sampleStart*(rate>0))+(sampleEnd*(rate<0))),
                end:((sampleEnd*(rate>0))+(sampleStart*(rate<0))),
                resetPos:sampleInit
            );

            snd=BufRd.ar(ch,bufnum,pos/duration*frames,
                loop:1,
                interpolation:4
            );
            snd=Pan2.ar(snd,0);

            snd=snd*amp*EnvGen.ar(Env.new([0,1,1,0],[xfade/2,sampleDuration-xfade,xfade/2]),doneAction:2);
            snd=snd*EnvGen.ar(Env.new([1,0],[xfade/2]),gate:t_free,doneAction:2);
            // envelopes
            snd=snd*EnvGen.ar(Env.perc(attack,release),doneAction:2);

            SendReply.kr(Impulse.kr(10),'/audition',[A2K.kr(pos)]);                      

            Out.ar(0,snd);
        }).add; 
        });


        SynthDef("defAudioIn",{
            arg ch=0,lpf=20000,lpfqr=0.707,hpf=20,hpfqr=0.909,pan=0,amp=1.0;
            var snd;
            snd=SoundIn.ar(ch);
            snd=Pan2.ar(snd,pan,amp);
            snd=RHPF.ar(snd,hpf,hpfqr);
            snd=RLPF.ar(snd,lpf,lpfqr);
            Out.ar(\out.kr(0),\compressible.kr(0)*snd);
            Out.ar(\outsc.kr(0),\compressing.kr(0)*snd);
            Out.ar(\outnsc.kr(0),(1-\compressible.kr(0))*snd);
            Out.ar(\outreverb.kr(0),\sendreverb.kr(0)*snd);
        }).add;


        (1..2).do({arg ch;
        SynthDef("playerInOut"++ch,{
            arg out=0, buf, id=0,amp=1.0, pan=0, filter=18000, rate=1.0,pitch=0,sampleStart=0.0,sampleEnd=1.0,sampleIn=0.0,sampleOut=1.0, watch=0, gate=1, xfade=0.1,
            duration=10000,attack=0.001,decay=0.3,sustain=1.0,release=2.0;
            
            // vars
            var snd,pos,trigger,sampleDuration,sampleDurationInOut,imp,aOrB,posA,sndA,posB,sndB,trigA,trigB;
            var durationBuffer=BufDur.ir(buf);
            var frames=BufFrames.ir(buf);
            
            rate = BufRateScale.ir(buf)*rate*pitch.midiratio;
            sampleDuration=(sampleEnd-sampleStart)/rate.abs;
            sampleDurationInOut=(sampleOut-sampleIn)/rate.abs;
            
            trigger=DelayN.kr(Impulse.kr(0)+Impulse.kr(1/sampleDurationInOut),sampleDuration*0.9,sampleDuration*0.9);
            aOrB=ToggleFF.kr(trigger);
            
            posA=Phasor.ar(
                trig:1-aOrB,
                rate:rate,
                start:sampleStart/durationBuffer*frames,
                end:sampleEnd/durationBuffer*frames,
                resetPos:sampleIn/durationBuffer*frames
            );
            sndA=BufRd.ar(ch,buf,posA,
                loop:1,
                interpolation:4
            );
            posB=Phasor.ar(
                trig:aOrB,
                rate:rate.neg,
                start:sampleStart/durationBuffer*frames,
                end:sampleEnd/durationBuffer*frames,
                resetPos:sampleOut/durationBuffer*frames
            );
            sndB=BufRd.ar(ch,buf,posB,
                loop:1,
                interpolation:4
            );

            pos=Select.kr(aOrB,[posA,posB]);
            snd=SelectX.ar(Lag.kr(aOrB,xfade),[sndA,sndB],0)*amp;

            snd=LPF.ar(snd,filter);
            snd=Pan2.ar(snd,pan);
            snd=snd*EnvGen.ar(Env.adsr(attack,decay,sustain,release),gate * (1-TDelay.kr(Impulse.kr(0),duration)) ,doneAction:2);
            
            SendReply.kr(Impulse.kr(10)*watch,'/position',[pos / BufFrames.ir(buf) * BufDur.ir(buf)]);

            Out.ar(\out.kr(0),\compressible.kr(0)*snd*amp);
            Out.ar(\outsc.kr(0),\compressing.kr(0)*snd);
            Out.ar(\outnsc.kr(0),(1-\compressible.kr(0))*snd*amp);
            Out.ar(\outreverb.kr(0),\sendreverb.kr(0)*snd);
        }).add;
        });


        SynthDef("kick", { |basefreq = 40, ratio = 6, sweeptime = 0.05, preamp = 1, amp = 1,
            decay1 = 0.3, decay1L = 0.8, decay2 = 0.15, clicky=0.0, out|
            var snd;
            var    fcurve = EnvGen.kr(Env([basefreq * ratio, basefreq], [sweeptime], \exp)),
            env = EnvGen.kr(Env([clicky,1, decay1L, 0], [0.0,decay1, decay2], -4), doneAction: Done.freeSelf),
            sig = SinOsc.ar(fcurve, 0.5pi, preamp).distort * env ;
            snd = (sig*amp).tanh!2;
            Out.ar(\out.kr(0),\compressible.kr(0)*snd);
            Out.ar(\outsc.kr(0),\compressing.kr(0)*snd);
            Out.ar(\outnsc.kr(0),(1-\compressible.kr(0))*snd);
            Out.ar(\outreverb.kr(0),\sendreverb.kr(0)*snd);
        }).send(context.server);

        SynthDef(\main, {
            arg outBus=0,inBusNSC,inSC,sidechain_mult=2,compress_thresh=0.1,compress_level=0.1,compress_attack=0.01,compress_release=1,inBus;
            var snd,sndSC,sndNSC;
            snd=In.ar(inBus,2);
            sndNSC=In.ar(inBusNSC,2);
            sndSC=In.ar(inSC,2);
            snd = Compander.ar(snd, (sndSC*sidechain_mult), 
                compress_thresh, 1, compress_level, 
                compress_attack, compress_release);
            snd = snd + sndNSC;
            snd = LeakDC.ar(snd);
            Out.ar(outBus,snd);
        }).send(context.server);

        SynthDef(\pad0, {
            var snd;
            snd = Saw.ar(\freq.kr(440) * ((-3..3) * 0.05).midiratio * [1, 2, 1, 4, 1, 2, 1]);
            snd = RLPF.ar(snd, LFNoise2.kr(0.3 ! snd.size).linexp(-1, 1, 100, 8000), 0.3);
            snd = Splay.ar(snd);
            snd = snd * EnvGen.ar(Env.asr(\attack.kr(0.5), 1.0, \release.kr(0.5)),\gate.kr(1) * ToggleFF.kr(1-TDelay.kr(DC.kr(1),\duration.kr(1))),doneAction:2);
            snd = snd * -30.dbamp * \amp.kr(1);
            Out.ar(\out.kr(0), snd);
            Out.ar(\outreverb.kr(0),\sendreverb.kr(0)*snd);
        }).send(context.server);

        SynthDef(\pad1, {
            var snd;
            snd = Saw.ar(\freq.kr(440) * ((-3..3) * 0.05).midiratio * [1, 2, 1, 4, 1, 2, 1]);
            snd = Splay.ar(snd);
            snd = MoogFF.ar(snd, XLine.kr(100,rrand(6000,12000),8), 0);
            snd = snd * EnvGen.ar(Env.asr(\attack.kr(0.5), 1.0, \release.kr(0.5)),\gate.kr(1) * ToggleFF.kr(1-TDelay.kr(DC.kr(1),\duration.kr(1))),doneAction:2);
            snd = Balance2.ar(snd[0], snd[1], \pan.kr(0));
            snd = snd * -10.dbamp * \amp.kr(1);
            Out.ar(\out.kr(0), snd);
            Out.ar(\outreverb.kr(0),\sendreverb.kr(0)*snd);
        }).send(context.server);

        SynthDef(\pad2,{
            var snd;
            snd = CombC.ar(PinkNoise.ar * -10.dbamp, \freq.kr(440).reciprocal, \freq.kr(440).reciprocal, 2.0);
            snd = snd ! 2;
            snd = LeakDC.ar(snd);
            snd = snd * EnvGen.ar(Env.asr(\attack.kr(0.5), 1.0, \release.kr(0.5)),\gate.kr(1) * ToggleFF.kr(1-TDelay.kr(DC.kr(1),\duration.kr(1))),doneAction:2);
            snd = Balance2.ar(snd[0], snd[1], \pan.kr(0));
            snd = snd * -50.dbamp * \amp.kr(1);
            Out.ar(\out.kr(0), snd);
            Out.ar(\outreverb.kr(0),\sendreverb.kr(0)*snd);
        }).send(context.server);

        SynthDef(\padFx, {
            var snd, env;
            snd = In.ar(\in.kr(0), 2);
            snd = snd * -10.dbamp;
            snd = snd + (NHHall.ar(snd, 8, modDepth: 1) * -5.dbamp);
            snd = snd + PitchShift.ar(snd, 0.2, 0.5);
            snd = snd + PitchShift.ar(snd, 0.13, 0.2);
            snd = DelayC.ar(snd, 0.2, SinOsc.ar(0.3, [0, pi]).linlin(-1,1,0,0.001));
            env = Env.perc(0.2, 0.5, curve: -2).kr(Done.none, \gate.tr(0));
            snd = snd * (1 - (0.9 * env));
            snd = MoogFF.ar(snd, 9000 * (1 - (0.5 *env)) + 100, 0);
            snd = snd + NHHall.ar(snd, 2);
            //snd = LPF.ar(snd, MouseY.kr(100,20000,1));
            Out.ar(\out.kr(0),\compressible.kr(0)*snd);
            Out.ar(\outsc.kr(0),\compressing.kr(0)*snd);
            Out.ar(\outnsc.kr(0),(1-\compressible.kr(0))*snd);
        }).send(context.server);

        (1..2).do({arg ch;
        SynthDef("slice"++ch,{
            arg amp=0, buf=0, rate=1, pos=0, gate=1, duration=100000, pan=0, send_pos=0, filter=18000, attack=0.01,release=0.01; 
            var snd;
            var snd_pos = Phasor.ar(
                trig: Impulse.kr(0),
                rate: rate * BufRateScale.ir(buf),
                resetPos: pos / BufDur.ir(buf) * BufFrames.ir(buf),
                end: BufFrames.ir(buf),
            );
            SendReply.kr(Impulse.kr(10)*send_pos,'/position',[snd_pos / BufFrames.ir(buf) * BufDur.ir(buf)]);
            snd = BufRd.ar(ch,buf,snd_pos,interpolation:4);
            snd = snd * Env.asr(attack, 1, release).ar(Done.freeSelf, gate * ToggleFF.kr(1-TDelay.kr(DC.kr(1),duration)) );
            snd = Pan2.ar(snd,pan);
            snd = RLPF.ar(snd,filter,0.707);

            // fx
            snd = (snd * 30.dbamp).tanh * -10.dbamp;
            snd = SelectX.ar(\decimate.kr(0).lag(0.01), [snd, Latch.ar(snd, Impulse.ar(LFNoise2.kr(0.3).exprange(1000,16e3)))]);
            snd = SelectX.ar(\pitch1.kr(0).lag(0.01), [snd, PitchShift.ar(snd, 0.2, 2)]);
            snd = SelectX.ar(\pitch2.kr(0).lag(0.01), [snd, PitchShift.ar(snd, 0.03, 1.4)]);
            snd = BHiShelf.ar(BLowShelf.ar(snd, 500, 1, -10), 3000, 1, -10);
            snd = (snd * 10.dbamp).tanh * -10.dbamp;
            snd = BHiShelf.ar(BLowShelf.ar(snd, 500, 1, 10), 3000, 1, 10);
            snd = snd * -20.dbamp;
            snd = RLPF.ar(snd,LinExp.kr(\filter.kr(1).lag(1)+0.01,0.01,1,100,16000),0.707);
            snd = CompanderD.ar(snd);

            Out.ar(\out.kr(0),\compressible.kr(0)*snd*amp);
            Out.ar(\outsc.kr(0),\compressing.kr(0)*snd);
            Out.ar(\outnsc.kr(0),(1-\compressible.kr(0))*snd*amp);
            Out.ar(\outreverb.kr(0),\sendreverb.kr(0)*snd);
        }).send(context.server);
        });


        context.server.sync;
        buses.put("busCompressible",Bus.audio(s,2));
        buses.put("busNotCompressible",Bus.audio(s,2));
        buses.put("busCompressing",Bus.audio(s,2));
        buses.put("busReverb",Bus.audio(s,2));
        context.server.sync;
        mx = MxSamplesZ(Server.default,100,buses.at("busCompressible").index,buses.at("busNotCompressible").index,buses.at("busCompressing"),buses.at("busReverb"));
        context.server.sync;
        syns.put("main",Synth.new(\main,[\outBus,0,\sidechain_mult,8,\inBus,buses.at("busCompressible"),\inBusNSC,buses.at("busNotCompressible"),\inSC,buses.at("busCompressing")]));
        NodeWatcher.register(syns.at("main"));
        context.server.sync;
        syns.put("reverb", Synth.new(\padFx, [
            out: buses.at("busCompressible"),
            outsc: buses.at("busCompressing"),
            outnsc: buses.at("busNotCompressible"),
            compressible: 1,
            compressing: 0,
            in: buses.at("busReverb"), gate: 0], syns.at("main"), \addBefore));
        NodeWatcher.register(syns.at("reverb"));
        context.server.sync;

        syns.put("audioInL",Synth.new("defAudioIn",[ch:0,
            out: buses.at("busCompressible"),
            outsc: buses.at("busCompressing"),
            outnsc: buses.at("busNotCompressible"),
            outreverb: buses.at("busReverb"),
            compressible: 0,
            compressing: 0,
            pan:-1], syns.at("reverb"), \addBefore));
        syns.put("audioInR",Synth.new("defAudioIn",[ch:1,
            out: buses.at("busCompressible"),
            outsc: buses.at("busCompressing"),
            outnsc: buses.at("busNotCompressible"),
            outreverb: buses.at("busReverb"),
            compressible: 0,
            compressing: 0,
            pan:1], syns.at("reverb"), \addBefore));
        NodeWatcher.register(syns.at("audioInR"));
        NodeWatcher.register(syns.at("audioInL"));

        context.server.sync;

        this.addCommand("main_set","sf",{ arg msg;
            var k=msg[1];
            var v=msg[2];
            if (syns.at("main").notNil,{
                if (syns.at("main").isRunning,{
                    ["Main: setting",k,v].postln;
                    syns.at("main").set(k.asString,v);
                });
            });
        });

        this.addCommand("audionin_set","ssf",{ arg msg;
            var lr=msg[1];
            var key=msg[2];
            var val=msg[3];
            ["audioIn"++lr,key,val].postln;
            syns.at("audioIn"++lr).set(key,val);
        });

        this.addCommand("padfx_set","sf",{ arg msg;
            var key=msg[1];
            var val=msg[2];
            ["padFx: putting",key,val].postln;
            syns.at("reverb").set(key,val);
        });

        this.addCommand("slice_off","s",{ arg msg;
            var id=msg[1];
            if (syns.at(id).notNil,{
                if (syns.at(id).isRunning,{
                    syns.at(id).set(\gate,0);
                });
            });
        });

        this.addCommand("slice_on","ssfffffffffffffffff",{ arg msg;
            var id=msg[1];
            var filename=msg[2];
            var db=msg[3];
            var db_add=msg[4];
            var pan=msg[5];
            var rate=msg[6];
            var pitch=msg[7];
            var pos=msg[8];
            var duration_slice=msg[9];
            var duration_total=msg[10];
            var retrig=msg[11];
            var gate=msg[12];
            var filter=msg[13];
            var decimate=msg[14];
            var compressible=msg[15];
            var compressing=msg[16];
            var send_pos=msg[17];
            var attack=msg[18];
            var release=msg[19];
            var db_first=db+db_add;
            if (retrig>0,{
                db_first=db;
            });
            if (bufs.at(filename).notNil,{
                if (syns.at(id).notNil,{
                    if (syns.at(id).isRunning,{
                        syns.at(id).set(\gate,0);
                    });
                });
                syns.put(id,Synth.new("slice"++bufs.at(filename).numChannels, [
                    out: buses.at("busCompressible"),
                    outsc: buses.at("busCompressing"),
                    outnsc: buses.at("busNotCompressible"),
                    outreverb: buses.at("busReverb"),
                    compressible: compressible,
                    compressing: compressing,
                    buf: bufs.at(filename),
                    attack: attack,
                    release: release,
                    amp: db_first.dbamp,
                    filter: filter,
                    rate: rate*pitch.midiratio,
                    pos: pos,
                    duration: (duration_slice * gate / (retrig + 1)),
                    decimate: decimate,
                    send_pos: send_pos,
                ], syns.at("reverb"), \addBefore));
                if (retrig>0,{
                    Routine {
                        (retrig).do{ arg i;
                            (duration_total/ (retrig+1) ).wait;
                            syns.put(id,Synth.new("slice"++bufs.at(filename).numChannels, [
                                out: buses.at("busCompressible"),
                                outsc: buses.at("busCompressing"),
                                outnsc: buses.at("busNotCompressible"),
                                outreverb: buses.at("busReverb"),
                                compressible: compressible,
                                compressing: compressing,
                                buf: bufs.at(filename),
                                attack: attack,
                                release: release,
                                amp: (db+(db_add*(i+1))).dbamp,
                                filter: filter,
                                rate: rate*((pitch.sign)*(i+1)+pitch).midiratio,
                                pos: pos,
                                duration: duration_slice * gate / (retrig + 1),
                                decimate: decimate,
                                send_pos: send_pos,
                            ], syns.at("reverb"), \addBefore));
                        };
                        NodeWatcher.register(syns.at(id));
                    }.play;
                 },{ 
                    NodeWatcher.register(syns.at(id));
                });
            });
        });

        this.addCommand("melodic_off","s",{ arg msg;
            var id=msg[1];
            ["melodic_off",id].postln;
            if (syns.at(id).notNil,{
                if (syns.at(id).isRunning,{
                    ["gating off"].postln;
                    syns.at(id).set(\gate,0);
                });
            });            
        });

        this.addCommand("melodic_on","ssfffffffffffffff",{ arg msg;
            var id=msg[1];
            var filename=msg[2];
            var db=msg[3];
            var db_add=msg[4];
            var pan=msg[5];
            var pitch=msg[6];
            var sampleStart=msg[7];
            var sampleIn=msg[8];
            var sampleOut=msg[9];
            var sampleEnd=msg[10];
            var duration=msg[11];
            var filter=msg[12];
            var gate=msg[13];
            var retrig=msg[14];
            var compressible=msg[15];
            var compressing=msg[16];
            var watch=msg[17];
            var db_first=db+db_add;
            if (retrig>0,{
                db_first=db;
            });
            if (bufs.at(filename).notNil,{
                var buf=bufs.at(filename);
                if (syns.at(id).notNil,{
                    if (syns.at(id).isRunning,{
                        syns.at(id).set(\gate,0);
                    });
                });
                syns.put(id,Synth.new("playerInOut"++buf.numChannels, [
                    out: buses.at("busCompressible"),
                    outsc: buses.at("busCompressing"),
                    outnsc: buses.at("busNotCompressible"),
                    outreverb: buses.at("busReverb"),
                    compressible: compressible,
                    compressing: compressing,
                    buf: buf,
                    amp: db_first.dbamp,
                    pan: pan,
                    filter: filter,
                    pitch: pitch,
                    sampleStart: sampleStart,
                    sampleIn: sampleIn,
                    sampleOut: sampleOut,
                    sampleEnd: sampleEnd,
                    duration: (duration * gate / (retrig + 1)),
                    watch: watch,
                ], syns.at("reverb"), \addBefore));
                if (retrig>0,{
                    Routine {
                        (retrig).do{ arg i;
                            (duration/ (retrig+1) ).wait;
                            syns.put(id,Synth.new("playerInOut"++buf.numChannels, [
                                out: buses.at("busCompressible"),
                                outsc: buses.at("busCompressing"),
                                outnsc: buses.at("busNotCompressible"),
                                outreverb: buses.at("busReverb"),
                                compressible: compressible,
                                compressing: compressing,
                                buf: buf,
                                amp: (db+(db_add*(i+1))).dbamp,
                                pan: pan,
                                filter: filter,
                                pitch: pitch,
                                sampleStart: sampleStart,
                                sampleIn: sampleIn,
                                sampleOut: sampleOut,
                                sampleEnd: sampleEnd,
                                duration: (duration * gate / (retrig + 1)),
                                watch: watch,
                            ], syns.at("reverb"), \addBefore));
                        };
                        NodeWatcher.register(syns.at(id));
                    }.play;
                 },{ 
                    NodeWatcher.register(syns.at(id));
                });
            });
        });


        this.addCommand("kick","fffffffffff",{arg msg;
            var basefreq=msg[1];
            var ratio=msg[2];
            var sweeptime=msg[3];
            var preamp=msg[4];
            var amp=msg[5].dbamp;
            var decay1=msg[6];
            var decay1L=msg[7];
            var decay2=msg[8];
            var clicky=msg[9];
            var compressing=msg[10];
            var compressible=msg[11];
            Synth.new("kick",[
                basefreq: basefreq,
                ratio: ratio,
                sweeptime: sweeptime,
                preamp: preamp,
                amp: amp,
                decay1: decay1,
                decay1L: decay1L,
                decay2: decay2,
                clicky: clicky,
                out: buses.at("busCompressible"),
                outsc: buses.at("busCompressing"),
                outnsc: buses.at("busNotCompressible"),
                outreverb: buses.at("busReverb"),
                compressible: compressible,
                compressing: compressing,
            ],syns.at("main"),\addBefore).onFree({"freed!"});
        });


        this.addCommand("note_on","fffff",{ arg msg;
            var note=msg[1];
            var amp=msg[2].dbamp;
            var attack=msg[3];
            var release=msg[4];
            var duration=msg[5];
            2.do{ arg i;
                var id=note.asString++"_"++i;
                if (syns.at(id).notNil,{
                    if (syns.at(id).isRunning,{
                        syns.at(id).set(\gate,0);
                    });
                });
                syns.put(id,Synth.new("pad"++i, [
                    freq: note.midicps, 
                    amp: amp,
                    attack: attack,
                    release: release,
                    duration: duration,
                    out: buses.at("busReverb"),
                ],
                syns.at("reverb"),\addBefore));
                NodeWatcher.register(syns.at(id));
            };
        });

        this.addCommand("note_off","f",{ arg msg;
            var note=msg[1];
            2.do{ arg i;
                var id=note.asString++"_"++i;
                if (syns.at(id).notNil,{
                    if (syns.at(id).isRunning,{
                        syns.at(id).set(\gate,0);
                    });
                });
            };
        });

        this.addCommand("load_buffer","s",{ arg msg;
            var id=msg[1];
            Buffer.read(context.server, id, action: {arg buf;
                ["loaded"+id].postln;
                bufs.put(id,buf);
            });
        });

        this.addCommand("audition_off","", { arg msg;
            if (syns.at("audition").notNil,{
                if (syns.at("audition").isRunning,{
                    syns.at("audition").set(\t_free,1);
                });
            });
        });


        this.addCommand("audition_on","sff", { arg msg;
            var server=context.server;
            var dontLoad=false;
            if (bufs.at("audition").notNil,{
                dontLoad=bufs.at("audition").path==msg[1];
                if (syns.at("audition").notNil,{
                    if (syns.at("audition").isRunning,{
                        syns.at("audition").set(\t_free,1);
                    });
                });
            });
            if (dontLoad==true,{
                syns.put("audition",Synth.head(server,"playerOneShot"++bufs.at("audition").numChannels,[\bufnum,bufs.at("audition"),\sampleStart,msg[2],\sampleEnd,msg[3],\watch,15]));
                NodeWatcher.register(syns.at("audition"));
            },{
                Buffer.read(server,msg[1],action:{ arg buf;
                    postln("loaded "++msg[1]++"into buf "++buf.bufnum);
                    bufs.put("audition",buf);
                    syns.put("audition",Synth.head(server,"playerOneShot"++bufs.at("audition").numChannels,[\bufnum,bufs.at("audition"),\sampleStart,msg[2],\sampleEnd,msg[3],\watch,15]));
                    NodeWatcher.register(syns.at("audition"));
                });
            });
        });

        this.addCommand("mx","sffffffffff", { arg msg;
            var folder=msg[1].asString;
            var note=msg[2];
            var velocity=msg[3];
            var amp=msg[4];
            var pan=msg[5];
            var attack=msg[6];
            var release=msg[7];
            var duration=msg[8];
            var sendCompressible=msg[9];
            var sendCompressing=msg[10];
            var sendReverb=msg[11];
            mx.note(folder,note,velocity,amp,pan,attack,release,duration,sendCompressible,sendCompressing,sendReverb);
        });

        // ^ Zxcvbn specific

    }

    free {
        // Zxcvbn Specific v0.0.1
        bufs.keysValuesDo({ arg buf, val;
			val.free;
		});
        syns.keysValuesDo({ arg buf, val;
			val.free;
		});
        buses.keysValuesDo({ arg buf, val;
            val.free;
        });
        oscs.keysValuesDo({ arg buf, val;
            val.free;
        });
        // ^ Zxcvbn specific
    }
}
