// SVG initialization and tools
var SVGNS = 'http://www.w3.org/2000/svg';
var HTMLNS = 'http://www.w3.org/1999/xhtml';

var USE_SVG = document.implementation.hasFeature("http://www.w3.org/TR/SVG11/feature#BasicStructure", "1.1");

function setAttrs(e, attributeMap) {
	if (attributeMap != null)
		for (var name in attributeMap)
			e.setAttribute(name, attributeMap[name]);
}

function newElem(ns, name, attributeMap, children) {
	var e = document.createElementNS(ns, name);
	setAttrs(e, attributeMap);
	if (children != null)
		for (var i = 0; i < children.length; i++)
			e.appendChild(children[i]);
	return e;
}

function newText(text) {
	return document.createTextNode(text);
}

function removeChildren(e) {
	while (e.children.length > 0)
		e.removeChild(e.children[0]);
}

// Manages a smooth transition of a set of XML attributes and CSS styles from one value to another. You
// can also pass a running transition, which will then be modified accordingly.
//
// The transition is described by the following data structure:
//   durationMs - duration of the transition in milliseconds
//   steps - the number of steps for a complete transition
//   currentState - the current state: 0 for the first state, 1 for the second state, or any number in between for transitional states
//   requestedState - the requested state: 0 for the first state or 1 for the second state
//   intervalId - if not null, the currently running interval timer id. Used internally.
//   startFrom0Cb - if not null, a callback to be invoked when the value changes from 0
//   startFrom1Cb - if not null, a callback to be invoked when the value changes from 1
//   endTo0Cb - if not null, a callback to be invoked when the value changes to 0
//   endTo1Cb - if not null, a callback to be invoked when the value changes to 1
//   transitionEndCb - if not null, will be called when transition ended
//   properties - a list of properties to change for each transition step. Each entry contains the following values:
//      type - 'xml' for XML attributes, 'css' for CSS styles, or 'csscolor' for CSS styles with color codes
//      obj - the element to modify
//      name - the name of the XML attribute or CSS style
//      s0 - value for state 0; 'xml' or 'css': a number; 'csscolor': a hex color (rrggbb)
//      s1 - value for state 1
//      precision - the number of post-decimal places for numeric values (null = 6)
//      postfix - an optional postfix for the numeric value to set, e.g. 'px' or 'em'
//      prefix - an optional prefix for the numeric value to set
function startTransition(desc) {
	if (desc.intervalId != null)
		clearInterval(desc.intervalId);
	if (desc.currentState == desc.requestedState)
		return;

	setTransitionProperties(desc, null);
	
	desc.intervalId = setInterval(function() {
		var oldState = desc.currentState;
		var d = ((desc.requestedState < desc.currentState) ? -1 : 1) / desc.steps;
		desc.currentState = Math.min(1, Math.max(0, desc.currentState + d));
		if (desc.currentState == 0 || desc.currentState == 1) {
			clearInterval(desc.intervalId);
			desc.intervalId = null;
		}
		setTransitionProperties(desc, oldState);
	}, desc.durationMs / desc.steps);
}


// Sets the properties of a transition for the current state, and optionally calls callbacks.
// desc - the descriptor (see startTransition)
// previousState - if not null, the previous state of the transition. Used to invoke the callbacks.
function setTransitionProperties(desc, previousState) {
	var state = desc.currentState;
	for (var i = 0; i < desc.properties.length; i++) {
		var p = desc.properties[i];
		var val;
		if (p.type == 'xml' || p.type == 'css') {
			var prec = (desc.precision == null) ? 6 : desc.precision;
			val = (p.prefix == null ? '' : p.prefix) + (state*p.s1 + (1-state)*p.s0).toFixed(prec) + (p.postfix == null ? '' : p.postfix);
		}
		else
			val = '#' + interpolateColor(p.s0, p.s1, state);

		if (p.type == 'xml')
			p.obj.setAttribute(p.name, val);
		else if (p.type == 'css' || p.type == 'csscolor')
			p.obj.style.setProperty(p.name, val, null);
		else
			throw 'Unknown property type: ' + p.type;
	}
	
	if (previousState != null) {
		if (previousState == 0 && state > 0 && desc.startFrom0Cb != null)
			desc.startFrom0Cb();
		else if (previousState == 1 && state < 1 && desc.startFrom1Cb != null)
			desc.startFrom1Cb();
		else if (state == 0 && previousState > 0 && desc.endTo0Cb != null)
			desc.endTo0Cb();
		else if (state == 1 && previousState < 1 && desc.endTo1Cb != null)
			desc.endTo1Cb();
		
		if (desc.transitionEndCb != null &&
				((state == 0 && previousState > 0) || (state == 1 && previousState < 1)))
			desc.transitionEndCb();
	}
}

