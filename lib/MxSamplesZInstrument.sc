MxSamplesZInstrument {

    var server;

    var <folder;
    var maxSamples;

    var <noteNumbers;
    var <noteDynamics;
    var <noteRoundRobins;

    var <buf;
    var bufUsed;
    var syn;

    var busCompressible;
    var busNotCompressible;
    var busCompressing;
    var busReverb;
    var busDelay;
    var busTape;

    *new {
        arg serverName,folderToSamples,numberMaxSamples,argBusCompressible,argBusNotCompressible,argBusCompressing,argBusReverb,argBusTape,argBusDelay;
        ^super.new.init(serverName,folderToSamples,numberMaxSamples,argBusCompressible,argBusNotCompressible,argBusCompressing,argBusReverb,argBusTape,argBusDelay);
    }

    init {
        arg serverName,folderToSamples,numberMaxSamples,argBusCompressible,argBusNotCompressible,argBusCompressing,argBusReverb,argBusTape,argBusDelay;

        server=serverName;
        folder=folderToSamples;
        maxSamples=numberMaxSamples;
        busCompressible=argBusCompressible;
        busNotCompressible=argBusNotCompressible;
        busCompressing=argBusCompressing;
        busReverb=argBusReverb;
        busTape=argBusTape;
        busDelay=argBusDelay;

        buf=Dictionary.new();
        bufUsed=Dictionary.new();
        syn=Dictionary.new();
        noteDynamics=Dictionary.new();
        noteRoundRobins=Dictionary.new();
        noteNumbers=Array.new(128);

        PathName.new(folder).entries.do({ arg v;
            var fileSplit=v.fileName.split($.);
            var note,dyn,dyns,rr,rel;
            if (fileSplit.last=="wav",{
                if (fileSplit.size==6,{
                    note=fileSplit[0].asInteger;
                    dyn=fileSplit[1].asInteger;
                    dyns=fileSplit[2].asInteger;
                    rr=fileSplit[3].asInteger;
                    rel=fileSplit[4].asInteger;
                    if (rel==0,{
                        if (noteDynamics.at(note).isNil,{
                            noteDynamics.put(note,dyns);
                            noteNumbers.add(note);
                        });
                        if (noteRoundRobins.at(note.asString++"."++dyn.asString).isNil,{
                            noteRoundRobins.put(note.asString++"."++dyn.asString,rr);
                        },{
                            if (rr>noteRoundRobins.at(note.asString++"."++dyn.asString),{
                                noteRoundRobins.put(note.asString++"."++dyn.asString,rr);
                            });
                        });
                    });
                });
            });
        });

        noteNumbers=noteNumbers.sort;


        SynthDef("playx2",{
            arg pan=0,amp=1.0,
            buf1,buf2,buf1mix=1,
            t_trig=1,rate=1,
            attack=0.01,decay=0.1,sustain=1.0,release=0.2,gate=1,duration=30,
            compressingBus=0,compressibleBus=0,notCompressibleBus=0,reverbBus=0,
            sendCompressible=0,sendCompressing=0,sendReverb=0,tapeBus,sendTape=0,delayBus,sendDelay=0,
            startPos=0;
            var snd,snd2;
            var frames1=BufFrames.ir(buf1);
            var frames2=BufFrames.ir(buf2);
            rate=rate*BufRateScale.ir(buf1);
            snd=PlayBuf.ar(2,buf1,rate,t_trig,startPos:startPos*frames1,doneAction:Select.kr(frames1>frames2,[0,2]));
            snd2=PlayBuf.ar(2,buf2,rate,t_trig,startPos:startPos*frames2,doneAction:Select.kr(frames2>frames1,[0,2]));
            snd=(buf1mix*snd)+((1-buf1mix)*snd2);//SelectX.ar(buf1mix,[snd2,snd]);
            snd=snd*EnvGen.ar(Env.asr(attack,sustain,release),gate*ToggleFF.kr(1-TDelay.kr(DC.kr(1),duration)),doneAction:2);
            snd=Balance2.ar(snd[0],snd[1],pan,amp);
            snd=snd/4; // assume ~ 4 note polyphony so reduce max volume
            Out.ar(compressibleBus,sendCompressible*snd*(1-sendReverb));
            Out.ar(compressingBus,sendCompressing*snd);
            Out.ar(notCompressibleBus,(1-sendCompressible)*snd*(1-sendReverb));
            Out.ar(reverbBus,sendReverb*snd);
            Out.ar(tapeBus,sendTape*snd);
            Out.ar(delayBus,sendDelay*snd);
        }).send(server);

        SynthDef("playx1",{
            arg pan=0,amp=1.0,
            buf1,buf2,buf1mix=1,
            t_trig=1,rate=1,
            attack=0.01,decay=0.1,sustain=1.0,release=0.2,gate=1,duration=30,
            compressingBus=0,compressibleBus=0,notCompressibleBus=0,reverbBus=0,
            sendCompressible=0,sendCompressing=0,sendReverb=0,tapeBus,sendTape=0,delayBus,sendDelay=0,
            startPos=0;
            var snd,snd2;
            var frames1=BufFrames.ir(buf1);
            var frames2=BufFrames.ir(buf2);
            rate=rate*BufRateScale.ir(buf1);
            snd=PlayBuf.ar(1,buf1,rate,t_trig,startPos:startPos*frames1,doneAction:Select.kr(frames1>frames2,[0,2]));
            snd2=PlayBuf.ar(1,buf2,rate,t_trig,startPos:startPos*frames2,doneAction:Select.kr(frames2>frames1,[0,2]));
            snd=SelectX.ar(buf1mix,[snd2,snd]);
            snd=snd*EnvGen.ar(Env.asr(attack,sustain,release),gate*ToggleFF.kr(1-TDelay.kr(DC.kr(1),duration)),doneAction:2);
            snd=Pan2.ar(snd,pan,amp);
            snd=snd/4; // assume ~ 4 note polyphony so reduce max volume
            Out.ar(compressibleBus,sendCompressible*snd*(1-sendReverb));
            Out.ar(compressingBus,sendCompressing*snd);
            Out.ar(notCompressibleBus,(1-sendCompressible)*snd*(1-sendReverb));
            Out.ar(reverbBus,sendReverb*snd);
            Out.ar(tapeBus,sendTape*snd);
            Out.ar(delayBus,sendDelay*snd);
        }).send(server);

    }


    garbageCollect {
        var ct=SystemClock.seconds;
        var bufUsedOrdered=Dictionary();
        var deleted=0;
        var files;
        bufUsed.keysValuesDo({ arg k,v;
            bufUsedOrdered[v]=k;
        });
        files=bufUsedOrdered.atAll(bufUsedOrdered.order);
        if (files.notNil,{
            files.reverse.do({arg k,i;
                if (deleted<10,{
                    if (buf.at(k).notNil,{
                        var bnum=buf.at(k).bufnum;
                        var doRemove=false;
                        if (bufUsed.at(k).notNil,{
                            if (ct-bufUsed.at(k)>20,{
                                doRemove=true;
                            });
                        });
                        if (doRemove==true,{
                            buf.at(k).free;
                            buf.removeAt(k);
                            bufUsed.removeAt(k);
                            deleted=deleted+1;
                            ("unloaded buffer file "++k).postln;
                        });
                    });
                });
            });
        });

    }

    noteOn {
        arg note,velocity,amp,pan,attack,release,duration,sendCompressible,sendCompressing,sendReverb,sendTape,sendDelay;
        var noteOriginal=note;
        var noteLoaded=note;
        var noteClosest=noteNumbers[noteNumbers.indexIn(note)];
        var noteClosestLoaded;
        var rate=1.0;
        var rateLoaded=1.0;
        var buf1mix=1.0;
        var file1,file2,fileLoaded;
        var velIndex=0;
        var velIndices;
        var vels;
        var dyns;
        var noteNumbersLoadedDict=Dictionary.new();
        var notNumbersLoaded=Array.new(128);

        buf.keysValuesDo({arg k,v;
            var fileSplit=k.split($.);
            var note=fileSplit[0];
            var dyn=fileSplit[1];
            noteNumbersLoadedDict.put((note++"."++dyn).asFloat,k);
            notNumbersLoaded.add((note++"."++dyn).asFloat);
        });
        notNumbersLoaded=notNumbersLoaded.sort;

        // first determine the rate to get the right note
        while ({note<noteClosest},{
            note=note+12;
            rate=rate*0.5;
        });

        while ({note-noteClosest>11},{
            note=note-12;
            rate=rate*2;
        });
        rate=rate*Scale.chromatic.ratios[note-noteClosest];

        // determine the number of dynamics
        dyns=noteDynamics.at(noteClosest);
        if (dyns>1,{
            velIndices=Array.fill(dyns,{ arg i;
                i*128/(dyns-1)
            });
            velIndex=velIndices.indexOfGreaterThan(velocity)-1;
        });

        // determine the closest loaded note, in case both files are not available
        noteClosestLoaded=notNumbersLoaded[notNumbersLoaded.indexIn(note+((velIndex+1)/10))];
        if (noteClosestLoaded.notNil,{
            fileLoaded=noteNumbersLoadedDict[noteClosestLoaded];
            noteClosestLoaded=noteClosestLoaded.asInteger;
            while ({noteLoaded<noteClosestLoaded},{
                noteLoaded=noteLoaded+12;
                rateLoaded=rateLoaded*0.5;
            });
            while ({noteLoaded-noteClosestLoaded>11},{
                noteLoaded=noteLoaded-12;
                rateLoaded=rateLoaded*2;
            });
            rateLoaded=rateLoaded*Scale.chromatic.ratios[noteLoaded-noteClosestLoaded];
            [fileLoaded,rateLoaded].postln;
        });


        // determine file 1 and 2 interpolation
        file1=noteClosest.asInteger.asString++".";
        file2=noteClosest.asInteger.asString++".";
        if (dyns<2,{
            // simple playback using amp
            file1=file1++"1.1.";
            file2=file2++"1.1.";
            // add round robin
            file1=file1++(noteRoundRobins.at(noteClosest.asString++".1").rand+1).asString++".0.wav";
            file2=file2++(noteRoundRobins.at(noteClosest.asString++".1").rand+1).asString++".0.wav";
        },{
            var rr1,rr2;
            // gather the velocity indices that are available
            // TODO: make this specific to a single note?
            vels=[velIndices[velIndex],velIndices[velIndex+1]];
            buf1mix=(1-((velocity-vels[0])/(vels[1]-vels[0])));
            // add dynamic
            file1=file1++(velIndex+1).asInteger.asString++".";
            file2=file2++(velIndex+2).asInteger.asString++".";
            // add dynamic max
            file1=file1++dyns.asString++".";
            file2=file2++dyns.asString++".";
            // add round robin
            rr1=noteRoundRobins.at(noteClosest.asString++"."++(velIndex+1).asString);
            if (rr1.isNil,{
                rr1=1;
            });
            file1=file1++(rr1.rand+1).asString++".0.wav";
            rr2=noteRoundRobins.at(noteClosest.asString++"."++(velIndex+2).asString);
            if (rr2.isNil,{
                rr2=1;
            });
            file2=file2++(rr2.rand+1).asString++".0.wav";           
        });


        // check if buffer is loaded
        ["checking",file1,file2].postln;
        if (buf.at(file1).isNil,{
            if (buf.at(file2).isNil,{
                // no file1 and no file2
                if (fileLoaded.notNil,{
                    "playing without 1+2".postln;
                    this.doPlay(noteOriginal,fileLoaded,fileLoaded,buf1mix,rateLoaded,
                        amp,pan,attack,release,duration,sendCompressible,sendCompressing,sendReverb,sendTape,sendDelay);
                });
                Buffer.read(server,PathName(folder+/+file2).fullPath,action:{ arg b1;
                    b1.postln;
                    buf.put(file2.asString,b1);
                    bufUsed.put(file2,SystemClock.seconds);
                });
            },{
                // only have buf2
                "playing without 1".postln;
                if (file2.notNil,{
                    this.doPlay(noteOriginal,file2,file2,buf1mix,rate,
                        amp,pan,attack,release,duration,sendCompressible,sendCompressing,sendReverb,sendTape,sendDelay);
                });
            });
            Buffer.read(server,PathName(folder+/+file1).fullPath,action:{ arg b1;
                b1.postln;
                buf.put(file1,b1);
                bufUsed.put(file1,SystemClock.seconds);
            });
        },{
            if (buf.at(file2).isNil,{
                // only have buf1
                "playing without 2".postln;
                this.doPlay(noteOriginal,file1,file1,buf1mix,rate, 
                    amp,pan,attack,release,duration,sendCompressible,sendCompressing,sendReverb,sendTape,sendDelay);
                Buffer.read(server,PathName(folder+/+file2).fullPath,action:{ arg b1;
                    b1.postln;
                    buf.put(file2,b1);
                    bufUsed.put(file2,SystemClock.seconds);
                });
            },{
                // play original files!
                "playing without NONE!".postln;
                this.doPlay(noteOriginal,file1,file2,buf1mix,rate, 
                    amp,pan,attack,release,duration,sendCompressible,sendCompressing,sendReverb,sendTape,sendDelay);
            });
        });

    }


    doPlay {
        arg note,file1,file2,buf1mix,rate,amp,pan,attack,release,duration,sendCompressible,sendCompressing,sendReverb,sendTape,sendDelay;
        var notename=1000000.rand;
        var node;
        [notename,note,amp,file1,file2,buf1mix,rate].postln;
        // check if sound is loaded and unload it
        if (syn.at(note).isNil,{
            syn.put(note,Dictionary.new());
        });
        bufUsed.put(file1,SystemClock.seconds);
        bufUsed.put(file2,SystemClock.seconds);
        ["playx"++buf.at(file1).numChannels].postln;
        node=Synth.head(server,"playx"++buf.at(file1).numChannels,[
            \compressingBus,busCompressing,
            \compressibleBus,busCompressible,
            \notCompressibleBus,busNotCompressible,
            \tapeBus,busTape,
            \delayBus,busDelay,
            \sendCompressible,sendCompressible,
            \sendCompressing,sendCompressing,
            \sendReverb,sendReverb,
            \sendTape,sendTape,
            \sendDelay,sendDelay,
            \reverbBus,busReverb,
            \amp,amp,
            \pan,pan,
            \attack,attack,
            \release,release,
            \duration,duration,
            \buf1,buf.at(file1),
            \buf2,buf.at(file2),
            \buf1mix,buf1mix,
            \rate,rate,
        ]).onFree({
            ["freed ",node].postln;
            syn.at(note).removeAt(notename);
        });
        syn.at(note).put(notename,node);
        NodeWatcher.register(node,true);
    }


    free {
        syn.keysValuesDo({arg note,v1;
            syn.at(note).keysValuesDo({ arg k,v;
                v.free;
            });
        });
        buf.keysValuesDo({ arg name,b;
            b.free;
        });
        bufUsed.free;
    }

}
