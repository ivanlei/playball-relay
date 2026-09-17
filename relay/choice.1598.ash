// choice.1598.ash -- relay override for the Baseball Diamond's "Play Ball!" choice.
//
// Needs Ezandora's Choice-Override library (relay/choice.ash), which runs
// relay/choice.<id>.ash for each choice adventure. Install by copying this file
// into KoLmafia's relay/ folder.
//
// What it changes on the page:
//   - Each pitch button, and KoLmafia's spoiler note under it, is colored by the
//     pitch's element, using the wiki's element colors.
//   - The pitch buttons move out of their fixed spot near the bottom of the
//     stadium (where five of them overflow the frame) into the Lineup box, right
//     under the list of batters.
//   - Each batter you've already pitched to (KoL strikes them through) gets the
//     pitch you threw listed beside them, in its element's color.
//   - Each button carries its element's progress towards that element's major
//     pitch, as filled circles plus the major's name.
//   - The Lineup box's white background becomes semi-transparent, so the stadium
//     shows through behind the batters and buttons.
//   - The batter is hidden once the inning is over, when they would otherwise
//     stand in front of the result text.
//   - The Lineup box moves to whichever side of the field the batter isn't on,
//     since the batter shifts right as the inning goes on and would otherwise
//     stand in front of the pitch buttons.
//   - The stadium (a fixed 1000px-tall div) is trimmed to end just below the
//     Lineup box, and KoL's result box moves below the stadium instead of
//     overlapping the Lineup box.
//
// KoLmafia decorates choice pages (including those spoiler notes) before an
// override script runs, so the page this sees already has them.

import "relay/choice.ash";

record pitch_info {
	string name;     // the wiki's name for the pitch
	string element;
	boolean major;   // the element's third pitch: the one that gets an out
};

// Keyword found in a pitch's button text -> what that pitch is. Every pitch has
// a distinct button, and these keywords are the ones KoLmafia matches for its
// own spoilers.
pitch_info[string] playBallPitches() {
	pitch_info[string] pitches;
	pitches["Some Smoke"] = new pitch_info("Some Smoke", "hot", false);
	pitches["Bring the Heat"] = new pitch_info("Bring the Heat", "hot", false);
	pitches["Schenectady"] = new pitch_info("Schenectady Scorcher", "hot", true);
	pitches["Deep Freeze"] = new pitch_info("Deep Freeze", "cold", false);
	pitches["Snow Ball"] = new pitch_info("Snowball", "cold", false);
	pitches["Ice"] = new pitch_info("Ice Them Out", "cold", true);
	pitches["Ghost"] = new pitch_info("Ghost Pitch", "spooky", false);
	pitches["Skull"] = new pitch_info("Skullball", "spooky", false);
	pitches["Curveball"] = new pitch_info("Non-Euclidean Curveball", "spooky", true);
	pitches["Garbage"] = new pitch_info("Garbageball", "stench", false);
	pitches["Bean"] = new pitch_info("Beanball", "stench", false);
	pitches["Cheddar"] = new pitch_info("Some Cheddar", "stench", true);
	pitches["Slurve"] = new pitch_info("Slurveball", "sleaze", false);
	pitches["Slider"] = new pitch_info("Bacon-Wrapped Slider", "sleaze", false);
	pitches["Screwball"] = new pitch_info("Screwball", "sleaze", true);
	return pitches;
}

// The wiki's element colors (Template:Element/style.css).
string playBallElementColor(string elem) {
	switch (elem) {
		case "hot":    return "red";
		case "cold":   return "blue";
		case "spooky": return "#5a5a5a";  // darker than the wiki's grey, which is hard to read here
		case "stench": return "green";
		case "sleaze": return "blueviolet";
	}
	return "";
}

// Identify a pitch from a button's text ("Throw a Snow Ball") or from a name
// this script stored earlier ("Snowball"). The two don't always match - the
// keywords come from the buttons - so names are checked first.
pitch_info playBallIdentify(string text) {
	foreach keyword, info in playBallPitches() {
		if (text == info.name) return info;
	}
	foreach keyword, info in playBallPitches() {
		if (text.contains_text(keyword)) return info;
	}
	return new pitch_info("", "", false);
}


/*****************************************************
	Element progress

	Per the wiki: an element's major pitch is only offered once you've thrown
	both of that element's minor pitches this inning, and after throwing one
	minor you're offered only the other one until it's thrown. So what matters
	when choosing is how far along each element is, which _pbThrown answers.
*****************************************************/

string playBallMajorFor(string elem) {
	foreach keyword, info in playBallPitches() {
		if (info.element == elem && info.major) return info.name;
	}
	return "";
}