// interpolates the given color in format 'rrggbb' using the factor p for color0 and 1-p for color1. Returns the result in the same format.
function interpolateColor(color0, color1, p) {
	var r = Math.round((1-p) * parseInt('0x' + color0.substr(0, 2)) + p * parseInt('0x' + color1.substr(0, 2)));
	var g = Math.round((1-p) * parseInt('0x' + color0.substr(2, 2)) + p * parseInt('0x' + color1.substr(2, 2)));
	var b = Math.round((1-p) * parseInt('0x' + color0.substr(4, 2)) + p * parseInt('0x' + color1.substr(4, 2)));
	return ((r < 16) ? '0' : '') + r.toString(16) +
		   ((g < 16) ? '0' : '') + g.toString(16) + 
		   ((b < 16) ? '0' : '') + b.toString(16);
} 

// Starts an animation sequence, consisting of one or more transitions that will be executed in order.
// You do not need to set currentState and requestedState in the transitions, they will be automatically set to 0 and 1.
// Also, transitionEndCb will be overwritten by the function.
// transitions - a list of transition descriptions
// skip - if not null, the number of transitions to skip
function startAnimationSequence(transitions, skip) {
	var s = skip == null ? 0 : skip;
	if (transitions.length <= s)
		return;
	
	var desc = transitions[s];
	desc.currentState = 0;
	desc.requestedState = 1;
	desc.transitionEndCb = function() {
		startAnimationSequence(transitions, s+1);
	};
	startTransition(desc);
}

// Gets the coordinate of node elem relative to the <body>. initialOffset is only used internally!. 
function getBodyCoords(elem, initialOffset) {
	if (elem.getBoundingClientRect != null) {
		var c = elem.getBoundingClientRect();
		return [c.left+window.scrollX, c.top+window.scrollY];
	}
	
	var r;
	if (initialOffset != null)
		r = [elem.offsetLeft + initialOffset[0], elem.offsetTop + initialOffset[1]];
	else
		r = [elem.offsetLeft, elem.offsetTop];

	if (elem.offsetParent == null)
		return r;
	else
		return getBodyCoords(elem.offsetParent, r);
}

var lastSmoothScrollId = null;

// scrolls smothly to the given id. Optionally calls doneCb when done.
function smoothScrollTo(id, doneCb) {
	if (lastSmoothScrollId != null)
		clearInterval(lastSmoothScrollId);
	
	var durationMs = 250;
	var stepsLeft = 5;
	var startY = window.scrollY;
	var endY = getBodyCoords(document.getElementById(id))[1];
	var d = (endY - startY) / stepsLeft;
	lastSmoothScrollId = setInterval(function() {
		if (d != 0 && stepsLeft-- > 0)
			window.scrollBy(0, d);
		else {
			clearInterval(lastSmoothScrollId);
			lastSmoothScrollId = null;
			window.scrollTo(window.scrollX, endY);
			if (doneCb != null)
				doneCb();
		}
	}, durationMs / stepsLeft);
}

////////////////////////////////////////////////////////////////////
//popup functions


var TT_MARGIN = 4; // margin for non-SVG background

var TTS_MARGIN = 10; // for SVG background
var TTS_POINTER_POS_X = 30;
var TTS_POINTER_HEIGHT = 28;
var TTS_POINTER_WIDTH = 24;

var TT_BASE_OFFSET = USE_SVG ? [0, TTS_MARGIN+TTS_POINTER_HEIGHT] : [15, 10];

var toolTipCheckerIntervalId = null;

function Tooltip(closeButtonBar, zIndex, bgColor, borderColor) {
	this.closeButtonBar = closeButtonBar;
	this.zIndex = zIndex;
	this.bgColor = bgColor;
	this.borderColor = borderColor;

	this.active = false;
	this.linkId = null;
	this.tooltipId = null;
	this.oldLinkClass = null;
	this.originalWidth = null;
	this.backgroundElement = null;
}

