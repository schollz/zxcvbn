// Engine_Zxcvbn

// Inherit methods from CroneEngine
Engine_Zxcvbn : CroneEngine {

    // Zxcvbn specific v0.1.0
    var buses;
    var syns;
    var bufs; 
    var oscs;
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

        context.server.sync;

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
            arg amp=0, buf=0, rate=1, pos=0, gate=1, duration=100000, pan=0, send_pos=0, filter=18000; 
            var snd;
            var snd_pos = Phasor.ar(
                trig: Impulse.kr(0),
                rate: rate * BufRateScale.ir(buf),
                resetPos: pos / BufDur.ir(buf) * BufFrames.ir(buf),
                end: BufFrames.ir(buf),
            );
            SendReply.kr(Impulse.kr(10)*send_pos,'/position',[snd_pos / BufFrames.ir(buf) * BufDur.ir(buf)]);
            snd = BufRd.ar(ch,buf,snd_pos,interpolation:4);
            snd = snd * Env.asr(0.01, 1, 0.01).ar(Done.freeSelf, gate * ToggleFF.kr(1-TDelay.kr(DC.kr(1),duration)) );
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
        }).send(context.server);
        });

        SynthDef(\sliceStretch,{
            var rate = BufRateScale.ir(\buf.kr(0)) * \rate.kr(1);
            var startPos = BufFrames.kr(\buf.kr(0)) * \slice.kr(0) / \slices.kr(16);
            var pos = Phasor.ar(
                rate: rate / LinLin.kr((6.283185307*\stretch.kr(1)).sin,-1,1,2,10),
                start: startPos,
                end: BufFrames.ir(\buf.kr(0)),
                resetPos: startPos,
            );
            var window = Phasor.ar(
                rate: rate,
                start: pos,
                end: pos + (LinExp.kr((6.283185307*\stretch.kr(1)).cos,-1,1,0.01,1)*44100),
                resetPos: pos,
            );
            var snd = BufRd.ar(2, \buf.kr(0), window, loop:1, interpolation:4);
            snd = snd * Env.linen(0, BufDur.kr(\buf.kr(0)) / \slices.kr(16), 0.01).ar;
            snd = snd * Env.asr(0.001, 1, 0.001).ar(Done.freeSelf, \gate.kr(1) * ToggleFF.kr(1-TDelay.kr(DC.kr(1),\duration.kr(10000))) );
            snd = snd * -6.dbamp ! 2;
            Out.ar(\out.kr(0),snd);
        }).send(context.server);

        SynthDef(\glitch,{
            arg amp=1.0;
            var snd;
            snd = SinOsc.ar((SinOsc.ar(\modFreq.kr(3240)) * Env.perc(0.01,2).kr * \index.kr(3000) + \carrierFreq.kr(1000)));
            snd = snd + PitchShift.ar(snd, Rand(0.03, 0.06), 2);
            snd = snd * Env.asr(0.001, 0.1, 0.01).ar(Done.freeSelf, \gate.kr(1) * ToggleFF.kr(1-TDelay.kr(DC.kr(1),\duration.kr(10000))) );
            snd = snd * -6.dbamp ! 2;
            snd = Pan2.ar(snd, \pan.kr(0));

            Out.ar(\out.kr(0),\compressible.kr(0)*snd*amp);
            Out.ar(\outsc.kr(0),\compressing.kr(0)*snd);
            Out.ar(\outnsc.kr(0),(1-\compressible.kr(0))*snd*amp);
        }).send(context.server);

        SynthDef(\bass,{
            arg freq=300,amp=1.0;
            var snd;
            snd = SinOsc.ar(Env([freq,freq/3,freq/5].cpsmidi, [0.1,3], -4).ar.midicps * [-0.1, 0, 0.1].midiratio);
            snd = snd * Env.perc(0, 5).ar;
            snd = snd + (snd * 4).fold2;
            snd = RLPF.ar(snd, 3000 * (1 + Env.perc(0.3, 1).ar), 0.3);
            snd = snd + (snd * 3).fold2;
            snd = RLPF.ar(snd, 1000 * (1 + Env.perc(0.1, 1).ar), 0.3);
            snd = snd + (snd * 3).fold2;
            snd = snd * Env.perc(0.001, 3.0).ar(Done.freeSelf);
            snd = snd * -10.dbamp;
            snd = snd * Env.asr(0.001, 0.1, 0.01).ar(Done.freeSelf, \gate.kr(1) * ToggleFF.kr(1-TDelay.kr(DC.kr(1),\duration.kr(10000))) );
            snd = Splay.ar(snd,0.3);
            Out.ar(\out.kr(0),\compressible.kr(0)*snd*amp);
            Out.ar(\outsc.kr(0),\compressing.kr(0)*snd);
            Out.ar(\outnsc.kr(0),(1-\compressible.kr(0))*snd*amp);
        }).send(context.server);


        SynthDef(\fx,{
            var snd;
            snd = In.ar(\in.kr(0), 2);
            snd = (snd * 30.dbamp).tanh * -10.dbamp;
            snd = SelectX.ar(\decimator.kr(0).lag(0.01), [snd, Latch.ar(snd, Impulse.ar(LFNoise2.kr(0.3).exprange(1000,16e3)))]);
            snd = SelectX.ar(\pitch1.kr(0).lag(0.01), [snd, PitchShift.ar(snd, 0.2, 2)]);
            snd = SelectX.ar(\pitch2.kr(0).lag(0.01), [snd, PitchShift.ar(snd, 0.03, 1.4)]);
            snd = BHiShelf.ar(BLowShelf.ar(snd, 500, 1, -10), 3000, 1, -10);
            snd = (snd * 10.dbamp).tanh * -10.dbamp;
            snd = BHiShelf.ar(BLowShelf.ar(snd, 500, 1, 10), 3000, 1, 10);
            snd = snd * -20.dbamp;
            snd = RLPF.ar(snd,LinExp.kr(\filter.kr(1).lag(1)+0.01,0.01,1,100,16000),0.707);
            snd = CompanderD.ar(snd);
            //snd = LPF.ar(snd,MouseX.kr(100,20000,1));
            Out.ar(\out.kr(0), snd);
        }).send(context.server);


        context.server.sync;
        buses.put("busIn",Bus.audio(s,2));
        buses.put("busInNSC",Bus.audio(s,2));
        buses.put("busSC",Bus.audio(s,2));
        buses.put("padFx",Bus.audio(s,2));
        context.server.sync;
        syns.put("main",Synth.new(\main,[\outBus,0,\sidechain_mult,8,\inBus,buses.at("busIn"),\inBusNSC,buses.at("busInNSC"),\inSC,buses.at("busSC")]));
        NodeWatcher.register(syns.at("main"));
        context.server.sync;
        syns.put("padFx", Synth.new(\padFx, [
            out: buses.at("busIn"),
            outsc: buses.at("busSC"),
            outnsc: buses.at("busInNSC"),
            compressible: 1,
            compressing: 0,
            in: buses.at("padFx"), gate: 0], syns.at("main"), \addBefore));
        NodeWatcher.register(syns.at("padFx"));
        context.server.sync;

        syns.put("audioInL",Synth.new("defAudioIn",[ch:0,
            out: buses.at("busIn"),
            outsc: buses.at("busSC"),
            outnsc: buses.at("busInNSC"),
            compressible: 0,
            compressing: 0,
            pan:-1], syns.at("main"), \addBefore));
        syns.put("audioInR",Synth.new("defAudioIn",[ch:1,
            out: buses.at("busIn"),
            outsc: buses.at("busSC"),
            outnsc: buses.at("busInNSC"),
            compressible: 0,
            compressing: 0,
            pan:1], syns.at("main"), \addBefore));
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
            syns.at("audioIn"++lr).set(key,val);
        });

        this.addCommand("padfx_set","sf",{ arg msg;
            var key=msg[1];
            var val=msg[2];
            ["padFx: putting",key,val].postln;
            syns.at("padFx").set(key,val);
        });

        this.addCommand("slice_off","s",{ arg msg;
            var id=msg[1];
            if (syns.at(id).notNil,{
                if (syns.at(id).isRunning,{
                    syns.at(id).set(\gate,0);
                });
            });
        });

        this.addCommand("slice_on","ssfffffffffffffff",{ arg msg;
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
            if (bufs.at(filename).notNil,{
                if (syns.at(id).notNil,{
                    if (syns.at(id).isRunning,{
                        syns.at(id).set(\gate,0);
                    });
                });
                syns.put(id,Synth.new("slice"++bufs.at(filename).numChannels, [
                    out: buses.at("busIn"),
                    outsc: buses.at("busSC"),
                    outnsc: buses.at("busInNSC"),
                    compressible: compressible,
                    compressing: compressing,
                    buf: bufs.at(filename),
                    amp: (db+db_add).dbamp,
                    filter: filter,
                    rate: rate*pitch.midiratio,
                    pos: pos,
                    duration: (duration_slice * gate / (retrig + 1)),
                    decimate: decimate,
                    send_pos: send_pos,
                ], syns.at("main"), \addBefore));
                if (retrig>0,{
                    Routine {
                        (retrig).do{ arg i;
                            (duration_total/ (retrig+1) ).wait;
                            syns.put(id,Synth.new("slice"++bufs.at(filename).numChannels, [
                                out: buses.at("busIn"),
                                outsc: buses.at("busSC"),
                                outnsc: buses.at("busInNSC"),
                                compressible: compressible,
                                compressing: compressing,
                                buf: bufs.at(filename),
                                amp: (db+(db_add*(i+1))).dbamp,
                                filter: filter,
                                rate: rate*((pitch.sign)*(i+1)+pitch).midiratio,
                                pos: pos,
                                duration: duration_slice * gate / (retrig + 1),
                                decimate: decimate,
                                send_pos: send_pos,
                            ], syns.at("main"), \addBefore));
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
            if (bufs.at(filename).notNil,{
                var buf=bufs.at(filename);
                if (syns.at(id).notNil,{
                    if (syns.at(id).isRunning,{
                        syns.at(id).set(\gate,0);
                    });
                });
                syns.put(id,Synth.new("playerInOut"++buf.numChannels, [
                    out: buses.at("busIn"),
                    outsc: buses.at("busSC"),
                    outnsc: buses.at("busInNSC"),
                    compressible: compressible,
                    compressing: compressing,
                    buf: buf,
                    amp: (db+db_add).dbamp,
                    pan: pan,
                    filter: filter,
                    pitch: pitch,
                    sampleStart: sampleStart,
                    sampleIn: sampleIn,
                    sampleOut: sampleOut,
                    sampleEnd: sampleEnd,
                    duration: (duration * gate / (retrig + 1)),
                    watch: watch,
                ], syns.at("main"), \addBefore));
                if (retrig>0,{
                    Routine {
                        (retrig).do{ arg i;
                            (duration/ (retrig+1) ).wait;
                            syns.put(id,Synth.new("playerInOut"++buf.numChannels, [
                                out: buses.at("busIn"),
                                outsc: buses.at("busSC"),
                                outnsc: buses.at("busInNSC"),
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
                            ], syns.at("main"), \addBefore));
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
                out: buses.at("busIn"),
                outsc: buses.at("busSC"),
                outnsc: buses.at("busInNSC"),
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
                    out: buses.at("padFx"),
                ],
                syns.at("padFx"),\addBefore));
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

        this.addCommand("glitch","f",{ arg msg;
            var duration=msg[1];
            syns.put("glitch",Synth.new(\glitch, [
                modFreq: exprand(100,3000),
                carrierFreq: exprand(100, 3000),
                index: rrand(100,8000),
                pan: rrand(-0.9,0.9),
                duration: duration,
                out: buses.at("busIn"),
                outsc: buses.at("busSC"),
                outnsc: buses.at("busInNSC"),
            ],syns.at("main"),\addBefore));
        });
        
        this.addCommand("bass","ff",{ arg msg;
            var freq=msg[1].midicps;
            var duration=msg[2];
            syns.put("bass",Synth.new(\bass, [
                freq: freq,
                pan: rrand(-0.9,0.9),
                duration: duration,
                out: buses.at("busIn"),
                outsc: buses.at("busSC"),
                outnsc: buses.at("busInNSC"),
            ],syns.at("main"),\addBefore));
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