// Minor pitches thrown this inning per element, and whether that element's
// major has been thrown (it is only ever offered once per inning).
int[string] playBallMinorsThrown(boolean[string] majorThrown) {
	int[string] minors;
	foreach elem in $strings[hot, cold, spooky, stench, sleaze] {
		minors[elem] = 0;
		majorThrown[elem] = false;
	}
	foreach i, entry in split_string(get_property("_pbThrown"), "\\|") {
		string[int] parts = split_string(entry, "=");
		if (parts.count() != 2) continue;
		pitch_info info = playBallIdentify(parts[1]);
		if (info.element == "") continue;
		if (info.major) {
			majorThrown[info.element] = true;
			minors[info.element] = 0;  // the cycle restarts after the major
		} else {
			minors[info.element] = minors[info.element] + 1;
		}
	}
	return minors;
}

// One progress marker: a filled circle for a minor already thrown, an empty one
// for a minor still to throw. The line around it is already in the element's
// colour, so the circles inherit it.
string playBallCircle(boolean thrown) {
	// Bigger than the 10px line they sit in, so they read at a glance.
	return "<span style=\"font-size: 15px; vertical-align: -2px\">"
		+ (thrown ? "&#9679;" : "&#9675;") + "</span>";
}

// The line under a pitch button: this element's progress towards its major
// pitch, as circles, and the major they lead to. An element's major is offered
// once per inning, so after it's thrown that element is done.
string playBallProgressNote(pitch_info info, int minorsDone, boolean majorDone) {
	string major = playBallMajorFor(info.element);
	if (info.major) {
		return playBallCircle(true) + playBallCircle(true) + " &rarr; <b>gets an out</b>";
	}
	if (majorDone) return "&#10003; " + major + " thrown";

	return playBallCircle(minorsDone >= 1) + playBallCircle(minorsDone >= 2) + " &rarr; " + major;
}

/*****************************************************
	Remembering pitches thrown this inning

	The page never says what you threw at a batter, so the script records it.
	When you click a pitch, KoLmafia serves the next page through this override
	with the form fields you submitted, which give the option number but not the
	button's text - each batter is offered a random five. So every render stores
	the pitches on offer and who is at bat, and the next render turns the
	submitted option number back into a pitch name.

	Both preferences start with "_", so KoLmafia clears them at rollover.
	_pbOffered: "<batter>|<option>=<pitch>|..."   what the last page offered
	_pbThrown:  "<batter>=<pitch>|..."            what was thrown this inning
*****************************************************/

string playBallLookup(string list, string key) {
	foreach i, entry in split_string(list, "\\|") {
		string[int] parts = split_string(entry, "=");
		if (parts.count() == 2 && parts[0] == key) return parts[1];
	}
	return "";
}

void playBallRecordThrow(string option) {
	string offered = get_property("_pbOffered");
	if (offered == "" || option == "") return;

	string[int] parts = split_string(offered, "\\|");
	if (parts.count() < 2) return;
	string batter = parts[0];
	string pitch = playBallLookup(offered, option);
	if (batter == "" || pitch == "") return;

	string thrown = get_property("_pbThrown");
	if (playBallLookup(thrown, batter) != "") return;  // already recorded (page reload)
	set_property("_pbThrown", (thrown == "" ? "" : thrown + "|") + batter + "=" + pitch);
}

/*****************************************************
	Page decoration
*****************************************************/

// Color one pitch form: the form's own color is inherited by the spoiler note
// inside it, and the button gets the color explicitly, since buttons don't
// inherit text color.
string playBallColorForm(string form, int[string] minorsDone, boolean[string] majorDone) {
	matcher submit = create_matcher("<input type=\"submit\" value=\"([^\"]*)\"", form);
	if (!submit.find()) return form;
	pitch_info info = playBallIdentify(submit.group(1));
	string color = playBallElementColor(info.element);
	if (color == "") return form;

	// KoLmafia's spoiler note repeats "to Baseball Diamond enchants" on most
	// pitches, and tags the Garbageball's drops with their quality; neither adds
	// anything here, and both cost a line of space.
	string trimmed = form.replace_string(" to Baseball Diamond enchants", "");
	trimmed = trimmed.replace_string(" (awesome food / booze)", "");

	string colored = trimmed.replace_string("<form method=\"post\"",
		"<form style=\"color: " + color + "; margin: 0.6em 0\" method=\"post\"");
	colored = colored.replace_string(submit.group(0),
		submit.group(0) + " style=\"color: " + color + "; border-color: " + color + "\"");

	// Where this pitch sits on the way to its element's major, under KoLmafia's
	// own spoiler note.
	return colored.replace_string("</form>",
		"<br><span style=\"font-size: 10px; font-style: italic\">"
		+ playBallProgressNote(info, minorsDone[info.element], majorDone[info.element]) + "</span></form>");
}

