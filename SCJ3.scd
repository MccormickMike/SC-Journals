// SCJ3

// Explore the Environment help file
// write classes and/or functions that behave differently in different environments?
// Could be way to create a text with behaviours that are unpredictable...
// In that case, could type up the text w/o comment lines and take advantage of the syntax highlighting?

// can also use WebView.enterInterpretsSelection to make use of new "classes" on webpages...

// MainMenu Helpfile - can create a custom menu...???!??!

// Look into History help documentation as a way to automate typed...performances?


// facebook info can be exported as JSON files...could be interesting to scrape that data, no?


// consider introducing more of an Oulipoian approach in the future...maybe a "script" is just a list? A recipe? A tweet? Etc.
// could also be a ritual - writing the same block of code/text several times, things are triggered....
// then a "reset," typing out the same code/text again but different things happen...


// one of these doesn't have to be in the SC IDE, obviously...will the Document methods work the same way in Atom, for example?
// or I could do a piece in TextEdit, terminal, etc. or switch between several throughout the course of the piece.


// consider making SCJournal Classes - unicode Parser, File/App opener, etc.
// Maybe a class like Entry(dateArg ? getDate,{points to dictionary with string cues and functions},etc.)
// does all the text parsing...maybe it's not that flexible however?

// Cambridge change





// consider?
Document.current.textChangedAction_({nil})

"open -a terminal".unixCmd
"processing-java --sketch='/Users/mikemccormick/Desktop/test/'' --run".unixCmd{ |res, pid| [\done, res, pid].postln } // doesn't work yet...


// attempt at pixel sorting - must investigate!!
(
i = Image("/Users/mikemccormick/Desktop/Screen Shot 2020-05-04 at 10.25.49 PM (2).png");
i.pixels = i.pixels.sort;
i.interpolation_(\fast);
i.plot(name: "nil",bounds: Rect(400,400,i.width/2,i.height/2), showInfo: false)
)



// this worked pretty well although ~cues was a dictionary of events
// next time it can just be ~cues.add("string" -> {func}) and the below code can be adjusted accordingly.

(
var date = Date.getDate.format("%d/%m/%Y");

var doc = Document("SC Journal %".format(date),"//SC Journal %\n\n/*\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n*/".format(date));
doc.keyDownAction = ({ |view, char, modifiers, unicode, keycode|

	// [view, char, modifiers, unicode, keycode].postln;

	if(char.isPrint,{

		~text = ~text.rotate.put(0,unicode);

		for(0,~cues.size-1,{ |i|
			if(~text[..~cues[i][\string].size-1].reverse == ~cues[i][\string].collectAs({ |i| i.asUnicode},Array),{
				~cues[i][\func].value(doc)
			});
		});
	});
});
)
