/* SC Journal #2 */

// window zooms!!
// post window wraps - yes
// main window wraps - yes
// turn off bracket completion
Server.default.options.device = "BlackHole 16ch"  // for recording

// MOMENTO MORI

(
var server = Server.default;
var path = "/Users/mikemccormick/Desktop/SCJ2/";       // folder of materials
var ampScale = 1;

server.options.device = "BlackHole 16ch";  // for recording

server.waitForBoot({

	/* Collections */

	~text = Array.fill(20,{0}); // consider .newClear(20)?

	/* Buffers */

	(
		~buffers = Dictionary[

			\breakthrough -> PathName(path ++ "hits/breakthrough/").entries.collect({ |sf|
				Buffer.read(server,sf.fullPath);
			}),

			\death -> Buffer.read(
				server,
				path ++ "hits/death.wav",
			),

			\deutsch -> PathName(path ++ "hits/deutsch/").entries.collect({ |sf|
				Buffer.read(server,sf.fullPath);
			}),

			\ping -> Buffer.readChannel(
				server,
				path ++ "hits/ping.wav",
				channels:[0,1],
			),

			\mori -> PathName(path ++ "hits/mori/").entries.collect({ |sf|
				Buffer.readChannel(server,sf.fullPath,channels: [0]);
			}),

			\pingReverse -> Buffer.readChannel(
				server,
				path ++ "hits/pingReverse.wav",
				channels:[0,1]
			),

			\pingMono -> Buffer.read(
				server,
				path ++ "hits/pingMono.wav",
			),
		]
	);

	server.sync;

	/* SynthDefs */

	(
		SynthDef(\monoPB,{
			var bufnum = \bufnum.kr;
			var sig = PlayBuf.ar(1,bufnum,BufRateScale.kr(bufnum) * \rate.kr(1),doneAction:2);
			sig = Pan2.ar(sig,\pan.kr(0),\amp.kr(1) * ampScale);
			Out.ar(\outBus.kr,sig);

		}).add;

		SynthDef(\stereoPB,{
			var bufnum = \bufnum.kr;
			var sig = PlayBuf.ar(2,bufnum,BufRateScale.kr(bufnum) * \rate.kr(1),doneAction:2);
			sig = Balance2.ar(sig[0],sig[1],\pan.kr(0),\amp.kr(1) * ampScale);
			Out.ar(\outBus.kr,sig);

		}).add;

		SynthDef(\sines,{
			var env = EnvGen.kr(Env.asr(\atk.kr(5),1,\rls.kr(0.1),2),\gate.kr(1),doneAction:2);
			var sig = SinOsc.ar(\freq.kr(1300));
			sig = Pan2.ar(sig*env,\pan.kr(0),\amp.kr(1) * ampScale);
			Out.ar(\outBus.kr,sig);

		}).add;

		SynthDef(\klik,{
			var env = EnvGen.kr(Env.perc(\atk.kr(0.02),\rls.kr(0.5)),1,doneAction: 2);
			var sig = WhiteNoise.ar(1!2).sum;
			sig = BPF.ar(sig,\filtFreq.kr(2000),0.8,25).clip(-1,1);
			sig = sig*env;
			sig = Pan2.ar(sig,\pan.kr(0),\amp.kr(1) * ampScale);
			Out.ar(\outBus.kr,sig);

		}).add;

		Ndef(\grainer,{
			var bufnum = \bufnum.kr;
			var impulseTrig = \impulseTrig.kr;
			var noise = impulseTrig.linexp(0.0,1.0,0.1,0.001);
			var rate = (\rate.kr(0.5).linexp(0.0,1.0,0.5,2.0)) + LFNoise2.kr(0.08,0.1);
			var trig = Impulse.kr(impulseTrig.linexp(0.0,1.0,0.3,12.0));
			var bufDur = BufDur.kr(bufnum);
			var pos = \pos.kr(0.5) + LFNoise1.kr(12,noise);

			TGrains.ar(2,trig,bufnum,BufRateScale.kr(bufnum) * rate,pos * bufDur,1.0,Latch.kr(LFNoise2.kr(0.05,0.7),trig),\amp.kr(1) * ampScale);
		});
	);

	server.sync;

	/* Patterns */
	(

		Pdef(\phantom,
			Ppar([
				Pbind(
					\instrument, \monoPB,
					\dur,0.25,
					\bufnum,Pseq([~buffers[\deutsch][6],~buffers[\deutsch][7]],inf),
					\rate,1,
					\pan,-1,
					\amp,Pseq([Pseg([0,0.5],15,\lin,1),Pseq([0.5],inf)],1),
					\outBus,0
				),
				Pbind(
					\instrument, \monoPB,
					\dur,0.25,
					\bufnum,Pseq([~buffers[\deutsch][7],~buffers[\deutsch][6]],inf),
					\rate,1,
					\pan,1,
					\amp,Pseq([Pseg([0,0.5],15,\lin,1),Pseq([0.5],inf)],1),
					\outBus,0
			)],inf)

		).quant_(0.25);
	);

	server.sync;

	/* Functions */

	(
		~funcs = Dictionary [

			\blink -> { |frames = 20|
				var window = Window("a",Window.screenBounds,false,false);

				window.background_(Color.black).front;

				Routine({
					frames.do({ |i|
						window.alpha = (i * frames.reciprocal);
						0.005.wait;
					});

					0.05.wait;

					frames.do({ |i|
						window.alpha = 1 - (i * frames.reciprocal);
						0.005.wait;
					});

					window.close;

				}).play(AppClock);

			},

			\clear -> { |document, start = 0, end|                                    // can pass the doc variable below into the first argument
				document.string_("//SC Journal %\n\n/*\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n*/".format(2),start,end)
			},

			\fade -> { |frames=200, pause=1|
				var window = Window("a",Window.screenBounds,false,false);
				window.background_(Color.black).front.alwaysOnTop;

				Routine({
					frames.do({ |i|
						window.alpha = (i * frames.reciprocal);
						0.005.wait;
					});

					pause.wait;

					window.close;

				}).play(AppClock);
			},

			\inked -> { |inks = 4, freq = 100|
				var array = Array.fill(inks,{20.rand});

				Routine({
					array.do({ |i|
						~funcs[\pix].value(path ++ "pix/ink/ink%.jpg".format(i),2.08,0,0);
						freq.reciprocal.wait;
						Window.closeAll;
					});
				}).play(AppClock);
			},


			\pedant -> {
				var bounds = Window.screenBounds;
				var window = Window("a",bounds,false,false);

				window.background_(Color.black);

				StaticText(window,window.bounds)
				.string_("PEDANT")
				.align_(\center)
				.stringColor_(Color.white)
				.font_(Font("menlo",120,true));

				window.front;
			},

			\pix -> { |string,scale,x,y|
				var img = Image.open(string);
				var rect = Rect(0,0,img.width * scale,img.height * scale);
				var window = Window("nope",Rect(x,y,rect.width,rect.height),true,false).front
				.background_(Color.clear);

				window.drawFunc_({
					img.drawInRect(rect,img.bounds)
				});
			},

			\pixFadeIn -> { |string,scale,x,y,frames=200|
				var img = Image.open(string);
				var rect = Rect(0,0,img.width * scale,img.height * scale);

				var window = Window("nope",Rect(x,y,rect.width,rect.height),true,false).front
				.background_(Color.clear)
				.alpha_(0);

				window.drawFunc_({
					img.drawInRect(rect,img.bounds)
				});

				Routine({
					frames.do({ |i|
						window.alpha = (i * frames.reciprocal);
						0.005.wait;
					});
				}).play(AppClock);
			},

			\post -> { |string,rate=0.1,click=true|

				if(click,{
					Routine({
						string.do({ |i|
							i.post;
							Synth(\klik,[\filtFreq,5000,\atk,0.001,\rls,0.001,\pan,0.5.rand2,\amp,0.05]);
							rate.exprand(2*rate).wait
						});
					}).play;
				},{
					Routine({
						string.do({ |i|
							i.post;
							rate.exprand(2*rate).wait;
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

			\wake -> { |frames=400, pause=3|
				var window = Window("a",Window.screenBounds,false,false);

				window.background_(Color.black).front;

				Routine({

					pause.wait;

					frames.do({ |i|
						window.alpha = 1 - (i * frames.reciprocal);
						0.005.wait;
					});

					window.close;
				}).play(AppClock);
			},
		]
	);

	server.sync;

	/**************************************************************************/

	(
		~cues = Dictionary[

			0 -> (
				string: "falling off.",
				func: { |document|

					Routine({
						0.6.wait;
						~funcs[\fade].value(200,1);
						3.4.wait;
						~funcs[\clear].value(document,0,1000);
						1.2.wait;
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
					Routine({
						0.5.wait;
						~funcs[\inked].value(1)
					}).play(AppClock)
				}
			),

			2 -> (
				string: "amount.",
				func: {
					~funcs[\post].value("...until heaven and earth pass away,\nnot an iota,\nnot a dot,\nwill pass from the Law until all is accomplished.\n\nMatthew 5:18\n",0.08)
				}
			),

			3 -> (
				string: "wear out",
				func: {
					2.do({|i| Synth(\monoPB,[\bufnum,~buffers[\mori][3],\rate,0.8 + [0.015,0].at(i),\pan,[-1,-0.8].at(i),\amp,0.04]);});
				}
			),

			4 -> (
				string: "introspect",
				func: {
					Routine({
						Synth(\monoPB,[\bufnum,~buffers[\breakthrough][0],\amp,0.6]);
						1.wait;
						~funcs[\post].value("I recorded this while walking to the metro station\n\n",0.08);
						6.5.wait;
						Synth(\monoPB,[\bufnum,~buffers[\breakthrough][1],\amp,0.6]);
						1.7.wait;
						~funcs[\post].value("in Istanbul\n\n",0.08);
						1.4.wait;
						Synth(\monoPB,[\bufnum,~buffers[\breakthrough][2],\amp,0.6]);
						2.7.wait;
						~funcs[\post].value("alone...\n\n",0.05);
						0.6.wait;
						~funcs[\post].value("          ",0.15,false);
						0.6.wait;
						Synth(\monoPB,[\bufnum,~buffers[\breakthrough][3]]);
						1.5.wait;
						~funcs[\post].value("...also alone...\n",0.15);
					}).play;
				}
			),

			5 -> (
				string: "destinat",
				func: { |document|
					Routine({
						Synth(\monoPB,[\bufnum,~buffers[\breakthrough][4]]);
						32.5.wait;
						~funcs[\wake].value(200,3);
						1.wait;
						~funcs[\clear].value(document,0,1000);
					}).play(AppClock);
				}
			),

			6 -> (
				string: "season",
				func: {
					~funcs[\post].value("or during a global pandemic...\n",0.12);
				}
			),

			7 -> (
				string: "repetitive",
				func: {
					Pdef(\phantom).play;
				}
			),

			8 -> (
				string: "illusion.",
				func: {
					~funcs[\post].value("Headphones interfere with the illusion!\n",0.1,false)
				}
			),

			9 -> (
				string: "unconscious.",
				func: {
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

			10 -> (
				string: "punctuation",
				func: {
					Pdef(\phantom,
						Ppar([
							Pbind(
								\instrument, \monoPB,
								\dur,0.25,
								\bufnum,Pseq([~buffers[\deutsch][6],~buffers[\deutsch][7]],inf),
								\rate,1,
								\pan,-1,
								\amp,Pseq([0.5],inf),                      // maybe the amp should * -3.dbamp ??
								\outBus,0
							),
							Pbind(
								\instrument, \monoPB,
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

			11 -> (
				string: "noise.",
				func: { |document|
					Routine({
						Pdef(\phantom,
							Ppar([
								Pbind(
									\instrument, \monoPB,
									\dur,0.25,
									\bufnum,Pseq([~buffers[\deutsch][6],~buffers[\deutsch][7]],inf),
									\rate,1,
									\pan,-1,
									\amp,Pseg([0.5,0.0],6,\lin,1),
									\outBus,0
								),
								Pbind(
									\instrument, \monoPB,
									\dur,0.25,
									\bufnum,Pseq([~buffers[\deutsch][6],~buffers[\deutsch][7]],inf),
									\rate,1,
									\pan,1,
									\amp,Pseg([0.5,0.0],6,\lin,1),
									\outBus,0
							)],1)
						);
						0.4.wait;
						~funcs[\fade].value(400,1);
						7.1.wait;
						~funcs[\clear].value(Document.current,0,2000);
						0.9.wait;
						Pdef(\phantom).stop;
						Synth(\stereoPB,[\bufnum,~buffers[\ping],\rate,0.8.rrand(1.2),\amp,0.8]);
						~funcs[\pix].value(path ++ "pix/letters/tau.png",1,150,50);
						3.wait;
						Window.closeAll;
					}).play(AppClock)
				}
			),

			12 -> (
				string: "ocean",
				func: {
					~funcs[\post].value("\"In this state, there is an unlimited mutual interpenetration between images, objects and concepts: opposites are undone, inner and outer worlds merge, death and birth become one, and the restrictions of space and time are dissolved.\"\n
Saarinen, J. (2015).\nThe Concept of the Oceanic Feeling in Artistic Creativity and in the Analysis of Visual Artworks.\nJournal of aesthetic education, 49 (3), 15-31.",0.05);
				}
			),

			13 -> (
				string: "connections",
				func: {
					Routine({
						25.do({|i|
							Synth(\monoPB,[\bufnum,~buffers[\mori][[2,3].choose],\rate,4.rrand(10.0),\pan,(0.2,0.4..1.0).choose * 1.rand2.sign,\amp,0.17 * 0.25.rrand(1.0)]);
							0.1.rrand(0.25).wait;
						})
					}).play
				}
			),

			14 -> (
				string: "trance...",
				func: {
					Routine({
						0.5.wait;
						~funcs[\inked].value(2,10);
						0.18.wait;
						~funcs[\pedant].value;
						0.18.wait;
						~funcs[\inked].value(1,10);
					}).play(AppClock)
				}
			),

			15 -> (
				string: "there?",
				func: { |document|
					Routine({
						2.wait;
						Synth(\stereoPB,[\bufnum,~buffers[\ping],\rate,0.8.rrand(1.2),\amp,0.8]);
						~funcs[\clear].value(document,0,2000);
						~funcs[\pix].value(path ++ "pix/letters/theta.png",1,150,50);
						5.wait;
						Window.closeAll;
					}).play(AppClock)
				}
			),

			16 -> (
				string: "inundat",
				func: {
					Pdef(\mori,
						Pbind(
							\instrument,\monoPB,
							\dur,Pseq([Pseg([1,0.15],[7],\exp,1),Pwhite(0.1,0.25,inf)],1),
							\bufnum,Pindex(~buffers[\mori],Pwrand([1,3],[0.5,0.5].normalizeSum,inf),inf),
							\rate,Prand([0.9],inf) + Pwhite(-0.01,0.01,inf),
							\pan,Prand([-1.0,-0.4,0,0.4,1.0],inf),
							\amp,Pseq([Pseg([0,1.0],[10],\lin,1),Pwrand([1,0.5,0.3],[0.7,0.2,0.1].normalizeSum,inf)],1) * 0.5,
						)
					).play
				}
			),

			17 -> (
				string: "imperm",
				func: {
					Routine({
						Pdef(\mori).stop;
						1.8.wait;
						2.do({|i| Synth(\monoPB,[\bufnum,~buffers[\mori][2],\rate,0.9 + [0,0.02].at(i),\pan,[-0.3,0.3].at(i),\amp,0.6])})
					}).play
				}
			),

			18 -> (
				string: "usual:",
				func: {
					Routine({
						0.5.wait;
						~funcs[\inked].value(3);
					}).play(AppClock)
				}
			),

			19 -> (
				string: "hometown",
				func: {
					Routine({
						~funcs[\pix].value(path ++ "pix/funeral.png",1,350,300);
						2.wait;
						~funcs[\post].value("Unconventional, but essential work, I guess...\n\n",0.1,true);
						7.wait;
						Window.closeAll
					}).play(AppClock)
				}
			),

			20 -> (
				string: "tests",
				func: {
					Routine({
						~funcs[\pix].value(path ++ "pix/docEditNor.png",0.5,250,250);
						2.wait;
						~funcs[\pixFadeIn].value(path ++ "pix/docEditEng.png",0.5,250,250,125);
						4.wait;
						~funcs[\post].value("I hope it isn't anything serious...\n\n",0.1,true);
						6.wait;
						Window.closeAll
					}).play(AppClock)
				}
			),

			21 -> (
				string: "hearing",
				func: {
					Routine({
						var left = Synth(\sines,[\pan,-1]);
						var right = Synth(\sines,[\pan,1]);
						~funcs[\post].value("Troubling news, especially for a musician...\n",0.1,false);
						4.wait;
						right.set(\gate,0);
						1.5.wait;
						left.set(\rls,3,\gate,0);
					}).play
				}
			),

			22 -> (
				string: "McCor",
				func: {
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

			23 -> (
				string: "differently:",
				func: { |document|
					Routine({
						var bounds = Window.screenBounds;
						var window = Window("a",bounds,false,false);
						var height = bounds.height*0.08;
						var offset = 20;
						var text;

						0.5.wait;
						~funcs[\ripAgain].value;
						10.wait;
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
						Ndef(\grainer).stop(fadeTime: 8);
						~funcs[\clear].value(document,0,2000);
						Window.closeAll
					}).play(AppClock)
				}
			),

			24 -> (
				string: "book",
				func: {
					~funcs[\post].value("Is it obvious I've been reading a lot recently?\n",0.08)
				}
			),

			25 -> (
				string: "purpose.",
				func: {
					~funcs[\post].value("Examples of immortality projects:\n\n-children\n\n-a garden\n\n-sourdough bread starter\n\n-\"art\" about your neuroses that will live on the internet forever\n\n",0.1)
				}
			),

			26 -> (
				string: "living",
				func: {
					Routine({
						1.wait;
						Synth(\stereoPB,[\bufnum,~buffers[\death],\amp,0.5]);
						2.wait;
						~funcs[\post].value("Geoffrey Scarre commenting on\n\nMartin Heidegger commenting on\n\nJean Paul Sartre\n\n",0.05,false);
						10.wait;
						~funcs[\post].value("and my comments",0.05,false);
						49.wait;
						30.do({
							~funcs[\pix].value(path ++ "pix/ink/ink%.jpg".format(20.rand),2.08,0,0);
							0.08.wait;
							Window.closeAll;
						});
						~funcs[\pix].value(path ++ "pix/ink/ink%.jpg".format(20.rand),2.08,0,0);
						1.4.wait;
						~funcs[\fade].value(250,20);
						20.wait;
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
// var date = Date.getDate.format("%d/%m/%Y");
var date = "23/08/2020";
var doc = Document("SC Journal %".format(date),"//SC Journal %\n\n/*\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n*/".format(date));

doc.keyDownAction = ({ |view, char, modifiers, unicode, keycode|
	// [view, char, modifiers, unicode, keycode].postln;

	~text = ~text.rotate.put(0,unicode);
	Synth(\klik,[\filtFreq,5000,\atk,0.001,\rls,0.001,\pan,0.5.rand2,\amp,0.05]);

	if(~text[..~cues[0][\string].size-1].reverse == ~cues[0][\string].collectAs({ |i| i.asUnicode},Array),{
		~cues[0][\func].value(doc);

		Document.current.keyDownAction = ({ |view, char, modifiers, unicode, keycode|
			if(char.isPrint,{

				~text = ~text.rotate.put(0,unicode);

				for(1,~cues.size-1,{ |i|
					if(~text[..~cues[i][\string].size-1].reverse == ~cues[i][\string].collectAs({ |i| i.asUnicode},Array),{
						~cues[i][\func].value(doc)
					});
				});
			});
		});
	});
});
)