// Write the pitch thrown at each struck-through batter beside their name.
string playBallAnnotateLineup(string page) {
	string thrown = get_property("_pbThrown");
	if (thrown == "") return page;

	string out = page;
	matcher struck = create_matcher("(?s)<s>\\s*(\\d+)\\.[^<]*</s>", page);
	while (struck.find()) {
		string pitch = playBallLookup(thrown, struck.group(1));
		if (pitch == "") continue;
		string color = playBallElementColor(playBallIdentify(pitch).element);
		out = out.replace_string(struck.group(0),
			struck.group(0) + "<span style=\"color: " + color + "; margin: 0 0.45em\">" + pitch + "</span>");
	}
	return out;
}

// The stadium is a div with a fixed 1000px height and the field as its
// background, most of which is empty once the pitches move up into the Lineup
// box. Its height has to be measured in the browser (the Lineup box grows with
// the roster and the buttons), so this adds a script that shrinks it on load.
//
// The same script moves KoL's result box (#output, absolutely positioned inside
// the stadium where it overlaps the Lineup box) out below the stadium, and
// converts the bottom-anchored batter and bat to top-based positions, since
// shrinking the stadium would otherwise drag them along.
string playBallTrimStadium(string page) {
	// After the ninth pitch only the "Inning Over!" button is left, and the
	// batter just stands in front of the result text.
	boolean inningOver = page.contains_text("Inning Over!");
	matcher stadium = create_matcher("<div style=\"position: relative; background-image: url\\(([^)]*)\\);", page);
	if (!stadium.find()) return page;

	string tagged = page.replace_string(stadium.group(0),
		"<div id=\"pbStadium\" style=\"position: relative; background-repeat: no-repeat; background-image: url(" + stadium.group(1) + ");");

	string script = "<script>(function(){"
		+ "function layout() {"
		+ "var stadium = document.getElementById('pbStadium');"
		+ "var lineup = document.getElementById('pbLineup');"
		+ "if (!stadium || !lineup) return;"
		// KoL's result text sits on top of the Lineup box; put it under the field.
		+ "var output = document.getElementById('output');"
		+ "if (output && output.parentNode === stadium) {"
		+ "  stadium.parentNode.insertBefore(output, stadium.nextSibling);"
		+ "  output.style.position = 'static';"
		+ "  output.style.maxHeight = 'none';"
		+ "  output.style.margin = '6px auto 0 auto';"
		+ "}"
		// Freeze bottom-anchored children (the batter and bat) where they are now.
		+ "var box = stadium.getBoundingClientRect();"
		+ "var kids = stadium.querySelectorAll('div, img, canvas');"
		+ "for (var i = 0; i < kids.length; i++) {"
		+ "  var k = kids[i];"
		+ "  if (getComputedStyle(k).position !== 'absolute') continue;"
		+ "  if (k.style.bottom === '' || k.style.bottom === 'auto') continue;"
		+ "  k.style.top = (k.getBoundingClientRect().top - box.top) + 'px';"
		+ "  k.style.bottom = 'auto';"
		+ "}"
		// The batter walks rightwards through the lineup, so keep the Lineup box
		// on the other side of the field from wherever they're standing.
		+ "var batter = document.getElementById('batter');"
		+ "var stand = batter ? batter.parentNode : null;"
		+ (inningOver ? "if (stand) { stand.style.display = 'none'; stand = null; }" : "")
		+ "if (stand) {"
		+ "  var r = stand.getBoundingClientRect();"
		+ "  var onRight = ((r.left + r.right) / 2 - box.left) > (box.width / 2);"
		+ "  lineup.style.left = onRight ? '4px' : 'auto';"
		+ "  lineup.style.right = onRight ? 'auto' : '4px';"
		+ "}"
		// With the inning over there's no batter to avoid, so centre the box.
		+ (inningOver ? "lineup.style.left = '50%'; lineup.style.right = 'auto'; lineup.style.transform = 'translateX(-50%)';" : "")
		// End the stadium a little below whichever sits lower, the Lineup box or
		// the batter.
		+ "var lowest = lineup.getBoundingClientRect().bottom;"
		+ "if (stand) lowest = Math.max(lowest, stand.getBoundingClientRect().bottom);"
		// Never crop below this, or the field turns into a sliver of stands.
		+ "var wanted = Math.ceil(lowest - stadium.getBoundingClientRect().top + 20);"
		+ "stadium.style.height = Math.max(wanted, 520) + 'px';"
		+ "}"
		// Once now, and again after images load, when the batter's size is known.
		+ "layout();"
		+ "window.addEventListener('load', layout);"
		+ "})();</script>";

	return tagged + script;
}

