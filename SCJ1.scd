//before startup - clean up Preview and NicePlayer

//probably need to edit the pathnames for this to work again...

(
Server.default.waitForBoot({

	//////////Collections//////////
	(
		~string = Array.fill(13,{0});
		~diary = Dictionary.new;
		~diary.add(\tracks-> PathName("/Users/mikemccormick/Desktop/SCJournal/vsounds/diary/").entries.collect({
			arg sf;
			Buffer.read(s,sf.fullPath);
		});
		);
		~tracks = Array.fill(~diary[\tracks].size,{0});
		~loop = Buffer.read(s,"/Users/mikemccormick/Desktop/SCJournal/vsounds/loop.wav");
	);

	s.sync;

	TempoClock.default.tempo_(46/60);

	s.sync;

	//////////SynthDefs//////////

	(
		SynthDef(\playback,{
			arg bufnum,startPos=0,atk=1,rls=1,gate=1,amp=0.5,outBus=0;
			var sig,env;

			env = EnvGen.kr(Env.asr(atk,1,rls,1),gate,doneAction:2);
			sig = PlayBuf.ar(2,bufnum,BufRateScale.kr(bufnum),startPos: BufFrames.kr(bufnum) * startPos);
			sig = Pan2.ar(sig.sum,LFNoise2.kr(0.2),amp);
			Out.ar(outBus,sig*env);

		}).add;

		SynthDef(\playbackStereo,{
			arg bufnum,rate=1,atk=1,rls=1,gate=1,amp=0.5,outBus=0;
			var sig,env;

			env = EnvGen.kr(Env.asr(atk,1,rls,1),gate,doneAction:2);
			sig = PlayBuf.ar(2,bufnum,BufRateScale.kr(bufnum)*rate,loop: 1);
			sig = Pan2.ar(sig,0,amp);
			Out.ar(outBus,sig*env);

		}).add;

		SynthDef(\player,{
			arg bufnum,startPos=0,atk=1,rls=1,gate=1,amp=0.5,outBus=0;
			var sig,env;

			env = EnvGen.kr(Env.asr(atk,1,rls,1),gate,doneAction:2);
			sig = PlayBuf.ar(2,bufnum,BufRateScale.kr(bufnum),startPos: BufFrames.kr(bufnum) * startPos);
			sig = Pan2.ar(sig.sum,LFNoise2.kr(0.3),amp*LFNoise2.kr(0.4).range(0.1,1.0));
			Out.ar(outBus,sig*env);

		}).add;

		SynthDef(\sinSynth, {
			arg freq=440,filtfreq=500,atk=0.1,rls=1.0,gate=1,pan=0,amp=0.4;
			var env,sig;

			env = EnvGen.kr(Env([0,1,0],[atk,rls]),gate,doneAction: 2);
			sig = SinOsc.ar(freq)*BrownNoise.ar(0.5,0.5);
			sig = RLPF.ar(sig, filtfreq);
			sig = BHiShelf.ar(sig,2800,db: -10);
			sig = Pan2.ar(sig,pan,amp);
			sig = sig*env;

			Out.ar(0,sig);

		}).add;

		SynthDef(\klik,{
			arg filtFreq=2000,atk=0.02,rls=0.5,pan=0,outBus,amp=0.5;
			var env,sig;

			env = EnvGen.kr(Env.perc(atk,rls),1,doneAction: 2);

			sig = WhiteNoise.ar(1!2).sum;
			sig = BPF.ar(sig,filtFreq,0.8,25).clip(-1,1);
			sig = sig*env;
			sig = Pan2.ar(sig,pan,amp);

			Out.ar(outBus,sig);

		}).add;

		SynthDef(\glitch,{
			arg filtFreq=2000,atk=0.02,rls=0.5,pan=0,dly=0.8,outBus,amp=0.5;
			var env,sig;

			env = EnvGen.kr(Env.perc(atk,rls),1,doneAction: 2);

			sig = WhiteNoise.ar(1!2).sum;
			sig = BPF.ar(sig,filtFreq,0.8,25).clip(-1,1);
			sig = sig*env;
			sig = CombC.ar(sig,0.1,dly,1.0);
			sig = Pan2.ar(sig,pan,amp);

			Out.ar(outBus,sig);

		}).add;

		SynthDef(\bump,{
			arg freq=80,harms=2,atk=0.02,rls=0.5,pan=0,outBus,amp=0.5;
			var env,sig;

			env = EnvGen.kr(Env([0,1,1,0],[atk,rls,atk],\exp),1,doneAction: 2);

			sig = SinOsc.ar(freq*[1,2],mul: harms).tanh.sum;
			sig = sig*env;
			sig = Pan2.ar(sig,pan,amp);

			Out.ar(outBus,sig);

		}).add;

		SynthDef(\pmSynth2,{
			arg carfreq=200, modfreq=1,index=0,rate=4,boop=10,atk=0.01,rls=0.4,filt=12000,gate=1,pan1=0,amp=0.3,bus=0,modFB=0;
			var env,mod,wobble,sig;

			wobble = LFNoise0.kr(rate*LFNoise0.kr(rate).range(0.5,2.0),boop).abs;
			mod = SinOscFB.ar(modfreq*wobble.reciprocal*2,modFB*wobble);

			sig = PMOsc.ar([carfreq,carfreq*1.05]*wobble,modfreq,index,mod,mod,mod);

			env = EnvGen.kr(Env.asr(atk,1,rls),gate,doneAction: 2);

			sig = sig*env;
			sig = CombC.ar(sig,0.02,0.02,0.5);
			sig = LPF.ar(sig,filt);
			sig = BLowShelf.ar(sig,60,1,-12);
			sig = LeakDC.ar(sig);

			Out.ar(bus,sig*amp);

		}).add;
	);

	s.sync;

	//////////Patterns//////////
	(
		Pdef(\glitchmas,
			Ppar([
				//clicks
				Pbindef(
					\klikker,
					\instrument,\klik,
					\dur,Prand([1/4,1/8,Pseq((1/16)!2,1)],inf),//put it more on the grid
					// \dur, Pseq([1],inf),
					\filtFreq,12000,
					\atk,0.001,
					\rls,0.001,
					\pan,Pwhite(-1.0,1.0,inf),
					\amp,Pkey(\dur)*2,
				),

				//bass
				Pbindef(
					\bass,
					\instrument,\bump,
					\dur,Pseq([4],inf),
					\freq,Pseq([27].midicps,inf),
					\atk,0.001,
					\harms,Pwhite(1,4,inf),
					\rls,1,
					\pan,0,
					\amp,Pkey(\harms).reciprocal * 0.6,
				),

				//combz
				Pbindef(
					\pingz,
					\instrument,\glitch,
					\dur,Pseq([3/4,3/4,1/2],inf),
					\type,Pseq([\rest,Pwrand([\note,\rest],[1,4].normalizeSum,[0.4,0.6]),Pwrand([\note,\rest],[1,4].normalizeSum,[0.4,0.6],1)],inf),
					\filtFreq,800,
					\atk,0.001,
					\rls,Pexprand(0.03,0.1,inf),
					\pan,Pwhite(-0.5,0.5,inf),
					\amp,0.04,
					\dly,46.midicps.reciprocal / Pxrand([1,2,4],inf),
				),

				//high beeps
				Pbindef(
					\pickup,
					\instrument,\glitch,
					\dur,Pseq([4,1].normalizeSum * 2,inf),
					\type,Pseq([\note,\rest,\note,Pwrand([\note,\rest],[0.55,0.45],1)],inf),
					\filtFreq,800,
					\atk,0.001,
					\rls,Pseq([0.03,Pwhite(0.35,0.5,1)],inf),
					\pan,Prand([-0.85,0.85],inf),
					\amp,Pseq([0.05,0.04],inf),
					\dly,Pseq([106.midicps.reciprocal,Prand([94.midicps.reciprocal],1)],inf) //Bb
				)
			])
		);

		Pdef(\mySin,
			Pbind(
				\instrument, \sinSynth,
				\dur,Pwhite(5,8.0,inf),
				\freq,Pwhite(1000,4000,inf),
				\filtfreq,Pkey(\freq*1.25,inf),
				\pan,Pwhite(-1.0,1.0,inf),
				\amp,Pwhite(0.2,0.35,inf),
				\atk,Pwhite(10.0,12.0,inf),
				\rls,Pwhite(10.0,12.0,inf),
			)
		);
	);

	s.sync;

	//////////functions//////////

	(
		~funcs = Dictionary.with(*[

			//months...
			\flash0 -> Routine({
				var screenB = Window.screenBounds;
				var routine;

				routine = Routine({
					200.do({
						arg index;
						var window,word,rect,text,size;

						word = ["you","are","not","enough"].wchoose([1,1,1.25,1.25].normalizeSum);

						rect = Rect(screenB.width.rand,screenB.height.rand,(screenB.width/2).rand,(screenB.height/2).rand);
						size = if(rect.width > rect.height,{rect.height/4},{rect.width/4});

						window = Window("%".format(index),rect,border: false);
						window.background_(Color.rand(0.25,0.6));
						text = StaticText(window,Rect(0,0,rect.width,rect.height));
						text.string = "%".format(word);
						text.align = \center;
						text.font = Font("Arial",size,true);

						window.front;
						0.01.wait;
					})
				});
				routine.play(AppClock);

				3.wait;
				routine.stop;
				Window.closeAll;
				1.wait;
				routine.reset;
			}),

			//the artist
			\flash1 -> Routine({
				var screenB = Window.screenBounds;
				var routine;

				routine = Routine({
					200.do({
						arg index;
						var window,word,rect,text,size;

						word = ["you","are","too","much"].wchoose([1,1,1.25,1.25].normalizeSum);

						rect = Rect(screenB.width.rand,screenB.height.rand,(screenB.width/2).rand,(screenB.height/2).rand);
						size = if(rect.width > rect.height,{rect.height/4},{rect.width/4});

						window = Window("%".format(index),rect,border: false);
						window.background_(Color.rand(0.25,0.6));
						text = StaticText(window,Rect(0,0,rect.width,rect.height));
						text.string = "%".format(word);
						text.align = \center;
						text.font = Font("Arial",size,true);

						window.front;
						0.01.wait;
					})
				});
				routine.play(AppClock);

				3.wait;
				routine.stop;
				Window.closeAll;
				1.wait;
				routine.reset;
			}),

			//understanding
			\flash2 -> Routine({
				var screenB = Window.screenBounds;
				var routine;

				routine = Routine({
					200.do({
						arg index;
						var window,word,rect,text,size;

						word = ["you're","full","of","shit"].wchoose([1,1,1.25,1.25].normalizeSum);

						rect = Rect(screenB.width.rand,screenB.height.rand,(screenB.width/2).rand,(screenB.height/2).rand);
						size = if(rect.width > rect.height,{rect.height/4},{rect.width/4});

						window = Window("%".format(index),rect,border: false);
						window.background_(Color.rand(0.25,0.6));
						text = StaticText(window,Rect(0,0,rect.width,rect.height));
						text.string = "%".format(word);
						text.align = \center;
						text.font = Font("Arial",size,true);

						window.front;
						0.01.wait;
					})
				});
				routine.play(AppClock);

				3.wait;
				routine.stop;
				Window.closeAll;
				1.wait;
				routine.reset;
			}),

			//experiences
			\bands -> {
				var routine;

				routine = Routine({
					6.do({
						arg index;
						var pipe;

						pipe = Pipe("open /Users/mikemccormick/Desktop/SCJournal/videos/v%.mp4".format(index), "w");
						pipe.close;
						0.5.wait;
					});
				});
				routine.play;
			},

			//Norway
			\visa -> Routine({
				2.do({
					arg index;
					var pipe;

					pipe = Pipe("open /Users/mikemccormick/Desktop/SCJournal/vpictures/p%.jpg".format(index), "w");
					pipe.close;
					1.wait;

				})
			}),

			//heartbreak
			\heartbroke -> Routine({
				var wait = 4;
				15.do({
					arg index;
					var pipe;

					pipe = Pipe("open /Users/mikemccormick/Desktop/SCJournal/vpictures/p%.jpg".format(index+2), "w");
					pipe.close;
					wait = wait * 0.75;
					wait.wait;
				})
			}),

			//the artist
			\johanna -> {
				var pipe;
				pipe = Pipe("open -a Safari https://johannalettmayer.net/", "w");
				pipe.close;
			},

			\joFlash -> Routine({

				~funcs[\johanna].value;
				2.wait;
				~funcs[\flash1].play(AppClock)
			}),

			//instrument
			\convo -> Routine({
				inf.do({
					var pipe, voice = ["Henrik","Nora"].choose;
					var con = "ntrsdlg kmvhpfbjcwzxq";
					var vow = "eai ouy";
					var word, newWord;
					var rand = 2.rrand(8);

					con = {con.wchoose((21..1).normalizeSum)}!rand;
					vow = {vow.wchoose((8..1).normalizeSum)}!(rand + 2.rand);
					word = con ++ vow;
					word = word.perfectShuffle;
					for(0,word.size-1,{arg i; newWord = newWord ++ word[i]});

					// newWord.postln;
					pipe = Pipe("say -v % %".format(voice,newWord), "w");
					pipe.close;
					0.5.exprand(3.0).wait;
				})
			}),

			//accents
			\newConvo -> Routine({
				inf.do({
					var pipe, voice = ["Satu","Ioana","Yelda"].choose;
					var con = "ntrsdlg kmvhpfbjcwzxq";
					var vow = "eai ouy";
					var word, newWord;
					var rand = 2.rrand(8);

					con = {con.wchoose((21..1).normalizeSum)}!rand;
					vow = {vow.wchoose((8..1).normalizeSum)}!(rand + 2.rand);
					word = con ++ vow;
					word = word.perfectShuffle;
					for(0,word.size-1,{arg i; newWord = newWord ++ word[i]});

					// newWord.postln;
					pipe = Pipe("say -v % %".format(voice,newWord), "w");
					pipe.close;
					0.5.exprand(3.0).wait;
				})
			}),

			//opposite
			\playMemos -> {
				~diary[\tracks].size.do({
					arg index;

					if(index < 2,
						{
							~tracks[index] = Synth(\playback,[\bufnum,~diary[\tracks][index],\atk,8 + index,\rls,4,\startPos,0,\amp,0.7,\outBus,0]);
						},{
							~tracks[index] = Synth(\player,[\bufnum,~diary[\tracks][index],\atk,8 + index,\rls,4,\startPos,0,\amp,0.55,\outBus,0]);
					})
				})
			},

			\stopMemos -> {
				~diary[\tracks].size.do({
					arg index;

					~tracks[index].set(\rls,10 + index,\gate,0);
				})
			},
		]);
	);

	s.sync;
});
)