var clickTooltip = new Tooltip('ttCloseBar', 80, '#fff8b0', "#ccc");
var mouseoverTooltip = new Tooltip(null, 95, '#fff8b0', "#ccc");
var clickTopic = new Tooltip('topicCloseBar', 85, '#bfffb8', "#444");
var mouseoverTopic = new Tooltip(null, 90, '#bfffb8', "#444");

var tooltips = [clickTooltip, mouseoverTooltip, clickTopic, mouseoverTopic];




function hideToolTip(tooltipObj) {
	if (!tooltipObj.active)
		return;
	document.getElementById(tooltipObj.linkId).className = tooltipObj.oldLinkClass;
	document.getElementById(tooltipObj.tooltipId).style.display = 'none';
	document.getElementById('body').removeChild(tooltipObj.backgroundElement);

	if (tooltipObj.closeButtonBar != null) document.getElementById(tooltipObj.closeButtonBar).style.display = 'none';
	tooltipObj.active = false;
}

function showToolTipSvgBackground(baseC, contentWidth, contentHeight, pointerOffsetX, tooltipObj) {
	
	var pointerX = Math.min(Math.max(TTS_MARGIN*2, TTS_POINTER_POS_X + pointerOffsetX), contentWidth-TTS_POINTER_WIDTH-2*TTS_MARGIN);
	var w = contentWidth + 2 * TTS_MARGIN;
	var h = contentHeight + TTS_POINTER_HEIGHT + 2 * TTS_MARGIN;
	var BUGGY_WEBKIT_CONSTANT = 500; // svg-area must be larger than actually needed, otherwise zooming out in webkit fails
	
	var div = newElem(HTMLNS, 'div', {'class':'tooltipSvgBackground'});
	var svg = newElem(SVGNS, 'svg', {width: (w+BUGGY_WEBKIT_CONSTANT)+'px', height: (h+BUGGY_WEBKIT_CONSTANT)+'px'});
	div.appendChild(svg);
	svg.appendChild(newElem(SVGNS, 'path', {fill: tooltipObj.bgColor, stroke: tooltipObj.borderColor, "stroke-width": "2",
		d: "M " + pointerX + " "+ TTS_POINTER_HEIGHT+ " " +
		   "C " + (pointerX + Math.round(TTS_POINTER_WIDTH/4)) + " "+Math.round(TTS_POINTER_HEIGHT/2)+" "+ 
	          (pointerX + Math.round(TTS_POINTER_WIDTH/4)) + " "+Math.round(TTS_POINTER_HEIGHT/2)+" "+
	          pointerX + " 1 " +
	   "L " + (pointerX + TTS_POINTER_WIDTH) + " " + TTS_POINTER_HEIGHT + " " +
	   "H " + (w-TTS_MARGIN) + " "+
	   "C " + (w-1) + " " + TTS_POINTER_HEIGHT + " " +
	   		  (w-1) + " " + TTS_POINTER_HEIGHT + " " +
	   		  (w-1) + " " + (TTS_POINTER_HEIGHT + TTS_MARGIN) + " " +
	   "V " + (h - TTS_MARGIN) + " " +  
	   "C " + (w-1) + " " + (h-1) + " " +
	   		  (w-1) + " " + (h-1) + " " +
	          (w - TTS_MARGIN) + " " + (h-1) + " " +
	   "H " + TTS_MARGIN + " " +
	   "C 1 " + (h-1) + " "+
	     "1 " + (h-1) + " "+
	     "1 " + (h - TTS_MARGIN) + " " +
	   "V " + (TTS_POINTER_HEIGHT + TTS_MARGIN) + " " +
	   "C 1 " + TTS_POINTER_HEIGHT + " "+
	     "1 " + TTS_POINTER_HEIGHT + " "+
	     TTS_MARGIN + " " + TTS_POINTER_HEIGHT + " " +
	   "Z"}));
	
	var bs = div.style;
	bs.left = (baseC[0] - TTS_MARGIN) + 'px';
	bs.top = (baseC[1] - TTS_MARGIN - TTS_POINTER_HEIGHT) + 'px';
	bs.width = w + 'px';
	bs.height = h + 'px';
	bs.zIndex = tooltipObj.zIndex;
	bs.display = 'block';
	
	document.getElementById('body').appendChild(div);
	tooltipObj.backgroundElement = div;
}

