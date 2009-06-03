// Modified from weatherParser.js from Leopard. Apologies to all offended.
// I'm hoping that no-one objects since it's Apple hardware and so forth.

/*
Copyright ＿ 2005, Apple Computer, Inc.  All rights reserved.
NOTE:  Use of this source code is subject to the terms of the Software
License Agreement for Mac OS X, which accompanies the code.  Your use
of this source code signifies your agreement to such license terms and
conditions.  Except as expressly granted in the Software License Agreement
for Mac OS X, no other copyright, patent, or other intellectual property
license or right is granted, either expressly or by implication, by Apple.
*/

var Source = {
  MiniIcons: //Fix Up for weatherParser.js but also enables standardisation of sorts
  [
  	"sunny", 						// 1 Sunny
  	"cloudy1",						// 2 Mostly Sunny
  	"cloudy2",					// 3 Partly Sunny
  	"cloudy3",					// 4 Intermittent Clouds
  	"cloudy4",					// 5 Hazy Sunshione
  	"cloudy5",					// 6 Mostly Cloudy
  	"cloudy5",					// 7 Cloudy (am/pm)
  	"overcast",					// 8 Dreary (am/pm)
  	"dunno",						// 9 retired
  	"dunno",						// 10 retired
  	"fog",						// 11 fog (am/pm)
  	"shower1",						// 12 showers (am/pm)
  	"shower3",					// 13 Mostly Cloudy with Showers
  	"shower2",					// 14 Partly Sunny with Showers
  	"tstorm3",				// 15 Thunderstorms (am/pm)
  	"tstorm2",				// 16 Mostly Cloudy with Thunder Showers
  	"tstorm1",				// 17 Partly Sunnty with Thunder Showers
  	"light_rain",						// 18 Rain (am/pm)
  	"cloudy5",					// 19 Flurries (am/pm)
  	"cloudy4",					// 20 Mostly Cloudy with Flurries
  	"cloudy2",					// 21 Partly Sunny with Flurries
  	"snow5",						// 22 Snow (am/pm)
  	"snow3",						// 23 Mostly Cloudy with Snow
  	"hail",						// 24 Ice (am/pm)
  	"sleet",						// 25 Sleet (am/pm)
  	"hail",						// 26 Freezing Rain (am/pm)
  	"dunno",						// 27 retired
  	"dunno",						// 28 retired
  	"sleet",					// 29 Rain and Snow Mixed (am/pm)
  	"sunny",						// 30 Hot (am/pm)
  	"sunny",				// 31 Cold (am/pm)
  	"mist",						// 32 Windy (am/pm)
  	// Night only Icons;
  	"sunny_night",						// 33 Clear
  	"cloudy1_night",				// 34 Mostly Clear
  	"cloudy2_night",				// 35 Partly Cloudy
  	"cloudy3_night",						// 36 Intermittent Clouds
  	"cloudy4_night",						// 37 Hazy
  	"cloudy5",						// 38 Mostly Cloudy
  	"shower2_night",						// 39 Partly Cloudy with Showers
  	"shower3_night",			 			// 40 Mostly Cloudy with Showers
  	"tstorm1_night",						// 41 Partly Cloudy with Thunder Showers
  	"tstorm2_night",						// 42 Mostly Cloudy with Thunder Showers
  	"cloudy4_night",						// 43 Mostly Cloudy with Flurries
  	"cloudy4_night"							// 44 Mostly Cloudy with Flurries
  ],
  
  getURLForSmallIcon: function (code)
  {
  	var src = '';
  	if (code)
  	{
  		src = miniIconTable[code];
  		
  		if (src === undefined)
  			src = '';
  	}
  		
  	return src;
  },
  
  findChild: function (element, nodeName)
  {
  	var child;
  	
  	for (child = element.firstChild; child != null; child = child.nextSibling)
  	{
  		if (child.nodeName == nodeName)
  			return child;
  	}
  	
  	return null;
  },
  
  
  trimWhiteSpace: function (string)
  {
  	return string.replace(/^\s*/, '').replace(/\s*$/, '');
  },
  
  // returns an anonymous object like so
  // object
  //		error: 	Boolean false for success
  //		errorString: failure string
  //		hi:		Fahrenheit
  //		lo: 		Fahrenheit
  //		temp: 	Fahrenheit
  //		realFeel: Farenheit
  //		icon	:	accuweather icon code
  //		description:	accuweather description
  //		city:	City (first caps)
  //		time:	time 24 hours(nn:nn)
  //		sunset:	time 24 hours (nn:nn)
  //		sunrise: time 24 hours (nn:nn)
  		
  fetchWeatherData: function (callback, zip)
  {
  	var url = 'http://apple.accuweather.com/adcbin/apple/Apple_Weather_Data.asp?zipcode=';
  	//var url = 'http://wu.apple.com/adcbin/apple/Apple_Weather_Data.asp?zipcode=';
  	
  	if (window.timerInterval != 300000)
  		window.timerInterval = 300000; // 5 minutes
  
  	var xml_request = new XMLHttpRequest();
  	xml_request.onload = function(e) {Source.xml_loaded(e, xml_request, callback);}
  	xml_request.overrideMimeType("text/xml");
  	xml_request.open("GET", url+zip);
  	xml_request.setRequestHeader("Cache-Control", "no-cache");
  	xml_request.setRequestHeader("wx", "385");
  	xml_request.send(null);
  	
  	return xml_request;
  },
  
  constructError: function (string)
  {
  	return {error:true, errorString:string};
  },
  
  // parses string of the form nn:nn
  parseTimeString: function (string)
  {
  	var obj = null;
  	try {
  		var array = string.match (/\d{1,2}/g);
  		
  		obj = {hour:parseInt(array[0], 10), minute:parseInt(array[1],10)};
  	}
  	catch (ex)
  	{
  		// ignore
  	}
  	
  	return obj;
  },
  
  dayCodes: {SUN: 0, MON: 1, TUE: 2, WED: 3, THU: 4,FRI: 5, SAT: 6},
  
  parseDayCode: function (dayCode)
  {
  	return Source.dayCodes[Source.trimWhiteSpace(dayCode).substr (0, 3).toUpperCase()];
  },
  
  xml_loaded: function (event, request, callback)
  {
  	if (request.responseXML)
  	{
  		var obj = {error:false, errorString:null}; 
  		var adc_Database = Source.findChild (request.responseXML, "adc_Database");
  		if (adc_Database == null) {callback(Source.constructError("no <adc_Database>")); return;}
  		
  		var CurrentConditions = Source.findChild (adc_Database, "CurrentConditions");
  		if (CurrentConditions == null) {callback(Source.constructError("no <CurrentConditions>")); return;}
  		
  		var tag = Source.findChild (CurrentConditions, "Time");
  		if (tag != null)
  			obj.time = Source.parseTimeString (tag.firstChild.data);
  		else
  			obj.time = null;
  
  		tag = Source.findChild (CurrentConditions, "City");
  		if (tag == null) {callback(Source.constructError("no <City>")); return;}
  		obj.city =  Source.trimWhiteSpace(tag.firstChild.data.toString()).toLowerCase();
  
  		tag = Source.findChild (CurrentConditions, "Temperature");
  		if (tag == null) {callback(Source.constructError("no <Temperature>")); return;}
  		obj.temp = parseInt (tag.firstChild.data);
  		
  		tag = Source.findChild (CurrentConditions, "RealFeel");
  		if (tag == null) {callback(Source.constructError("no <RealFeel>")); return;}
  		obj.realFeel = parseInt (tag.firstChild.data);
  		
  		tag = Source.findChild (CurrentConditions, "WeatherText");
  		if (tag == null)
  			obj.description = null;
  		else
  			obj.description = Source.trimWhiteSpace(tag.firstChild.data);
  					
  		tag = Source.findChild (CurrentConditions, "WeatherIcon");
  		if (tag == null) {callback(Source.constructError("no <WeatherIcon>")); return;}
  		obj.icon = parseInt (tag.firstChild.data, 10);
  		obj.icon -= 1; //Accuweather starts at 1
  		
  		obj.sunset = null;
  		obj.sunrise = null;
  		var Planets = Source.findChild (adc_Database, "Planets");
  		if (Planets != null)
  		{
  			tag = Source.findChild (Planets, "Sun");
  			if (tag != null)
  			{
  				var rise = tag.getAttribute("rise");
  				var set = tag.getAttribute("set");
  				
  				if (rise != null && set != null)
  				{
  					obj.sunset = Source.parseTimeString (set);
  					obj.sunrise = Source.parseTimeString(rise);
  				}
  			}
  		}
  
  		obj.forecast = new Array;
  		var Forecast = Source.findChild (adc_Database, "Forecast");
  		if (Forecast == null) {callback(Source.constructError("no <Forecast>")); return;}
  		
  		// assume the days are in order, 1st entry is today
  		var child;
  		var j=0;
  		var firstTime = true;
  		
  		for (child = Forecast.firstChild; child != null; child = child.nextSibling)
  		{
  			if (child.nodeName == 'day')
  			{
  				if (firstTime) // today
  				{
  					obj.hi = 0;
  					tag = Source.findChild(child, 'High_Temperature');
  					if (tag != null)
  						obj.hi = parseInt (tag.firstChild.data);
  					
  					obj.lo = 0;
  					tag = Source.findChild(child, 'Low_Temperature');
  					if (tag != null)
  						obj.lo = parseInt (tag.firstChild.data);
  					
  					firstTime = false;
  				}
  
  				var foreobj = {daycode:null, hi:0, lo:0, icon:-1};
  
  				tag = Source.findChild(child, 'DayCode');
  				if (tag != null)
  					foreobj.daycode = Source.trimWhiteSpace(tag.firstChild.data.toString()).substring(1,3);
  				
  				tag = Source.findChild(child, 'High_Temperature');
  				if (tag != null)
  					foreobj.hi = parseInt (tag.firstChild.data);
  				
  				tag = Source.findChild(child, 'Low_Temperature');
  				if (tag != null)
  					foreobj.lo = parseInt (tag.firstChild.data);					
          
  				tag = Source.findChild(child, 'WeatherIcon');
  				if (tag != null)
  				{
  					foreobj.icon = parseInt (tag.firstChild.data, 10);
  					foreobj.ouricon = Source.MiniIcons[foreobj.icon-1];
  				}
  				
  				tag = Source.findChild(child, 'TXT_Short');
  				if(tag != null)
  				  foreobj.description = Source.trimWhiteSpace(tag.firstChild.data);
  					
  				tag = Source.findChild (child, "DayCode");
  				if (tag != null)
  					foreobj.daycode = Source.parseDayCode(tag.firstChild.data);
  				else
  					foreobj.daycode = null;
  
  				//alert(j);
  					
  				obj.forecast[j++]=foreobj;
  				if (j == 7) break; // only look ahead 7 days
  			}
  		}
  
  		callback (obj); 
  		
  	}
  	else
  	{
  		callback ({error:true, errorString:"XML request failed. no responseXML"}); //Could be any number of things..
  	}
  },
  
  // returns an anonymous object like so
  // object
  //		error: 	Boolean false for success
  //		errorString: failure string
  //		cities:	array (alphabetical by name)
  //			object
  //				name: city name
  //				zip: postal code
  //				state: city state
  //		refine: boolean - true if the search is too generic
  validateWeatherLocation: function (location, callback)
  {
  	var url = 'http://apple.accuweather.com/adcbin/apple/Apple_find_city.asp?location=';
  	//var url = 'http://wu.apple.com/adcbin/apple/Apple_find_city.asp?location=';
  	
  	var xml_request = new XMLHttpRequest();
  	xml_request.onload = function(e) {Source.xml_validateloaded(e, xml_request, callback);}
  	xml_request.overrideMimeType("text/xml");
  	xml_request.open("GET", url+location);
  	xml_request.setRequestHeader("Cache-Control", "no-cache");
  	xml_request.send(null);
  },
  
  xml_validateloaded: function (event, request, callback)
  {
  	if (request.responseXML)
  	{
  		var obj = {error:false, errorString:null, cities:new Array, refine:false};
  		var adc_Database = Source.findChild (request.responseXML, "adc_Database");
  		if (adc_Database == null) {callback(Source.constructError("no <adc_Database>")); return;}
  		
  		var CityList = Source.findChild (adc_Database, "CityList");
  		if (CityList == null) {callback(Source.constructError("no <CityList>")); return;}
  		
  		if (CityList.getAttribute('extra_cities') == '1')
  			obj.refine = true;
  
  		for (child = CityList.firstChild; child != null; child = child.nextSibling)
  		{
  			if (child.nodeName == "location")
  			{
  				var city = child.getAttribute("city");
  				var state = child.getAttribute("state");
  				var zip = child.getAttribute("postal");
  				
  				if (city && state && zip)
  				{
  					obj.cities[obj.cities.length] = {name:city, state:state, zip:zip};
  				}
  			}
  		}
  		
  		callback (obj);
  	}
  	else
  	{
  		callback ({error:true, errorString:"No Response"});
  	}
  },

};
