SerialPort.listDevices; //run this to get name of arduino device
(
//Start-up routine, boots first before running code
s.waitForBoot{
	//Fork runs a routine for running things in order and timing
	fork{
		//GLOBAL VARIABLES
		////Paths
		~wtpath = "/home/ddmi/Documents/DDMI_1516_Spring_C10_Tue_8Mar/DDMI_Performance/wavetables/";
		////Arduino
		~ino = ArduinoSMS("/dev/ttyUSB0", 9600);
		////Control Busses
		~kbs = {Bus.control(s)}!50;
		////Net Addresses
		~proc = NetAddr("127.0.0.1", 12321);
		////Mapping
		~ma = [
			[0,1023,0.0,1.0], //mapping for Pot1
			[0,1023,150,10000], //mapping for Pot2
			[ 0,1,0,1 ],
			[ 0.0,1.0,0.0,1.0 ],
			[ 0,1,0,1 ],
			[ 0.0,1.0,0.0,1.0 ],
			[200,800, 0.5, 20.0 ],
			[200,800, 0.0, 1.2 ]
		];

		0.1.wait;

		//BUFFERS
		////Wavetable Buffers
		~wt1  = Buffer.read(s, ~wtpath ++ "WT7.aif");
		~wt2 = Buffer.read(s, ~wtpath ++ "WT10.aif");
		~wt3 = Buffer.read(s, ~wtpath ++ "FM - Complex Sine 135.wav");
		~wt4 = Buffer.read(s, ~wtpath ++ "FM Sine 3 4 1.wav");

		//OSC DEFS
		////GUI Keyboard
		OSCdef( \trig, {|msg| ~mt.set(\trig, msg[1].asFloat)}, "/trig" );
		OSCdef( \pitch, {|msg| ~mt.set(\pitch, msg[1].asFloat)}, "/pitch" );
		OSCdef( \amp, {|msg| ~mt.set(\amp, msg[1].asFloat)}, "/amp" );
		////Visualizer
		//Mechanism for Processing to grab control data
		OSCdef( \getkdata, {
			arg msg;
			var kbus = msg[1].asInteger;
			var knum = msg[2].asInteger;
			~kbs[kbus].get( { arg val;  ~proc.sendMsg( "/kbsval", knum, val.asFloat ) } );
		}, "/getkdata");

		0.1.wait;

		//ARDUINO
		~ino.action = {
			arg msg;
			var sm = msg.split($:);
			//////////////////////////////////////////////////////////////////////////////
			//
			// Pot0 - the if statement represents 1 sensor ////////////////////////////////
			//
			//////////////////////////////////////////////////////////////////////////////
			if( sm[0] == "p0", { //which sensor?
				var val = sm[1].asFloat.linlin( ~ma[0][0], ~ma[0][1],  ~ma[0][2],  ~ma[0][3] );
				~kbs[0].setSynchronous(val);
			} );

			//Pot1
			if( sm[0] == "p1", { //which sensor?
				var val = sm[1].asFloat.linlin( ~ma[1][0], ~ma[1][1],  ~ma[1][2],  ~ma[1][3]);
				~kbs[1].setSynchronous(val);
			} );

			//Button0 momentary
			if( sm[0] == "b0", {
				var val = sm[1].asFloat.linlin( ~ma[2][0], ~ma[2][1],  ~ma[2][2],  ~ma[2][3]);
				~kbs[2].setSynchronous(val);
			} );

			//Button0 toggle //Preset Button
			if( sm[0] == "bt0", {
				var val = sm[1].asInteger;
				switch( val,
					0, { //Preset 0 - Chariots1
						//Kill Old ~mt Synth
						~mt.free;
						//Start New ~mt Synth
						~mt = Synth(\chariots);
						//Send Appropriate Mappings
						////Mapping
						~ma = [
							[0,1023, 0.06, 12.0], //mapping for Pot1, goes to kbus[0]
							[0,1023 , 0.06, 21.1], //mapping for Pot2, goes to kbus[1]
							[ 0,1,0,1 ],
							[ 0.0,1.0,0.0,1.0 ],
							[ 0,1,0,1 ],
							[ 0.0,1.0,0.0,1.0 ],
							[200,800, 0.5, 20.0 ],
							[200,800, 0.0, 1.2 ]
						];
						//Map Synth Args to Appropriate Control Busses
						~mt.map(\detune, ~kbs[0]);
						~mt.map(\lffreq, ~kbs[1]);
					},
					1, {
						~mt.free;
						~mt = Synth(\midisine);
					},
					2, {
						~mt.free;
						~mt = Synth(\pad);
					},
					3, {
						~mt.free;"three".postln;}
				);
			} );

			//Button01 momentary
			if( sm[0] == "b1", {
				var val = sm[1].asFloat.linlin( ~ma[4][0], ~ma[4][1],  ~ma[4][2],  ~ma[4][3]);
				~kbs[4].setSynchronous(val);
			} );


			//FSR0 raw
			if( sm[0] == "fsr0", {
				var val = sm[1].asFloat.linlin( ~ma[6][0], ~ma[6][1],  ~ma[6][2],  ~ma[6][3] );
				~kbs[6].setSynchronous(val);
			} );


			//FSR peak value 0
			if( sm[0] == "fsp0", {
				var val = sm[1].asFloat.linlin( ~ma[7][0], ~ma[7][1],  ~ma[7][2],  ~ma[7][3] );
				~kbs[7].setSynchronous(val);
			} );

		}; //end Arduino
		//SYNTHDEFS
		SynthDef( \midisine,{
			arg trig=0, atk=0.01, rel=0.1, crv= -3;
			var freq, synth, vol, pitch, amp, env;
			pitch = \pitch.kr(60, 0.017);
			amp = \amp.kr(0.85, 0.017);
			freq = pitch.midicps;
			env = EnvGen.ar( Env.asr(atk, 1, rel, crv), trig );
			synth = SinOsc.ar(freq);
			Out.ar(0, synth*env*amp);
		}).add;

		SynthDef( \chariots, {
			arg atk=0.410, rel=6.1, crv = 0, trig=0, lffreq=0.06, detune = 0.06,
			lpfreq=6000, fatk=1.6, frel=7.7, fcrv=0,
			mix=0.7, rm=0.9, dmp=0.07;
			var osc1, osc2, freq1, freq2, env, pitch, amp, sig, lfo1, pitch2,
			fenv;
			fenv = EnvGen.ar( Env.asr(fatk, 1, frel, fcrv), trig );
			lfo1 = SinOsc.kr(lffreq);
			pitch = \pitch.kr(60, 0.017);
			pitch2 = pitch + (lfo1*detune) ;
			amp = \amp.kr(0.85, 0.017);
			env = EnvGen.ar( Env.asr(atk, 1, rel, crv), trig );
			freq1 = pitch.midicps;
			freq2 = pitch2.midicps;
			osc1 = Saw.ar(freq1);
			osc2 = Saw.ar(freq2);
			sig = Mix.ar( [osc1, osc2] );
			sig = RLPF.ar(sig, (lpfreq*fenv)+100 );
			//sig = FreeVerb2.ar(sig, sig, mix, rm, dmp);
			sig = JPverb.ar(sig, 4, 0, 4);
			Out.ar(0, sig*amp*env);
		}).add;

		SynthDef(\chippy, {
			arg trig=0, dur=0.25;
			var freq, sig, env, h1, h2, amp, pitch;
			pitch = \pitch.kr(60, 0.01);
			amp = \amp.kr(0.85, 0.03);
			freq = pitch.midicps;
			env = EnvGen.ar( Env.perc(0.01, dur), trig );
			h1 = TIRand.kr(2, 7, env);
			h2 = TIRand.kr(2, 7, env);
			sig = AY.ar( AY.freqtotone(freq), AY.freqtotone(freq*h1), AY.freqtotone(freq*h2), 0.25,3,15,10,7);
			Out.ar(0, sig*env*amp);
		}).add;

		SynthDef( \synthbass,{
			arg trig=0, atk=0.01, rel=0.07, crv= -6,
			fatk=0.01, fdky=0.14, fsus=0.1, frel=0.07, fcrv= 0,
			ffrq1=1800, rq1=0.9, dky=0, sus=1;
			var freq1, osc1, vol, amp, env,
			osc2, osc3, freq2, freq3,
			sig, pitch, fenv, sigR;
			pitch = \pitch.kr(60, 0.017);
			freq1 = pitch.midicps;
			freq2 = (pitch+0.06).midicps;
			freq3 = (pitch-12).midicps;
			amp = \amp.kr(0.85, 0.040);
			env = EnvGen.ar( Env.adsr(atk, dky, sus, rel, curve:crv), trig );
			fenv = EnvGen.ar( Env.adsr(fatk, fdky, fsus, frel, curve:fcrv), trig);
			osc1 = SawDPW.ar(freq1);
			osc2 = SawDPW.ar(freq2);
			osc3 = SinOsc.ar(freq3);
			sig = Mix.ar([osc1, osc2, osc3]);
			sig = RLPF.ar( sig, (ffrq1*fenv)+80, rq1 );
			sig = sig.softclip;
			sigR = DelayC.ar(sig, 0.2, 0.03);
			Out.ar(0, [sig, sigR]*env*amp);
		}).add;

		SynthDef( \lead, {
			arg trig=0, atk=0.03, rel=1.5, crv = 0,
			ffreqhi=15000, ffreqlo=100,
			fatk=0.01, fdecay= 1.2, fsusl=0.18, frel=1, fcrv= -2,
			osamp1=0.5, osamp2=0.5, osamp3=1,
			detune1= -0.08, detune2= 0.08, detune3=0.02,
			lfo1w=3, lfo1freq=45, lfo2freq = 6, lfo3freq = 0.1,
			glide=0.7, wtbuf, offset=0.65;
			var osc1, freq1, pitch1;
			var osc2, freq2, pitch2;
			var osc3, freq3, pitch3;
			var pitch, amp;
			var sig, sig2;
			var env, fenv;
			var lfo1, lfo2, lfo3;
			//Envelopes
			env = EnvGen.ar( Env.asr(atk, 1, rel, crv), trig );
			fenv = EnvGen.ar( Env.adsr(fatk, fdecay, fsusl, frel, curve:fcrv), trig );
			//lfos
			lfo1 = SinOsc.kr(lfo1freq*fenv);
			lfo2 = SinOsc.kr(lfo2freq);
			lfo3 = SinOsc.kr(lfo3freq);
			//Pitch/Frequency/Amp
			pitch = \pitch.kr(60, glide);
			pitch1 = pitch + (lfo2*detune1);
			pitch2 = pitch + (lfo2*detune2);
			pitch3 = pitch + (lfo3*detune3);
			freq1 = pitch.midicps;
			freq2 = pitch2.midicps;
			freq3 = pitch3.midicps;
			amp = \amp.kr(0.85, 0.017);
			//Oscillators
			osc1 = Saw.ar(freq1);
			osc2 = Saw.ar(freq2);
			osc3  = VOsc3.ar(wtbuf+offset, freq3, freq3+0.37, freq3+0.43, 0.3333);
			//Mix-Filter-Make Stereo
			sig = Mix.ar( [osc1*osamp1, osc2*osamp2, osc3*osamp3] );
			sig = RLPF.ar(sig, (((ffreqhi*fenv)+ffreqlo).cpsmidi+(lfo1*lfo1w)).midicps );
			sig2 = DelayC.ar(sig, 0.2, 0.05);
			Out.ar(0, [sig, sig2]*amp*env);
		}).add;

		SynthDef(\snh, {
			arg atk=0.01, rel=0.5, crv= -2,trig=0, sfreq=7.5,
			dt1= -7, oamp1=0.35, oamp2=0.35, oamp3=0.2, oamp4=0.1,
			wtbuf, offset=0.4, res=1.2, pan=1, pitch=60;
			var sig, amp, env;
			var osc1, osc2, osc3, osc4;
			var freq, freq2, sh;
			sh = LFNoise0.kr(sfreq);
			env = EnvGen.ar(Env.asr(atk, 1, rel, crv), trig);
			amp = \amp.kr(0.85, 0.03);
			freq = pitch.midicps;
			freq2 = (pitch+dt1).midicps;
			osc1 = Saw.ar(freq);
			osc2 = Saw.ar(freq2);
			osc3 = VOsc3.ar(wtbuf+offset, freq, freq+0.37, freq+0.43, 0.333333);
			osc4 = DFM1.ar(In.ar(55), freq, res);
			sig = Mix.ar([osc1*oamp1, osc2*oamp2, osc3*oamp3, osc4*oamp4]);
			sig = DFM1.ar(sig, sh.range(pitch+12, pitch+36).midicps, res);
			sig = Pan2.ar(sig, sh.range(-1, 1) );
			Out.ar(0, sig*amp*env);
		}).add;

		SynthDef(\pad, {
			arg atk=0.3, rel=0.5, trig=0, crv = -2,
			lffreq1=2, lffreq2=2, lf1lo=0.14, lf1hi=0.20,
			lf2lo=0.74, lf2hi=0.8, detune1= -0.06, detune2 = 0.06, detune3 = -12.06,
			ffreq = 2500;
			var osc1,osc2, osc3;
			var freq1, freq2, freq3;
			var env, sig, amp, pitch, sig2;
			var lfo1, lfo2;
			pitch = \pitch.kr(64, 0);
			amp = \amp.kr(0.75, 0.03);
			lfo1 = SinOsc.kr(lffreq1).range(lf1lo, lf1hi);
			lfo2 = SinOsc.kr(lffreq2).range(lf2lo, lf2hi);
			env = EnvGen.ar(Env.asr(atk, 1, rel, curve: crv),trig);
			freq1 = (pitch+detune1).midicps;
			freq2 = (pitch+detune2).midicps;
			freq3 = (pitch+detune3).midicps;
			osc1 = Pulse.ar(freq1, lfo1);
			osc2 = Pulse.ar(freq2, lfo2);
			osc3 = Pulse.ar(freq3, lfo1);
			sig = Mix.ar([osc1*0.33333, osc2*0.33333, osc3*0.33333]);
			sig = DFM1.ar(sig, ffreq, type:0);
			sig2 = DelayC.ar(sig, 0.2, 0.05);
			Out.ar(0, [sig, sig2]*env*amp);
		}).add;
		0.1.wait;
		//RUN SYNTHS
		//~mt = Synth(\midisine);
		//~mt = Synth(\chariots);
		~mt = Synth(\chippy);
		//~mt = Synth(\synthbass);
		//~mt = Synth(\pad);
		//~mt = Synth(\lead, [\wtbuf, ~wt1.bufnum]);
		//~mt = Synth(\snh, [\wtbuf, ~wt3.bufnum]);
	}//end of fork
}//end s.waitForBoot
)

( //Manual Preset Test
//Kill Old ~mt Synth
~mt.free;
//Start New ~mt Synth
~mt = Synth(\chariots);
//Send Appropriate Mappings
////Mapping
~ma = [
	[0,1023, 0.06, 12.0], //mapping for Pot1, goes to kbus[0]
	[0,1023 , 0.06, 21.1], //mapping for Pot2, goes to kbus[1]
	[ 0,1,0,1 ],
	[ 0.0,1.0,0.0,1.0 ],
	[ 0,1,0,1 ],
	[ 0.0,1.0,0.0,1.0 ],
	[200,800, 0.5, 20.0 ],
	[200,800, 0.0, 1.2 ]
];
//Map Synth Args to Appropriate Control Busses
~mt.map(\detune, ~kbs[0]);
~mt.map(\lffreq, ~kbs[1]);
)


~mt.set(\detune, 1.1);
~mt.set(\lffreq, 21.1);

arg atk=0.410, rel=6.1, crv = 0, trig=0, lffreq=0.06, detune = 0.06,
lpfreq=6000, fatk=1.6, frel=7.7, fcrv=0,
mix=0.7, rm=0.9, dmp=0.07;