function showToolTipBackground(baseC, contentWidth, contentHeight, tooltipObj) {
	var div = newElem(HTMLNS, 'div', {'class':'tooltipBackground'});
	var bs = div.style;
	bs.left = (baseC[0] - TT_MARGIN) + 'px';
	bs.top = (baseC[1] - TT_MARGIN) + 'px';
	bs.width = (contentWidth + 2 * TT_MARGIN) + 'px';
	bs.height = (contentHeight + 2 * TT_MARGIN) + 'px';
	bs.zIndex = tooltipObj.zIndex;
	bs.display = 'block';

	document.getElementById('body').appendChild(div);
	tooltipObj.backgroundElement = div;
}

function showToolTip(linkId, tooltipId, tooltipObj) {
	hideToolTip(tooltipObj);
	tooltipObj.linkId = linkId;
	tooltipObj.tooltipId = tooltipId;
	
	var link = document.getElementById(linkId);
	tooltipObj.oldLinkClass = link.className;
	link.className = 'visibleTooltip';
	
	var coords = getBodyCoords(link);
	var baseC = [Math.round(coords[0] + Math.min(link.offsetWidth / 3, 12) + TT_BASE_OFFSET[0]), coords[1] + link.offsetHeight + TT_BASE_OFFSET[1]];
	
	var tt = document.getElementById(tooltipId);
	
	var closeBarOffset = 0;
	if (tooltipObj.closeButtonBar != null) {
		var closeBar = document.getElementById(tooltipObj.closeButtonBar);
		closeBar.style.left = baseC[0] + 'px';
		closeBar.style.top  = baseC[1]  + 'px';
		closeBar.style.zIndex = tooltipObj.zIndex + 1;
		closeBar.style.display = 'block';
		closeBarOffset = closeBar.offsetHeight + 2;
	}
	
	tt.style.left = baseC[0] + 'px';
	tt.style.top  = (baseC[1] + closeBarOffset)  + 'px';
	tt.style.zIndex = tooltipObj.zIndex + 2;
	tt.style.display = 'block';
	
	if (tooltipObj.closeButtonBar != null)
		document.getElementById(tooltipObj.closeButtonBar).style.width = tt.offsetWidth + 'px';
	
	var contentWidth = tt.offsetWidth;
	var contentHeight = tt.offsetHeight + closeBarOffset;
	if (USE_SVG)
		showToolTipSvgBackground(baseC, contentWidth, contentHeight, 0, tooltipObj);
	else
		showToolTipBackground(baseC, contentWidth, contentHeight, tooltipObj);
	
	tooltipObj.originalWidth = tt.offsetWidth;
	tooltipObj.active = true;
}

function refreshToolTips() {
	for (var i = 0; i < tooltips.length; i++)
		if (tooltips[i].active)
			showToolTip(tooltips[i].linkId, tooltips[i].tooltipId, tooltips[i]);
}

function genericClick(linkId, tooltipId, mouseoverObj, clickObj) {
	if (mouseoverObj.active && (tooltipId == mouseoverObj.tooltipId || linkId == mouseoverObj.linkId)) 
		hideToolTip(mouseoverObj);
	
	if (clickObj.active && clickObj.linkId == linkId)
		hideToolTip(clickObj);
	else
		showToolTip(linkId, tooltipId, clickObj);
	return false;
}

function genericOver(linkId, tooltipId, mouseoverObj, clickObj) {
	if (clickObj.active && (tooltipId == clickObj.tooltipId || linkId == clickObj.linkId))
		return false;
	showToolTip(linkId, tooltipId, mouseoverObj);
	return false;
}

function tlClick(linkId, tooltipId) {
	return genericClick(linkId, tooltipId, mouseoverTooltip, clickTooltip);
}

function tlOver(linkId, tooltipId) {
	return genericOver(linkId, tooltipId, mouseoverTooltip, clickTooltip);
}

function tlOut(linkId, tooltipId) {
	hideToolTip(mouseoverTooltip);
	return false;
}

