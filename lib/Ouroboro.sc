Ouroboro {
	var server;
	var synRecord;
	var bufRecord;
	var xfaRecord;
	var actRecord;
	var fnXFader;
	var oscRecordInfo;
	var oscRecordDone;
	var bus;


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
		arg argServer,argBus;
		^super.new.init(argServer,argBus);
	}

	init {
		arg argServer,argBus;
		server=argServer;
		bus=argBus;

		synRecord=Dictionary.new();
		bufRecord=Dictionary.new();
		xfaRecord=Dictionary.new();
		actRecord=Dictionary.new();


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
				inputArray: input*EnvGen.ar(Env.new([0,1,1,0],[0.01,duration-0.02,0.02])),
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
				inputArray: input*EnvGen.ar(Env.new([0,1,1,0],[0.005,duration-0.01,0.005])),
				bufnum:bufnum,
				phase:pos,
			);
			SendReply.kr(Impulse.kr(10),"/recordingProgress",[id,pos/duration/server.sampleRate]);
			SendReply.kr(done,"/recordingProgress",[id,1.0]);
			SendReply.kr(done,"/recordingDone",[id]);
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
				inputArray: input*EnvGen.ar(Env.new([0,1,1,0],[0.005,duration-0.01,0.005])),
				bufnum:bufnum,
				phase:pos,
			);
			SendReply.kr(Impulse.kr(10),"/recordingProgress",[id,pos/duration/server.sampleRate]);
			SendReply.kr(done,"/recordingProgress",[id,1.0]);
			SendReply.kr(done,"/recordingDone",[id]);
			FreeSelf.kr(done);
		}).send(server);

		oscRecordInfo = OSCFunc({ |msg|
			var id=msg[3].asInteger;
			var progress=msg[4];
			NetAddr("127.0.0.1", 10111).sendMsg("recordingProgress",id,progress);
		}, '/recordingProgress');
		oscRecordDone = OSCFunc({ |msg|
			var id=msg[3].asInteger;
			var buf1=id.asString++"_1";
			var buf2=id.asString++"_2";
			["ouroboro: recording done",id].postln;
			if (bufRecord.at(buf1).notNil,{
				bufRecord.at(buf1).write("/home/we/dust/buf1.aiff");
				xfaRecord.at(id).postln;
				if (xfaRecord.at(id)>0.0,{
					var crossfadeFrames=(xfaRecord.at(id)*server.sampleRate).round.asInteger;
					var frameOffset=0;
					["ouroboro: ",id,"xfading :",crossfadeFrames/server.sampleRate,"seconds"].postln;
					fnXFader.value(bufRecord.at(buf1),crossfadeFrames,-2,0,{ arg buf;
						["ouroboro: xfaded",buf].postln;
						if (bufRecord.at(buf2).notNil,{
							bufRecord.at(buf2).free;
						});
						bufRecord.put(buf2,buf);
						buf.write("/home/we/dust/buf2.aiff");
						actRecord.at(id).(buf);
					});
				},{
					actRecord.at(id).(bufRecord.at(id));
				});
			},{
				"id empty?".postln;
			});
			NetAddr("127.0.0.1", 10111).sendMsg("recordingDone",id,id);
		}, '/recordingDone');

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
		var buf1=id.asString++"_1";
		if (synRecord.at(id).notNil,{
			if (synRecord.at(id).isRunning,{
				synRecord.at(id).free;
			});
			synRecord.put(id,nil);
		});
		if (bufRecord.at(buf1).notNil,{
			bufRecord.at(buf1).free;
		});
	}

	record {
		arg argID,argSeconds, argCrossfade, argChannel, action1, action2;
		// argChannel 
		// 0 = left (record type 0)
		// 1 = right (record type 0)
		// 2 = stereo input (record type 1)
		// 3 = stereo bus (record type 2)
		var id=argID;
		var frames=(server.sampleRate*(argSeconds+argCrossfade)).round.asInteger.postln;
		var defRecordType=(argChannel>1).asInteger;
		var stereo=(argChannel>1).asInteger;
		var buf1=id.asString++"_1";
		if (bufRecord.at(buf1).notNil,{
			bufRecord.at(buf1).free;
		});
		if (argChannel>2,{
			defRecordType=2;
		});
		actRecord.put(id,action2);
		xfaRecord.put(id,argCrossfade);
		bufRecord.put(buf1,Buffer.new(server, frames, stereo+1));
		server.sendBundle(nil,bufRecord.at(buf1).allocMsg);
		["ouroboro: buffer ready",bufRecord.at(buf1).duration,"seconds"].postln;
		// start the recording
		synRecord.put(id,Synth.new("defRecord"++defRecordType,
			[\id,id,\bufnum,bufRecord.at(buf1),\duration,bufRecord.at(buf1).duration,\ch,argChannel,\busin,bus]
		));
		NodeWatcher.register(synRecord.at(id));
		action1.(bufRecord.at(buf1));
	}


	free {
		synRecord.keysValuesDo({ arg note, val;
			val.free;
		});
		bufRecord.keysValuesDo({ arg note, val;
			val.free;
		});
		oscRecordInfo.free;
		oscRecordDone.free;
	}
}