(
var date, doc;
// date = Date.getDate.format("%d/%m/%Y");
date = "17/12/2019";

doc = Document("SC Journal %".format(date),"//SC Journal %\n\n/*\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n*/".format(date));
doc.keyDownAction = ({
	arg view, char, modifiers, unicode, keycode;

	Synth(\klik,[\filtFreq,5000,\atk,0.001,\rls,0.001,\pan,0.5.rand2,\amp,0.2]);

	if(char.isPrint,{
		// [char, unicode, keycode].postln;
		~string = ~string.rotate.put(0,unicode);

		case
		//performance
		{~string[0..10].reverse == [112,101,114,102,111,114,109,97,110,99,101]}{Pdef(\glitchmas).play}
		//direction
		{~string[0..8].reverse == [100,105,114,101,99,116,105,111,110]}{Pdef(\glitchmas).stop}
		//months...
		{~string[0..8].reverse == [109,111,110,116,104,115,46,46,46]}{~funcs[\flash0].play(AppClock)}
		//experiences
		{~string[0..10].reverse == [101,120,112,101,114,105,101,110,99,101,115]}{~funcs[\bands].value}
		//come to mind
		{~string[0..11].reverse == [99,111,109,101,32,116,111,32,109,105,110,100]}{~joao = Synth(\playbackStereo,[\bufnum,~loop.bufnum,\rate,-0.5,\atk,0.1,\rls,0.1,\gate,1,\amp,0.8,\outBus,0])}

		//Norway
		{~string[0..5].reverse == [78,111,114,119,97,121]}{~funcs[\visa].play}
		//heartbreak
		{~string[0..9].reverse == [104,101,97,114,116,98,114,101,97,107]}{~funcs[\heartbroke].play}
		//suicide
		{~string[0..6].reverse == [115,117,105,99,105,100,101]}{
			~joao.set(\rls,3.0,\gate,0);

			Document.current.keyDownAction = ({
				arg view, char, modifiers, unicode, keycode;

				if(char.isPrint,{
					// [char, unicode, keycode].postln;
					~string = ~string.rotate.put(0,unicode);

					case
					// ////
					{~string[0..3].reverse == [47,47,47,47]}{if(Pdef(\mySin).isPlaying,{Pdef(\mySin).stop},{Pdef(\mySin).play})}
					//the artist
					{~string[0..9].reverse == [116,104,101,32,97,114,116,105,115,116]}{~funcs[\joFlash].play}
					//language
					{~string[0..7].reverse == [108,97,110,103,117,97,103,101]}{~bleep = Synth(\pmSynth2,[\carfreq,16,\modfreq,50,\modFB,2.1,\index,5,\filt,3000,\atk,0.1,\amp,0.1,\boop,250,\bus,0,\rate,2])}
					//understanding
					{~string[0..12].reverse == [117,110,100,101,114,115,116,97,110,100,105,110,103]}{~funcs[\flash2].play(AppClock)}
					//delights
					{~string[0..7].reverse == [100,101,108,105,103,104,116,115]}{~bleep.set(\rls,8.0,\gate,0)}
					//instrument
					{~string[0..9].reverse == [105,110,115,116,114,117,109,101,110,116]}{~funcs[\convo].play}
					//accents
					{~string[0..6].reverse == [97,99,99,101,110,116,115]}{~funcs[\convo].stop; ~funcs[\newConvo].play}
					//opposite
					{~string[0..7].reverse == [111,112,112,111,115,105,116,101]}{~funcs[\newConvo].stop; ~funcs[\playMemos].play}
				})
			});
		};
	});
});
);