function tlClose() {
	hideToolTip(clickTooltip);
	return false;
}

function tpcClick(linkId, tooltipId) {
	return genericClick(linkId, tooltipId, mouseoverTopic, clickTopic);
}

function tpcOver(linkId, tooltipId) {
	return genericOver(linkId, tooltipId, mouseoverTopic, clickTopic);
}

function tpcOut(linkId, tooltipId) {
	hideToolTip(mouseoverTopic);
	return false;
} 

function tpcClose() {
	hideToolTip(clickTopic);
	return false;
}

function tooltipKeyPressHandler(e) {
    if (e.keyCode == 27) {
    	for (var i = 0; i < tooltips.length; i++)
    		if (tooltips[i].active && tooltips[i].closeButtonBar != null)
    			hideToolTip(tooltips[i]);
    	return false;
    }
}
 



////////////////////////////////////////////////////////////////
// section open/close/goto

// internal: hides section with the first id, shows the second	
function reverseCollapsedSection(hideThisId, showThisId) {
	if (hideThisId != null) {
		var c = document.getElementById(hideThisId);
		if (c != null)
			c.style.display='none';
	}
	document.getElementById(showThisId).style.display='block'; 
}
 
//hides section with the first id, shows the second	
function hideCollapsableSection(anchor) {
	reverseCollapsedSection('sec_'+anchor, 'colla_'+anchor);
	posBarUpdate(false);
	return false;
}

//hides section with the first id, shows the second	
function showCollapsableSection(anchor) {
	reverseCollapsedSection('colla_'+anchor, 'sec_'+anchor);
	posBarUpdate(false);
	return false;
}

// shows all sub-sections given in the list of subsection/collapsed section ids
function showAll(subSecList) {
	for (var idx = 0; subSecList[idx] != null; idx++) { 
		var s = subSecList[idx]; 
		reverseCollapsedSection(s[0], s[1]);
	}
	posBarUpdate(false);
	return false;
}

var currentlyHighlighting = false;
// highlights the section with the given anchor
function highlightSection(anchor) {
	if (currentlyHighlighting)
		return;
	
	var anim;
	var endColor = 'f78000';
	var sec = document.getElementById('sec_'+anchor);
	
	var cnt = document.getElementById('seccnt_'+anchor);
	if (cnt != null) {
		var startColor; 
		
		
		if (sec.className == 'subSecRow1')
			startColor = '171772';
		else
			startColor = '696ade';

		var head = document.getElementById('sechd_'+anchor);
		anim = [
		            { durationMs: 500, steps: 10, properties: [ {type: 'csscolor', obj: cnt, name: 'border-color', s0: endColor, s1: startColor},
		                                                        {type: 'csscolor', obj: head, name: 'background-color', s0: endColor, s1: startColor}],
		              endTo1Cb: function() {
		            	currentlyHighlighting = false;
		              }
		            }
		            ];
	}
	else {
		anim = [
	             { durationMs: 500, steps: 10, properties: [ {type: 'csscolor', obj: sec, name: 'background-color', s0: endColor, s1: 'ffffff'}],
	              endTo1Cb: function() {
	            	sec.style.setProperty('background-color', null, null);
	            	currentlyHighlighting = false;
	              }
	            }
	         ];
	}
	
	currentlyHighlighting = true;
	startAnimationSequence(anim);
}

// goes to section with given anchor
function goTo(anchorLink, effect) {
	var anchor = anchorLink.substring(1);
	reverseCollapsedSection('colla_'+anchor, 'sec_'+anchor);
	if (effect)
		smoothScrollTo('sec_'+anchor, function() {
			highlightSection(anchor);
		});
	else {
		document.getElementById('sec_'+anchor).scrollIntoView(true);
		posBarUpdate(false);
	}
	return false;
}

//////////////////////////////////////////////////////////////////
// navigation/toc functions

var isNavOpen = false;
var posbarRect;


var navbarTransition;

