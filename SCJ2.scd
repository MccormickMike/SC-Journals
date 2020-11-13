 /* SC Journal #2 */

// post window zoom!!
// post window wraps? yes/no
// main window wraps - yes
// turn off bracket completion

//add to YT documentation
~funcs[\post].value("Headphones interfere with the illusion!\n",0.3)

(
var server = Server.default;
var path = "/Users/mikemccormick/Desktop/SCJ2/"; // folder of materials
var ampScale = 0.53;

server.waitForBoot({

	/* Collections */

	~text = Array.fill(20,{0}); // consider .newClear(20) not sure if slots can be nil

	/* Buffers */

	(
		~buffers = Dictionary[

			\breakthrough -> PathName(path ++ "hits/breakthrough/").entries.collect({
				arg sf;
				Buffer.read(server,sf.fullPath);
			}),

			\deutsch -> PathName(path ++ "hits/deutsch/").entries.collect({
				arg sf;
				Buffer.read(server,sf.fullPath);
			}),

			\ping -> Buffer.readChannel(
				server,
				path ++ "hits/ping.wav",
				channels:[0,1]
			),

			\pingReverse -> Buffer.readChannel(
				server,
				path ++ "hits/pingReverse.wav",
				channels:[0,1]
			),

			\pingMono -> Buffer.read(
				server,
				path ++ "hits/pingMono.wav",
			),

			\death -> Buffer.read(
				server,
				path ++ "hits/death.wav",
			),
		]
	);

	server.sync;

	/* SynthDefs */

	(
		SynthDef(\phantomPB,{
			arg bufnum,rate=1,pan=0,amp=0.5,outBus=0;
			var sig;

			sig = PlayBuf.ar(1,bufnum,BufRateScale.kr(bufnum)*rate,doneAction:2);
			sig = Pan2.ar(sig,pan,amp * ampScale);
			Out.ar(outBus,sig);

		}).add;

		SynthDef(\monoPB,{
			arg bufnum,rate=1,pan=0,amp=0.5,outBus=0;
			var sig;

			sig = PlayBuf.ar(1,bufnum,BufRateScale.kr(bufnum)*rate,doneAction:2);
			sig = Pan2.ar(sig,pan,amp * ampScale);
			Out.ar(outBus,sig);

		}).add;

		SynthDef(\stereoPB,{
			arg bufnum,rate=1,pan=0,amp=0.5,outBus=0;
			var sig;

			sig = PlayBuf.ar(2,bufnum,BufRateScale.kr(bufnum)*rate,doneAction:2);
			sig = Balance2.ar(sig[0],sig[1],pan,amp * ampScale);
			Out.ar(outBus,sig);

		}).add;

		SynthDef(\sines,{
			arg freq = 1300,gate=1,atk=5,rls=0.1,pan=0,amp=0.5,outBus=0;
			var sig,env;

			env = EnvGen.kr(Env.asr(atk,1,rls,2),gate,doneAction:2);
			sig = SinOsc.ar(freq);
			sig = Pan2.ar(sig*env,pan,amp * ampScale);
			Out.ar(outBus,sig);

		}).add;

		SynthDef(\klik,{
			arg filtFreq=2000,atk=0.02,rls=0.5,pan=0,outBus,amp=0.5;
			var env,sig;

			env = EnvGen.kr(Env.perc(atk,rls),1,doneAction: 2);

			sig = WhiteNoise.ar(1!2).sum;
			sig = BPF.ar(sig,filtFreq,0.8,25).clip(-1,1);
			sig = sig*env;
			sig = Pan2.ar(sig,pan,amp * ampScale);

			Out.ar(outBus,sig);

		}).add;

		SynthDef(\tik,{
			arg freq=300,atk=0.02,rls=0.5,pan=0,outBus=0,amp=0.5;
			var env,sig;

			env = EnvGen.kr(Env.perc(atk,rls),1,doneAction: 2);

			sig = SinOsc.ar(freq);
			sig = sig*env;
			sig = Pan2.ar(sig,pan,amp * ampScale);

			Out.ar(outBus,sig);

		}).add;

		Ndef(\grainer,{
			arg bufnum,rate=0.5,impulseTrig,pos=0.5, amp=1.0;
			var sig,trig,noise,grainDur=1.0,bufDur;

			noise = impulseTrig.linexp(0.0,1.0,0.1,0.001);
			rate = rate.linexp(0.0,1.0,0.5,2.0);
			rate = rate + LFNoise2.kr(0.08,0.1);

			trig = Impulse.kr(impulseTrig.linexp(0.0,1.0,0.3,12.0));
			bufDur = BufDur.kr(bufnum);

			pos = pos + LFNoise1.kr(12,noise);

			sig = TGrains.ar(2,trig,bufnum,BufRateScale.kr(bufnum) * rate,pos * bufDur,grainDur,Latch.kr(LFNoise2.kr(0.05,0.7),trig),amp * ampScale);
		});
	);

	server.sync;

	/* Patterns */
	(

		Pdef(\phantom,
			Ppar([
				Pbind(
					\instrument, \phantomPB,
					\dur,0.25,
					\bufnum,Pseq([~buffers[\deutsch][6],~buffers[\deutsch][7]],inf),
					\rate,1,
					\pan,-1,
					\amp,Pseq([Pseg([0,0.5],15,\lin,1),Pseq([0.5],inf)],1) * ampScale,
					\outBus,0
				),
				Pbind(
					\instrument, \phantomPB,
					\dur,0.25,
					\bufnum,Pseq([~buffers[\deutsch][7],~buffers[\deutsch][6]],inf),
					\rate,1,
					\pan,1,
					\amp,Pseq([Pseg([0,0.5],15,\lin,1),Pseq([0.5],inf)],1) * ampScale,
					\outBus,0
			)],inf)

		).quant_(0.25);
	);

	server.sync;

	/* Functions */

	(
		~funcs = Dictionary [

			\blink -> {
				arg frames = 20;
				var window = Window("a",Window.screenBounds,false,false);

				window.background_(Color.black).front;

				Routine({
					frames.do({
						arg i;
						window.alpha = (i * frames.reciprocal);
						0.005.wait;
					});

					0.05.wait;

					frames.do({
						arg i;
						window.alpha = 1 - (i * frames.reciprocal);
						0.005.wait;
					});

					window.close;

				}).play(AppClock);

			},

			\clear -> {    // can pass the variable doc below into the first argument
				arg document, start=0, end;
				document.string_("//SC Journal %\n\n/*\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n*/".format(2),start,end)
			},

			\fade -> {
				arg frames = 200, pause = 1;
				var window = Window("a",Window.screenBounds,false,false);

				window.background_(Color.black).front.alwaysOnTop;

				Routine({
					frames.do({
						arg i;
						window.alpha = (i * frames.reciprocal);
						0.005.wait;
					});

					pause.wait;

					window.close;

				}).play(AppClock);
			},

			\inked -> {
				arg inks = 4, freq = 100;
				var array = Array.fill(inks,{20.rand});

				Routine({
					array.do({
						arg i;
						~funcs[\pix].value(path ++ "pix/ink/ink%.jpg".format(i),2.08,0,0);
						freq.reciprocal.wait;
						Window.closeAll;
					});
				}).play(AppClock);
			},

			\pix -> {
				arg string,scale,x,y;
				var img = Image.open(string);
				var rect = Rect(0,0,img.width * scale,img.height * scale);

				var window = Window("nope",Rect(x,y,rect.width,rect.height),true,false)
				.front
				.background_(Color.clear);

				window.drawFunc_({
					img.drawInRect(rect,img.bounds)
				});
			},

			\pixFadeIn -> {
				arg string,scale,x,y,frames = 200;
				var img = Image.open(string);
				var rect = Rect(0,0,img.width * scale,img.height * scale);

				var window = Window("nope",Rect(x,y,rect.width,rect.height),true,false)
				.front
				.background_(Color.clear)
				.alpha_(0);

				window.drawFunc_({
					img.drawInRect(rect,img.bounds)
				});

				Routine({
					frames.do({
						arg i;
						window.alpha = (i * frames.reciprocal);
						0.005.wait;
					});
				}).play(AppClock);
			},

			\post -> {

				arg string,rate=0.1,click=true;

				if(click,{
					Routine({
						string.do({
							arg i;
							i.post;
							Synth(\klik,[\filtFreq,5000,\atk,0.001,\rls,0.001,\pan,0.5.rand2,\amp,0.05]);
							rate.exprand(2*rate).wait
						});
					}).play;
				},{
					Routine({
						string.do({
							arg i;
							i.post;
							rate.exprand(2*rate).wait
						});
					}).play;
				})
			},

			\rip -> {
				Routine({
					~funcs[\pixFadeIn].value(path ++ "pix/rip/rip0.png",0.4,0,500);
					2.exprand(3.5).wait;
					~funcs[\pixFadeIn].value(path ++ "pix/rip/rip1.png",0.4,1068,500);
					2.exprand(3.5).wait;
					~funcs[\pixFadeIn].value(path ++ "pix/rip/rip2.png",0.4,190,0);
					2.exprand(3.5).wait;
					~funcs[\pixFadeIn].value(path ++ "pix/rip/rip3.png",0.4,880,0);
					2.exprand(3.5).wait;
					~funcs[\pixFadeIn].value(path ++ "pix/rip/rip4.png",0.45,520,500);

				}).play(AppClock);
			},

			\ripAgain -> {
				Routine({
					~funcs[\pixFadeIn].value(path ++ "pix/rip/rip0.png",0.4,0,500);
					~funcs[\pixFadeIn].value(path ++ "pix/rip/rip1.png",0.4,1068,500);
					~funcs[\pixFadeIn].value(path ++ "pix/rip/rip2.png",0.4,190,0);
					~funcs[\pixFadeIn].value(path ++ "pix/rip/rip3.png",0.4,880,0);
					~funcs[\pixFadeIn].value(path ++ "pix/rip/rip4.png",0.45,520,500);

				}).play(AppClock);
			},

			\ripEdit -> {
				Routine({
					Window.closeAll;

					~funcs[\pix].value(path ++ "pix/rip/erip0.png",0.4,0,500);
					~funcs[\pix].value(path ++ "pix/rip/erip1.png",0.4,1068,500);
					~funcs[\pix].value(path ++ "pix/rip/erip2.png",0.4,190,0);
					~funcs[\pix].value(path ++ "pix/rip/erip3.png",0.4,880,0);
					~funcs[\pix].value(path ++ "pix/rip/erip4.png",0.45,520,500);

				}).play(AppClock);
			},

			\wake -> {
				arg frames = 400, pause = 3;
				var window = Window("a",Window.screenBounds,false,false);

				window
				.background_(Color.black)
				.front;

				Routine({
					pause.wait;

					frames.do({
						arg i;
						window.alpha = 1 - (i * frames.reciprocal);
						0.005.wait;
					});

					window.close;

				}).play(AppClock);
			}
		]
	);

	server.sync;

	/**************************************************************************/

	/* Playbook */

	(
		~cues = Dictionary[

			0 -> (
				string: "falling off.",
				func: {
					arg document;

					Routine({
						0.4.wait;
						~funcs[\fade].value(200,1);
						5.wait;
						~funcs[\clear].value(document,0,1000);                //reevaluate
						Synth(\stereoPB,[\bufnum,~buffers[\ping],\rate,0.8.rrand(1.2),\amp,0.8]);
						~funcs[\pix].value(path ++ "pix/letters/iota.png",1,150,50);
						3.wait;
						Window.closeAll;
					}).play(AppClock)
				}
			),

			1 -> (
				string: "overuse?",
				func: {
					~funcs[\inked].value(1)
				}
			),

			2 -> (
				string: "amount",
				func:{
					~funcs[\post].value("...until heaven and earth pass away,\nnot an iota,\nnot a dot,\nwill pass from the Law until all is accomplished.\n
Matthew 5:18\n",0.08)
				}
			),

			3 -> (
				string: "introspection",
				func:{

					// check to see if the clicks interfere with the recording!

					Routine({
						Synth(\monoPB,[\bufnum,~buffers[\breakthrough][0]]);
						1.wait;
						~funcs[\post].value("I recorded this while walking to the metro station\n",0.08);
						6.5.wait;
						Synth(\monoPB,[\bufnum,~buffers[\breakthrough][1]]);
						1.7.wait;
						~funcs[\post].value("in Istanbul\n",0.08);
						1.4.wait;
						Synth(\monoPB,[\bufnum,~buffers[\breakthrough][2]]);
						2.7.wait;
						~funcs[\post].value("alone...\n",0.05);
						1.2.wait;
						Synth(\monoPB,[\bufnum,~buffers[\breakthrough][3]]);
						0.5.wait;
						~funcs[\post].value("...also alone...\n",0.15);
					}).play;
				}
			),

			4 -> (
				string: "destinat",
				func:{
					Synth(\monoPB,[\bufnum,~buffers[\breakthrough][4]]);
				}
			),

			5 -> (
				string: "season",
				func:{
					~funcs[\post].value("or during a global pandemic...\n",0.12);
				}
			),

			6 -> (
				string: "monotony",
				func:{
					Pdef(\phantom).play;
				}
			),

			7 -> (
				string: "unconscious",
				func:{
					~funcs[\post].value(
						"     __..,,... ,,,,,,.\n" ++
						"''''        , '        `.\n" ++
						"         ,')  ,...       `.\n" ++
						"         `. \'      `.       ` `\n" ++
						"__..,.            .  `.\n" ++
						"       `.       .  `.  `.\n" ++
						"         `.  `.  `.  `._),..\n" ++
						"           `.  `.  `..'      `\n" ++
						"             ` -'`\'\'\n"
						,0.05,false)
				}
			),

			8 -> (
				string: "punctuation",
				func:{
					Pdef(\phantom,
						Ppar([
							Pbind(
								\instrument, \phantomPB,
								\dur,0.25,
								\bufnum,Pseq([~buffers[\deutsch][6],~buffers[\deutsch][7]],inf),
								\rate,1,
								\pan,-1,
								\amp,Pseq([0.5],inf),
								\outBus,0
							),
							Pbind(
								\instrument, \phantomPB,
								\dur,0.25,
								\bufnum,Pseq([~buffers[\deutsch][6],~buffers[\deutsch][7]],inf),
								\rate,1,
								\pan,1,
								\amp,Pseq([0.5],inf),
								\outBus,0
						)],inf)
					).quant_(0.25);
				}
			),

			9 -> (
				string: "noise.",
				func:{
					arg document;
					Routine({
						Pdef(\phantom).stop;
						0.4.wait;
						~funcs[\fade].value(200,1);
						5.wait;
						~funcs[\clear].value(document,0,2000);
						Synth(\stereoPB,[\bufnum,~buffers[\ping],\rate,0.8.rrand(1.2),\amp,0.8]);
						~funcs[\pix].value(path ++ "pix/letters/tau.png",1,150,50);
						3.wait;
						Window.closeAll;
					}).play(AppClock)
				}
			),

			10 -> (
				string: "abstraction",
				func:{
					~funcs[\post].value("\"In this state, there is an unlimited mutual interpenetration between images, objects and concepts: opposites are undone, inner and outer worlds merge, death and birth become one, and the restrictions of space and time are dissolved.\"\n
Saarinen, J. (2015).\nThe Concept of the Oceanic Feeling in Artistic Creativity and in the Analysis of Visual Artworks.\nJournal of aesthetic education, 49 (3), 15-31.\nRetrieved from http://www.jstor.org/stable/10.5406/jaesteduc.49.3.0015\n",0.08)
				}
			),

			11 -> (
				string: "trance...",
				func:{
					~funcs[\inked].value(2);
				}
			),

			12 -> (
				string: "weren't there",
				func:{
					arg document;
					Routine({
						1.wait;
						Synth(\stereoPB,[\bufnum,~buffers[\ping],\rate,0.8.rrand(1.2),\amp,0.8]);
						~funcs[\clear].value(document,0,2000);
						~funcs[\pix].value(path ++ "pix/letters/theta.png",1,150,50);
						5.wait;
						Window.closeAll;
					}).play(AppClock)
				}
			),

			13 -> (
				string: "usual:",
				func:{
					~funcs[\inked].value(3);
				}
			),

			14 -> (
				string: "blood tests",
				func:{
					Routine({
						~funcs[\pix].value(path ++ "pix/docEdit.png",0.5,250,250);
						~funcs[\post].value("That doesn't sound promising...\n",0.1,true);
						6.5.wait;
						Window.closeAll
					}).play(AppClock)
				}
			),

			15 -> (
				string: "hometown",
				func:{
					Routine({
						~funcs[\pix].value(path ++ "pix/funeral.png",1,350,300);
						~funcs[\post].value("Unorthodox, but essential, I guess...\n",0.1,true);
						7.wait;
						Window.closeAll
					}).play(AppClock)
				}
			),

			16 -> (
				string: "hearing",
				func:{
					Routine({
						var left,right;
						left = Synth(\sines,[\pan,-1]);
						right = Synth(\sines,[\pan,1]);
						~funcs[\post].value("Bad news for a musician...\n",0.1,false);
						4.wait;
						right.set(\gate,0);
						1.5.wait;
						left.set(\rls,3,\gate,0);
					}).play
				}
			),

			17 -> (
				string: "Mike McCor",
				func:{
					Routine({
						Ndef(\grainer).set(\bufnum,~buffers[\pingMono],\impulseTrig,1,\rate,0.9,\pos,0.15,\amp,0.5);
						Ndef(\grainer).play(fadeTime:4);
						6.wait;
						~funcs[\rip].value;
						25.wait;
						Window.closeAll;
					}).play(AppClock)
				}
			),

			18 -> (
				string: "differently",
				func:{
					arg document;
					Routine({
						var bounds = Window.screenBounds;
						var window = Window("a",bounds,false,false);
						var height = bounds.height*0.08;
						var offset = 20;
						var text;

						~funcs[\ripAgain].value;
						8.wait;
						Synth(\stereoPB,[\bufnum,~buffers[\ping],\rate,16,\amp,0.35]);
						~funcs[\ripEdit].value;
						12.wait;

						// the following lines could be removed, for example...should add sound to this as well!
						window = Window("a",bounds,false,false).background_(Color.black).front;

						Synth(\stereoPB,[\bufnum,~buffers[\ping],\rate,15,\amp,0.35]);
						~funcs[\pix].value(path ++ "pix/baseball/thirdBase.png",0.5,offset,height);
						~funcs[\pix].value(path ++ "pix/baseball/outfield.png",0.5,bounds.width * 1/3 + offset,height);
						~funcs[\pix].value(path ++ "pix/baseball/pitcher.png",0.5,bounds.width * 2/3 + offset,height);

						text = StaticText(window,Rect(bounds.width * 1/3 + offset,60,420,140))
						.string_("Also, he is at least the third Mike McCormick to play professional baseball in the US...\n\n What could THIS possibly mean?!?!")
						.stringColor_(Color.white)
						.background_(Color.clear)
						.align_(\center)
						.font_(Font("Menlo",20));
						8.wait;

						Synth(\stereoPB,[\bufnum,~buffers[\ping],\rate,14,\amp,0.35]);
						Ndef(\grainer).stop(fadeTime: 4);
						~funcs[\clear].value(document,0,2000);
						Window.closeAll
					}).play(AppClock)
				}
			),

			19 -> (
				string: "1973 book",
				func:{
					~funcs[\post].value("Is it obvious I've been reading a lot recently?\n",0.08)
				}
			),

			20 -> (
				string: "purpose",
				func:{
					~funcs[\post].value("Examples of immortality projects:\n-children\n-a garden\n-sourdough bread\n-\"art\" about your neuroses that will live on the internet forever\n\n",0.1)
				}
			),

			21 -> (
				string: "entirely",
				func:{
					Routine({

						~funcs[\post].value("Geoffrey Scarre commenting on\nMartin Heidegger commenting on\nJean Paul Sartre",0.05,false);
						Synth(\stereoPB,[\bufnum,~buffers[\death],\amp,0.5]);
						59.wait;
						30.do({
							~funcs[\pix].value(path ++ "pix/ink/ink%.jpg".format(20.rand),2.08,0,0);
							0.05.wait;
						});
						~funcs[\pix].value(path ++ "pix/ink/ink%.jpg".format(20.rand),2.08,0,0);
						~funcs[\fade].value(250,20);
						Window.closeAll;
					}).play(AppClock)
				}
			),
		]
	)
});
);

//  run the sucker!!
(
var date, doc;
date = Date.getDate.format("%d/%m/%Y");

doc = Document("SC Journal %".format(date),"//SC Journal %\n\n/*\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n*/".format(date));
doc.keyDownAction = ({
	arg view, char, modifiers, unicode, keycode;

	// [view, char, modifiers, unicode, keycode].postln;

	if(char.isPrint,{

		~text = ~text.rotate.put(0,unicode);

		for(0,~cues.size-1,{
			arg i;
			if(~text[..~cues[i][\string].size-1].reverse == ~cues[i][\string].collectAs({arg i; i.asUnicode},Array),{
				~cues[i][\func].value(doc)
			});
		});
	});
});
)