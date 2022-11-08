Ouroboro {
	var server;
	var synRecord;
	var bu1Record;
	var bu2Record;
	var finRecord;
	var fnXFader;
	var oscRecordInfo;
	var oscRecordDone;
	var bus;
	var syn;


/*	(
		s.waitForBoot({
			Routine {
				"starting".postln;
				o=Ouroboro.new(s);
				1.wait;
				o.record(111,1,0.2,0,{
					arg buf;
					["DONE"+buf.duration].postln;
				});

			}.play;
		})
	)*/

	*new {
		arg argServer,argBus,argSyn;
		^super.new.init(argServer,argBus,argSyn);
	}

	init {
		arg argServer,argBus,argSyn;
		server=argServer;
		bus=argBus;
		syn=argSyn;

		synRecord=Array.newClear(11);
		bu1Record=Array.newClear(11);
		bu2Record=Array.newClear(11);
		finRecord=Array.newClear(11);


		SynthDef("defRecord0",{
			arg id, bufnum,duration,ch=0;
			var input=SoundIn.ar(ch);
			var done=TDelay.kr(Impulse.kr(0),duration);
			var pos=Phasor.ar(
				rate:1,
				start:0,
				end:28800000, // 10 minutes
			);
			BufWr.ar(
				inputArray: LeakDC.ar(input)*EnvGen.ar(Env.new([0,1,1,0],[0.005,duration-0.01,0.005])),
				bufnum:bufnum,
				phase:pos,
			);
			SendReply.kr(Impulse.kr(10),"/recordingProgress",[id,pos/duration/server.sampleRate]);
			SendReply.kr(done,"/recordingProgress",[id,1.0]);
			FreeSelf.kr(done);
		}).send(server);
		SynthDef("defRecord1",{
			arg id, bufnum,duration;
			var input=SoundIn.ar([0,1]);
			var done=TDelay.kr(Impulse.kr(0),duration);
			var pos=Phasor.ar(
				rate:1,
				start:0,
				end:28800000, // 10 minutes
			);
			BufWr.ar(
				inputArray: LeakDC.ar(input*2)*EnvGen.ar(Env.new([0,1,1,0],[0.005,duration-0.01,0.005])),
				bufnum:bufnum,
				phase:pos,
			);
			SendReply.kr(Impulse.kr(10),"/recordingProgress",[id,pos/duration/server.sampleRate]);
			SendReply.kr(done,"/recordingProgress",[id,1.0]);
			FreeSelf.kr(done);
		}).send(server);
		SynthDef("defRecord2",{
			arg id, bufnum,duration,busin;
			var input=In.ar(busin,2);
			var done=TDelay.kr(Impulse.kr(0),duration);
			var pos=Phasor.ar(
				rate:1,
				start:0,
				end:28800000, // 10 minutes
			);
			BufWr.ar(
				inputArray: LeakDC.ar(input)*EnvGen.ar(Env.new([0,1,1,0],[0.005,duration-0.01,0.005])),
				bufnum:bufnum,
				phase:pos,
			);
			SendReply.kr(Impulse.kr(10),"/recordingProgress",[id,pos/duration/server.sampleRate]);
			SendReply.kr(done,"/recordingProgress",[id,1.0]);
			FreeSelf.kr(done);
		}).send(server);

		oscRecordInfo = OSCFunc({ |msg|
			var id=msg[3].asInteger;
			var progress=msg[4];
			NetAddr("127.0.0.1", 10111).sendMsg("recordingProgress",id,progress);
		}, '/recordingProgress');


		// https://fredrikolofsson.com/f0blog/buffer-xfader/
		fnXFader ={|inBuffer, frames= 2, curve= -2, rotation=0, action|
			if(frames>inBuffer.numFrames, {
				"xfader: crossfade duration longer than half buffer - clipped.".warn;
			});
			frames= frames.min(inBuffer.numFrames.div(2)).round.asInteger;
			Buffer.alloc(inBuffer.server, inBuffer.numFrames-frames, inBuffer.numChannels, {|outBuffer|
				inBuffer.loadToFloatArray(action:{|arr|
					var interleavedFrames= frames*inBuffer.numChannels;
					var startArr= arr.copyRange(0, interleavedFrames-1);
					var endArr= arr.copyRange(arr.size-interleavedFrames, arr.size-1);
					var result= arr.copyRange(0, arr.size-1-interleavedFrames);
					var resultFinal= arr.copyRange(0, arr.size-1-interleavedFrames);
					interleavedFrames.do{|i|
						var fadeIn= i.lincurve(0, interleavedFrames-1, 0, 1, curve);
						var fadeOut= i.lincurve(0, interleavedFrames-1, 1, 0, 0-curve);
						result[i]= (startArr[i]*fadeIn)+(endArr[i]*fadeOut);
					};
					(arr.size-interleavedFrames).do{|i|
						var j=i+(rotation*inBuffer.numChannels);
						if (j>(arr.size-interleavedFrames-1),{
							j=j-(arr.size-interleavedFrames);
						});
						resultFinal[j]=result[i];
					};
					outBuffer.loadCollection(resultFinal, 0, action);
				});
			});
		};
	}


	stop {
		arg id;
		finRecord[id]=true;
		if (synRecord[id].notNil,{
			if (synRecord[id].isRunning,{
				synRecord[id].free;
			});
			synRecord[id]=nil;
		});
	}

	record {
		arg argID,argSeconds, argCrossfade, argChannel, action1, action2;
		// argChannel 
		// 0 = left (record type 0)
		// 1 = right (record type 0)
		// 2 = stereo input (record type 1)
		// 3 = stereo bus (record type 2)
		var id=argID.floor.asInteger;
		var frames=(server.sampleRate*(argSeconds+argCrossfade)).round.asInteger.postln;
		var defRecordType=(argChannel>1).asInteger;
		var stereo=(argChannel>1).asInteger;
		if (argChannel>2,{
			defRecordType=2;
		});
		finRecord[id]=false;
		if (bu1Record[id].notNil,{
			bu1Record[id].free;
		});
		bu1Record[id]=Buffer.new(server, frames, stereo+1);
		server.sendBundle(nil,bu1Record[id].allocMsg);
		["ouroboro: recording",id,"defRecord"++defRecordType,argSeconds+argCrossfade,"seconds"].postln;
		// start the recording
		synRecord[id]=Synth.new("defRecord"++defRecordType,
			[\id,id,\bufnum,bu1Record[id],\duration,argSeconds+argCrossfade,\ch,argChannel,\busin,bus],
			syn,\addBefore,
		).onFree({
			["ouroboro: recording done",id].postln;
			if (finRecord[id],{},{
				finRecord[id]=true;
				if (bu1Record[id].notNil,{
					["id found:",id].postln;
					bu1Record[id].write("/home/we/dust/buf1.aiff");
					if (argCrossfade>0,{
						var crossfadeFrames=(argCrossfade*server.sampleRate).round.asInteger;
						var frameOffset=0;
						["ouroboro: ",id,"xfading :",crossfadeFrames/server.sampleRate,"seconds"].postln;
						fnXFader.value(bu1Record[id],crossfadeFrames,-2,0,{ arg buf;
							["ouroboro: xfaded",buf].postln;
							if (bu2Record[id].notNil,{
								bu2Record[id].free;
								bu2Record[id]=nil;
							});
							bu2Record[id]=buf;
							bu2Record[id].write("/home/we/dust/buf2.aiff");
							action2.(buf);
						});
					},{
						action2.(bu1Record[id]);
					});
					["osc: sending recordingDone",id].postln;
					NetAddr("127.0.0.1", 10111).sendMsg("recordingDone",id,id);
				},{
					["id empty:",id].postln;
				});
			});
		});
		NodeWatcher.register(synRecord[id]);
		action1.(bu1Record[id]);
	}


	free {
		synRecord.do({ arg v,i;
			v.free;
		});
		bu1Record.do({ arg v,i;
			v.free;
		});
		bu2Record.do({ arg v,i;
			v.free;
		});
		oscRecordInfo.free;
		oscRecordDone.free;
		syn.free;
		bus.free;
	}
}