// draws the left navbar SVG
function drawNavbar() {
	var svg, openText, closeText, arrow1, arrow2;
	svg = newElem(SVGNS, 'svg', {width: '18px', height: '526px', style:'position:absolute; top:50%; height:526px; margin-top:-263px;'}, 
		[newElem(SVGNS, 'g', {fill:'white'}, [
		 	newElem(SVGNS, 'g', {transform: 'translate(10, 9)'}, 
		 	[ 
		 	 	arrow1 = newElem(SVGNS, 'polygon', {points: '-7,-8 -7,8 7,0'})
			]),
		 	newElem(SVGNS, 'g', {transform: 'translate(10, 516)'}, 
			[ 
				arrow2 = newElem(SVGNS, 'polygon', {points: '-7,-8 -7,8 7,0'})
			]),
	        newElem(SVGNS, 'g', {transform: 'translate(0, 526) rotate(-90)'}, 
			[
				closeText = newElem(SVGNS, 'text', {x: 238, y: 14, textLength: 50, 'font-family':'Verdana, sans-serif', 'font-weight': 'bold', 'font-size': 14, opacity: 0}, [newText('Close')]), 
				openText = newElem(SVGNS, 'text', {x: 188, y: 14, textLength: 150, 'font-family':'Verdana, sans-serif', 'font-weight': 'bold', 'font-size': 14}, [newText('Table of Content')]) 
		 	])
	    ])]);
	
	var navbar = document.getElementById('navbar');
	navbar.appendChild(svg);

	navbarTransition = {
				durationMs: 200,
				steps: 6,
				currentState: 0, 
				requestedState: 0,
				startFrom0Cb: function() {
					document.getElementById('navcontainer').className = 'visibleNav';
					isNavOpen = true;
					posBarUpdate();
				},
				endTo0Cb: function() {
					document.getElementById('navcontainer').className = '';
					document.getElementById('visibleContent').className = '';
					isNavOpen = false;
				},
				endTo1Cb: function() {
					document.getElementById('visibleContent').className = 'openNav';
				},
				properties: [
						{type: 'xml', obj: arrow1, name: 'transform', s0: 0, s1: -180, prefix: 'rotate(', postfix: ')', precision: 2 },
						{type: 'xml', obj: arrow2, name: 'transform', s0: 0, s1: -180, prefix: 'rotate(', postfix: ')', precision: 2 },
						{type: 'xml', obj: openText, name: 'opacity', s0: 1, s1: 0},
						{type: 'xml', obj: closeText, name: 'opacity', s0: 0, s1: 1},
						{type: 'css', obj: document.getElementById('visibleContent'), name: 'margin-left', s0: 40, s1: 380, postfix: 'px', precision: 0},
						{type: 'css', obj: document.getElementById('navcontainer'), name: 'left', s0: -340, s1: 20, postfix: 'px', precision: 0}
				   ]
				};
}

// toggle navigation
function navToggle() {
	navbarTransition.requestedState = (navbarTransition.requestedState == 1 ? 0 : 1);
	startTransition(navbarTransition);
	return false;
}

// close navigation
function navClose() {
	navbarTransition.requestedState = 0;
	startTransition(navbarTransition);
	return false;
}

//open navigation
function navOpen() {
	navbarTransition.requestedState = 0;
	startTransition(navbarTransition);
	return false;
}

// internal get min/max Y of an element relative to the <body> as a tuple
function getMinMaxY(elem, offset) {
	if (elem.getBoundingClientRect != null) {
		var c = elem.getBoundingClientRect();
		return [c.top+window.scrollY, c.bottom+window.scrollY];
	}
	
	if (offset != null) {
		if (elem.offsetParent == null)
			return [elem.offsetTop+offset, elem.offsetTop+elem.offsetHeight+offset];
		else
			return getMinMaxY(elem.offsetParent, elem.offsetTop+offset);
	}
	else {
		if (elem.offsetParent == null)
			return [elem.offsetTop, elem.offsetTop+elem.offsetHeight];
		else
			return getMinMaxY(elem.offsetParent, elem.offsetTop);
	}
}


