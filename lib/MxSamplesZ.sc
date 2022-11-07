MxSamplesZ {

	var server;
	var maxSamples;

	var <ins;

	var busCompressible;
	var busNotCompressible;
	var busCompressing;
	var busReverb;
	var busTape;

	var garbageCollector;

	*new {
		arg serverName,numberMaxSamples,argBusCompressible,argBusNotCompressible,argBusCompressing,argBusReverb,argBusTape;
		^super.new.init(serverName,numberMaxSamples,argBusCompressible,argBusNotCompressible,argBusCompressing,argBusReverb,argBusTape);
	}

	init {
		arg serverName,numberMaxSamples,argBusCompressible,argBusNotCompressible,argBusCompressing,argBusReverb,argBusTape;
		server=serverName;
		maxSamples=numberMaxSamples;
		busCompressible=argBusCompressible;
		busNotCompressible=argBusNotCompressible;
		busCompressing=argBusCompressing;
		busReverb=argBusReverb;
		busTape=argBusTape;

		ins=Dictionary.new();

		// unload old buffers periodically
		garbageCollector=Routine {
			loop {
				var diskMB=0.0;
				ins.keysValuesDo({arg k1, val;
					val.buf.keysValuesDo({arg k,v;
						diskMB=diskMB+(v.numFrames*v.numChannels*4.0/1000000.0);
					});
				});
				if (diskMB>100.0,{
					("current mb usage: "++diskMB).postln;
					ins.keysValuesDo({arg k, val;
						val.garbageCollect;
					});	
					1.wait;
				},{
					3.wait;
				});
			}
		}.play;
	}

	note {
		arg folder,note,velocity,amp,pan,attack,release,duration,sendCompressible,sendCompressing,sendReverb,sendTape;
		if (ins.at(folder).isNil,{
			ins.put(folder,MxSamplesZInstrument(server,folder,maxSamples,busCompressible,busNotCompressible,busCompressing,busReverb,busTape));
		});
		ins.at(folder).noteOn(note,velocity,amp,pan,attack,release,duration,sendCompressible,sendCompressing,sendReverb,sendTape);
	}

	free {
		garbageCollector.stop;
		ins.keysValuesDo({ arg note, val;
			val.free;
		});
		ins.free;
	}

}
