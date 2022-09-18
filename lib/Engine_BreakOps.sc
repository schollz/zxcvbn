// Engine_BreakOps

// Inherit methods from CroneEngine
Engine_BreakOps : CroneEngine {

    // BreakOps specific v0.1.0
    var buses;
    var syns;
    var bufs; 
    var oscs;
    // BreakOps ^

    *new { arg context, doneCallback;
        ^super.new(context, doneCallback);
    }

    alloc {
        // BreakOps specific v0.0.1
        var s=context.server;

        buses = Dictionary.new();
        syns = Dictionary.new();
        bufs = Dictionary.new();
        oscs = Dictionary.new();

        oscs.put("position",OSCFunc({ |msg| NetAddr("127.0.0.1", 10111).sendMsg("progress",msg[3],msg[3]); }, '/position'));

        context.server.sync;

        SynthDef(\main, {
            var in1=In.ar(\in1.kr(1),2); // drums
            var in2=In.ar(\in2.kr(1),2); // pad
            var snd=Compander.ar(in2,in1*8,0.1,1,0.1,0.01,0.01)+(in1);
            snd=Compander.ar(snd,snd,4,1,0.5,0.01,0.01);
            snd=LeakDC.ar(snd);
            Out.ar(\out.kr(0),snd);
        }).send(context.server);

        SynthDef(\pad0, {
            var snd;
            snd = Saw.ar(\freq.kr(440) * ((-3..3) * 0.05).midiratio * [1, 2, 1, 4, 1, 2, 1]);
            snd = RLPF.ar(snd, LFNoise2.kr(0.3 ! snd.size).linexp(-1, 1, 100, 8000), 0.3);
            snd = Splay.ar(snd);
            snd = snd * Env.asr(0.8, 1, 0.8).ar(Done.freeSelf, \gate.kr(1));
            snd = snd * -30.dbamp;
            Out.ar(\out.kr(0), snd);
        }).send(context.server);

        SynthDef(\pad1, {
            var snd;
            snd = Saw.ar(\freq.kr(440) * ((-3..3) * 0.05).midiratio * [1, 2, 1, 4, 1, 2, 1]);
            snd = Splay.ar(snd);
            snd = MoogFF.ar(snd, XLine.kr(100,rrand(6000,12000),8), 0);
            snd = snd * Env.asr(0.8, 1, 0.8).ar(Done.freeSelf, \gate.kr(1));
            snd = Balance2.ar(snd[0], snd[1], \pan.kr(0));
            snd = snd * -10.dbamp;
            Out.ar(\out.kr(0), snd);
        }).send(context.server);

        SynthDef(\pad2,{
            var snd;
            snd = CombC.ar(PinkNoise.ar * -10.dbamp, \freq.kr(440).reciprocal, \freq.kr(440).reciprocal, 2.0);
            snd = snd ! 2;
            snd = LeakDC.ar(snd);
            snd = snd * Env.asr(0.8, 1, 0.8).ar(Done.freeSelf, \gate.kr(1));
            snd = Balance2.ar(snd[0], snd[1], \pan.kr(0));
            snd = snd * -50.dbamp;
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
            ReplaceOut.ar(\out.kr(0), snd * -6.dbamp);
        }).send(context.server);

        SynthDef(\slice,{
            arg out=0, amp=0, buf=0, rate=1, pos=0, gate=1, duration=100000, send_pos=0; 
            var snd;
            var snd_pos = Phasor.ar(
                trig: Impulse.kr(0),
                rate: rate * BufRateScale.ir(buf),
                resetPos: pos / BufDur.ir(buf) * BufFrames.ir(buf),
                end: BufFrames.ir(buf),
            );
            SendReply.kr(Impulse.kr(10)*send_pos,'/position',[snd_pos / BufFrames.ir(buf) * BufDur.ir(buf)]);
            snd = BufRd.ar(2,buf,snd_pos,interpolation:4);
            snd = snd * Env.asr(0.001, 1, 0.001).ar(Done.freeSelf, gate * (1-TDelay.kr(Impulse.kr(0),duration)) );
            snd = snd * amp.dbamp;
            Out.ar(out,snd);
        }).send(context.server);

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
            snd = snd * Env.asr(0.001, 1, 0.001).ar(Done.freeSelf, \gate.kr(1) * (1-TDelay.kr(Impulse.kr(0),\duration.kr(100000))) );
            snd = snd * -6.dbamp ! 2;
            Out.ar(\out.kr(0),snd);
        }).send(context.server);

        SynthDef(\glitch,{
            var snd;
            snd = SinOsc.ar((SinOsc.ar(\modFreq.kr(3240)) * Env.perc(0.01,2).kr * \index.kr(3000) + \carrierFreq.kr(1000)));
            snd = snd + PitchShift.ar(snd, Rand(0.03, 0.06), 2);
            snd = snd * Env.asr(0.001, 0.1, 0.01).ar(Done.freeSelf, \gate.kr(1) * (1-TDelay.kr(Impulse.kr(0),\duration.kr(100000))) );
            snd = snd * -6.dbamp ! 2;
            snd = Pan2.ar(snd, \pan.kr(0));
            Out.ar(\out.kr(0),snd);
        }).send(context.server);

        SynthDef(\bass,{
            arg freq=300;
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
            snd = Splay.ar(snd,0.3);
            Out.ar(\out.kr(0),snd);
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
        buses.put("compressing",Bus.audio(s,2));
        buses.put("compressible",Bus.audio(s,2));
        buses.put("sliceFx",Bus.audio(s,2));
        buses.put("padFx",Bus.audio(s,2));
        context.server.sync;
        syns.put("main",Synth.new(\main,[\in1,buses.at("compressing"),\in2,buses.at("compressible")]));
        context.server.sync;
        syns.put("sliceFx",Synth.new(\fx, [\in, buses.at("sliceFx"), \out, buses.at("compressing")], syns.at("main"), \addBefore));
        context.server.sync;
        syns.put("padFx", Synth.new(\padFx, [in: buses.at("padFx"), out: buses.at("compressible"),  gate: 0], syns.at("main"), \addBefore));
        context.server.sync;

        this.addCommand("play","sffffffff",{ arg msg;
            var id=msg[1];
            var amp=msg[2].dbamp;
            var rate=msg[3];
            var pitch=msg[4];
            var pos=msg[5];
            var duration=msg[6]; // duration of the full slice
            var gate=msg[7]; // gate is between 0-1
            var retrig=msg[8];
            var send_pos=msg[9];
            if (bufs.at(id).notNil,{
                if (syns.at(id).notNil,{
                    if (syns.at(id).isRunning,{
                        syns.at(id).set(\gate,0);
                    });
                });
                syns.put(id,Synth.new(\slice, [
                    out: buses.at("sliceFx"),
                    buf: bufs.at(id),
                    amp: amp,
                    rate: rate*pitch.midiratio,
                    pos: pos,
                    duration: duration * gate / retrig,
                    send_pos: send_pos,
                ], syns.at("sliceFx"), \addBefore));
                Routine {
                    if (retrig>1,{
                        (retrig-1).do{ arg i;
                            (duration/retrig).wait;
                            syns.put(id,Synth.new(\slice, [
                                out: buses.at("sliceFx"),
                                buf: bufs.at(id),
                                amp: amp,
                                rate: rate*((pitch.sign)*(i+1)+pitch).midiratio,
                                pos: pos,
                                duration: duration * gate / retrig,
                                send_pos: send_pos,
                            ], syns.at("sliceFx"), \addBefore));
                        };
                    });
                    // the last node played gets watched
                    NodeWatcher.register(syns.at(id));
                }.play;
            });
        });


        this.addCommand("note_on","f",{ arg msg;
            var note=msg[1];
            2.do{ arg i;
                var id=note.asString++"_"++i;
                if (syns.at(id).notNil,{
                    if (syns.at(id).isRunning,{
                        syns.at(id).set(\gate,0);
                    });
                });
                syns.put(id,Synth.new("pad"++i, [
                    freq: note.midicps, 
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


        // ^ BreakOps specific

    }

    free {
        // BreakOps Specific v0.0.1
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
        // ^ BreakOps specific
    }
}