string decoratePlayBall(string page, string submittedOption) {
	// A fresh inning: nobody struck through yet, so forget the last one.
	if (!page.contains_text("<s>")) {
		set_property("_pbThrown", "");
	} else {
		playBallRecordThrow(submittedOption);
	}

	// The pitch buttons live in <div id="pitches">, absolutely positioned near the
	// bottom of the stadium. It holds only forms, no nested divs.
	matcher pitchesDiv = create_matcher("(?s)<div id=\"pitches\"[^>]*>(.*?)</div>", page);
	if (!pitchesDiv.find()) return playBallTrimStadium(playBallAnnotateLineup(page));

	// Remember what's on offer and who's at bat, so the next page can name the
	// pitch this one throws.
	matcher atBat = create_matcher("<b>(\\d+)\\.[^<]*</b>", page);
	buffer offered;
	if (atBat.find()) {
		offered.append(atBat.group(1));
		matcher form = create_matcher("(?s)<form.*?</form>", pitchesDiv.group(1));
		while (form.find()) {
			matcher option = create_matcher("name=\"option\" value=\"(\\d+)\"", form.group(0));
			matcher submit = create_matcher("<input type=\"submit\" value=\"([^\"]*)\"", form.group(0));
			if (option.find() && submit.find()) {
				string name = playBallIdentify(submit.group(1)).name;
				if (name != "") offered.append("|" + option.group(1) + "=" + name);
			}
		}
		set_property("_pbOffered", offered.to_string());
	}

	boolean[string] majorThrown;
	int[string] minorsDone = playBallMinorsThrown(majorThrown);

	buffer forms;
	matcher form2 = create_matcher("(?s)<form.*?</form>", pitchesDiv.group(1));
	while (form2.find()) {
		forms.append(playBallColorForm(form2.group(0), minorsDone, majorThrown));
	}
	if (forms.length() == 0) return playBallTrimStadium(playBallAnnotateLineup(page));

	// The Lineup box ends with the batter list's </small>; the pitches go right
	// after it, inside the box, so they sit under the batters however long the
	// list is.
	matcher lineupEnd = create_matcher("(?s)(<b>Lineup</b>.*?</small>)", page);
	if (!lineupEnd.find()) return playBallTrimStadium(playBallAnnotateLineup(page));

	string withoutOld = page.replace_string(pitchesDiv.group(0), "");
	string moved = withoutOld.replace_string(lineupEnd.group(1),
		lineupEnd.group(1) + "<div id=\"pitches\" style=\"text-align: center; margin-top: 1em\">" + forms + "</div>");

	// Only the box's background goes translucent (rgba), not the box itself, so
	// the batters and buttons stay fully opaque. At 0.7 the stadium's line art
	// made the text hard to read, so it's mostly opaque, and a white glow behind
	// the text keeps letters clear where lines pass behind them.
	matcher lineupBox = create_matcher("(?s)(<div )(style=\"[^\"]*?)background: white;([^\"]*\">\\s*<center><b>Lineup</b>)", moved);
	if (lineupBox.find()) {
		moved = moved.replace_string(lineupBox.group(0),
			lineupBox.group(1) + "id=\"pbLineup\" " + lineupBox.group(2)
			+ "background: rgba(255, 255, 255, 0.85); text-shadow: 0 0 2px white, 0 0 4px white;"
			+ lineupBox.group(3));
	}

	// The heading only repeats what the box obviously is, and its padding pushes
	// the batters down; both anchors above have been matched by now. KoL wraps
	// the batter list in <small>, which is hard to read against the stadium, so
	// that goes too and the names render at the box's own size.
	moved = moved.replace_string("<center><b>Lineup</b><br><br></center>", "");
	moved = moved.replace_string("<small>", "").replace_string("</small>", "");
	moved = moved.replace_string("id=\"pbLineup\" style=\"position: absolute; width: 280px;",
		"id=\"pbLineup\" style=\"position: absolute; width: 280px; padding-top: 0.5em;");

	return playBallTrimStadium(playBallAnnotateLineup(moved));
}

void main(string page_text_encoded) {
	string page_text = page_text_encoded.choiceOverrideDecodePageText();

	// The fields just submitted: whichchoice=1598 and the option number of the
	// pitch clicked, when this page follows a pitch.
	string option = "";
	string[string] fields = form_fields();
	if ((fields contains "option") && (fields contains "whichchoice") && fields["whichchoice"] == "1598") {
		option = fields["option"];
	}

	write(decoratePlayBall(page_text, option));
}
