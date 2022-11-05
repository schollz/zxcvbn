Ouroboro {
	var server;
	var synRecord;
	var bufRecord;
	var xfaRecord;
	var actRecord;
	var fnXFader;
	var oscRecordInfo;
	var oscRecordDone;


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
		arg argServer;
		^super.new.init(argServer);
	}

	init {
		arg argServer;
		server=argServer;

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
				inputArray: input*EnvGen.ar(Env.new([0,1,1,0],[0.01,duration-0.02,0.02])),
				bufnum:bufnum,
				phase:pos,
			);
			SendReply.kr(Impulse.kr(10),"/recordingProgress",[id,pos/duration/server.sampleRate]);
			SendReply.kr(done,"/recordingProgress",[id,1.0]);
			SendReply.kr(done,"/recordingDone",[id]);
			FreeSelf.kr(done);
		}).send(server);

		oscRecordInfo = OSCFunc({ |msg|
			var id=msg[3];
			var progress=msg[4];
			// [id,progress].postln;
			NetAddr("127.0.0.1", 10111).sendMsg("recordingProgress",id,progress);
		}, '/recordingProgress');
		oscRecordDone = OSCFunc({ |msg|
			var id=msg[3];
			if (bufRecord.at(id).notNil,{
				xfaRecord.at(id).postln;
				if (xfaRecord.at(id)>0.0,{
					var crossfadeFrames=(xfaRecord.at(id)*server.sampleRate).round.asInteger;
					var frameOffset=0;
					["ouroboro: ",id,"xfading :",crossfadeFrames/server.sampleRate,"seconds"].postln;
					fnXFader.value(bufRecord.at(id),crossfadeFrames,-2,0,{ arg buf;
						["ouroboro: xfaded",buf].postln;
						actRecord.at(id).(buf);
					});
				},{
					actRecord.at(id).(bufRecord.at(id));
				});
			},{
				"id empty?".postln;
			});
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
		if (synRecord.at(id).notNil,{
			if (synRecord.at(id).isRunning,{
				synRecord.at(id).free;
			});
			synRecord.put(id,nil);
		});
		if (bufRecord.at(id).notNil,{
			bufRecord.at(id).free;
		});
	}

	record {
		arg argID,argSeconds, argCrossfade, argChannel, action;
		var id=argID;
		var frames=(server.sampleRate*(argSeconds+argCrossfade)).round.asInteger.postln;
		var stereo=(argChannel>1).asInteger;
		if (bufRecord.at(id).notNil,{
			bufRecord.at(id).free;
		});
		actRecord.put(id,action);
		xfaRecord.put(id,argCrossfade);
		bufRecord.put(id,Buffer.new(server, frames, stereo+1));
		server.sendBundle(nil,bufRecord.at(id).allocMsg);
		["ouroboro: buffer ready",bufRecord.at(id).duration,"seconds"].postln;
		// start the recording
		synRecord.put(id,Synth.new("defRecord"++stereo,
			[\id,id,\bufnum,bufRecord.at(id),\duration,bufRecord.at(id).duration,\ch,argChannel]
		));
		NodeWatcher.register(synRecord.at(id));
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