// updates the position bar
function posBarUpdate(resized) {
	if (!USE_SVG || !isNavOpen)
		return;
	
	var FIRST_LINK = 1; // starts with 1: 0 is the close link
	
	var navLinksContainer = document.getElementById('navlinks');
	var navLinks = navLinksContainer.getElementsByTagName('a');
	var linksY1 = navLinks[FIRST_LINK].offsetTop; 
	var linksY2 = navLinks[navLinks.length-1].offsetTop + navLinks[navLinks.length-1].offsetHeight + 1; // +1 to include border
	var scrY1 = window.scrollY;
	var scrY2 = scrY1 + window.innerHeight;

	var y1 = linksY2 +2;
	var y2 = 0; 
	var firstOnScreenLinkY = null;
	var lastOnScreenLinkY = null;
	
	for (var i = FIRST_LINK; i < navLinks.length; i++) {
		var nl = navLinks[i];
		var anchor = nl.id.substr(4); // naming scheme of link ids is 'nav_<anchor>'
		var elem = document.getElementById('sec_'+anchor);
		if (elem == null) // section not on screen (multipage): skip
			continue;
		if (elem.offsetParent == null) // section collapsed: use summary
			elem = document.getElementById('colla_'+anchor);
		
		var p = getMinMaxY(elem);
		if (p[1] < scrY1) // skip if over screen
			continue;
		if (p[0] >= scrY2) // abort if below screen
			break;
		
		if (firstOnScreenLinkY == null) {
			if (i == FIRST_LINK)
				firstOnScreenLinkY = 0;
			else
				firstOnScreenLinkY = nl.offsetTop;
		}
		if (i == navLinks.length-1)
			lastOnScreenLinkY = navLinksContainer.scrollHeight;
		else
			lastOnScreenLinkY = nl.offsetTop + nl.offsetHeight;
		
		if (p[0] <= scrY1 && p[1] >= scrY2) { // case 1: element larger than screen
			y1 = nl.offsetTop-1;
			y2 = y1 + nl.offsetHeight+1;
			break;
		}
		else if (p[0] >= scrY1 && p[1] <= scrY2) { // case 2: element fully on screen
			y1 = Math.min(nl.offsetTop-1, y1);
			y2 = Math.max(nl.offsetTop+nl.offsetHeight+1, y2);
		}
		else if (p[0] < scrY1) { // case 3: element partially over the top of the screen
			var visFactor = (scrY1 - p[0]) / Math.max(1, p[1] - p[0]);
			y1 = Math.min(nl.offsetTop + visFactor*nl.offsetHeight, y1);
			y2 = Math.max(nl.offsetTop+nl.offsetHeight, y2);
		}
		else if (p[1] > scrY2) { // case 4: element partially below screen
			var visFactor = 1 - (p[1] - scrY2) / Math.max(1, p[1] - p[0]);
			y1 = Math.min(nl.offsetTop, y1);
			y2 = Math.max(nl.offsetTop + visFactor*nl.offsetHeight, y2);
			break;
		}
	}

	// paint/update the position bar
	var h1 = Math.max(y2-y1+1, 0);
	if (resized || posbarRect == null) {
		var startScreenY = window.scrollY;
		var endScreenY = startScreenY + window.innerHeight;
		
		var svg = newElem(SVGNS, 'svg', {width: '12px', height: linksY2+'px'});
		
		posbarRect = newElem(SVGNS, 'rect', {x:'0', y: y1, width:'8', height: h1, style:"fill:#f78000;stroke-width:0"});
		svg.appendChild(posbarRect);
		var bar = document.getElementById('navpositionbar');
		removeChildren(bar);
		bar.appendChild(svg);
	} 
	else
		setAttrs(posbarRect, {y: y1, height: h1});
	
	// scroll the navigation to show the position bar
	if (navLinks.length > 0) {
		var scrY1 = navLinksContainer.scrollTop;
		var scrY2 = scrY1 + navLinksContainer.clientHeight;
		if (scrY2-scrY1 > h1) {
			if (scrY1 > y1)
				navLinksContainer.scrollTop = firstOnScreenLinkY;
			else if (scrY2 < y2)
				navLinksContainer.scrollTop = Math.max(0, lastOnScreenLinkY - navLinksContainer.clientHeight);
		}
	}
}




//////////////////////////////////////////////////////////////////

window.onload = function() {
	drawNavbar();
	
	if (window.location.hash == null || window.location.hash.length < 2)
		return; 
	goTo(window.location.hash);
};

window.onresize = function() {
	refreshToolTips();
	posBarUpdate(true);
};

window.onscroll = function() {
	posBarUpdate(false);
};

document.onkeydown = tooltipKeyPressHandler;

