
var Source = {
  MiniIcons:
  [
    "tstorm3",       // 0  tornado
    "tstorm3",       // 1  tropical storm
    "tstorm3",       // 2  hurricane
    "tstorm3",       // 3  severe thunderstorms
    "tstorm2",       // 4  thunderstorms
    "sleet",         // 5  mixed rain and snow
    "sleet",         // 6  mixed rain and sleet
    "sleet",         // 7  mixed snow and sleet
    "sleet",         // 8  freezing drizzle
    "light_rain",    // 9  drizzle
    "sleet",         // 10 freezing rain
    "shower2",       // 11 showers
    "shower2",       // 12 showers
    "snow1",         // 13 snow flurries
    "snow2",         // 14 light snow showers
    "snow4",         // 15 blowing snow
    "snow4",         // 16 snow
    "hail",          // 17 hail
    "sleet",         // 18 sleet
    "mist",          // 19 dust
    "fog",           // 20 foggy
    "mist",           // 21 haze
    "fog",           // 22 smoky
    "cloudy1",       // 23 blustery
    "cloudy1",       // 24 windy
    "overcast",      // 25 cold
    "cloudy1",       // 26 cloudy
    "cloudy4_night", // 27 mostly cloudy (night)
    "cloudy4",       // 28 mostly cloudy (day)
    "cloudy2_night", // 29 partly cloudy (night)
    "cloudy2",       // 30 partly cloudy (day)
    "sunny_night",   // 31 clear (night)
    "sunny",         // 32 sunny
    "mist_night",    // 33 fair (night)
    "mist",          // 34 fair (day)
    "hail",          // 35 mixed rain and hail
    "sunny",         // 36 hot
    "tstorm1",       // 37 isolated thunderstorms
    "tstorm2",       // 38 scattered thunderstorms
    "tstorm2",       // 39 scattered thunderstorms
    "tstorm2",       // 40 scattered showers
    "snow5",         // 41 heavy snow
    "snow3",         // 42 scattered snow showers
    "snow5",         // 43 heavy snow
    "cloudy1",       // 44 partly cloudy
    "storm1",        // 45 thundershowers
    "snow2",         // 46 snow showers
    "tstorm1",       // 47 isolated thundershowers
    "dunno",         // 48 / 3200 not available
  ],
		
  dayCodes: {SUN: 0, MON: 1, TUE: 2, WED: 3, THU: 4,FRI: 5, SAT: 6},
  
  validateWeatherLocation: function(locale, callback)
  {
    url = "http://weather.yahooapis.com/forecastrss?u=f&p=";
    
    var xmlReq = new XMLHttpRequest();
    xmlReq.onreadystatechange = function(e)
    {
      Source.handleValidatedWeatherLocale(e, xmlReq, locale, callback);
    }
    xmlReq.overrideMimeType("text/xml");
    xmlReq.open("GET", url + escape(locale).replace(/^%u/g, "%"));
    xmlReq.setRequestHeader("Cache-Control", "no-cache");
    xmlReq.send(null);
  },
  
  handleValidatedWeatherLocale: function (event, xmlReq, locale, callback)
  {
    if(xmlReq.readyState != 4) 
    {
      return;
    }
    if(xmlReq.status != 200 && xmlReq.status != 0) 
    {
      return;
    }
    if(!xmlReq.responseXML)
    {
      return;
    }
    
    var obj = {error:false, errorString:null, cities:new Array, refine:false};
    
    var effectiveRoot = Source.findChild(Source.findChild(xmlReq.responseXML, "rss"), "channel");
    
    var title = Source.findChild(effectiveRoot, "title");
    if(title.firstChild.data != "Yahoo! Weather - Error")
    {
      var location = Source.findChild(effectiveRoot, "yweather:location");
      
      var city = location.getAttribute("city");
			var state = location.getAttribute("country");
			var zip = locale;
			
      if (city && state && zip)
			{
				obj.cities[obj.cities.length] = {name:city, state:state, zip:zip};
			}
    }
    else {
      var item = Source.findChild(effectiveRoot, "item");
      var title = Source.findChild(item, "title");
      
      obj.error = true;
      obj.errorString = title.firstChild.data;
    }
    
    callback(obj);
  },
  
  fetchWeatherData: function (callback, locale)
  {
    url = "http://weather.yahooapis.com/forecastrss?u=f&p=";
    
    var xmlReq = new XMLHttpRequest();
    xmlReq.onreadystatechange = function(e)
    {
      Source.handleFetchedWeatherData(e, xmlReq, callback);
    }
    xmlReq.overrideMimeType("text/xml");
    xmlReq.open("GET", url + escape(locale).replace(/^%u/g, "%"));
    xmlReq.setRequestHeader("Cache-Control", "no-cache");
    xmlReq.send(null); 
    
    return xmlReq;
  },
  
  handleFetchedWeatherData: function (event, xmlReq, callback)
  {
    if(xmlReq.readyState != 4) 
    {
      return;
    }
    if(xmlReq.status != 200 && xmlReq.status != 0) 
    {
      return;
    }
    if(!xmlReq.responseXML)
    {
      return;
    }
    
    var obj = {error:false, errorString:null};
    
    var Channel = Source.findChild(Source.findChild(xmlReq.responseXML, "rss"), "channel");
    
    var title = Source.findChild(Channel, "title");
    if(title.firstChild.data == "Yahoo! Weather - Error") {
      var item = Source.findChild(Channel, "item");
      var title = Source.findChild(item, "title");
      
      obj.error = true;
      obj.errorString = title.firstChild.data;
    }
    
    var Condition = Source.findChild(Source.findChild(Channel, "item"), "yweather:condition");
    
    attribute = Source.findChild(Channel, "yweather:location").getAttribute("city");
    obj.city = attribute.toString();
    
    attribute = Condition.getAttribute("temp");
    obj.temp = parseInt(attribute);
    
    attribute = Source.findChild(Channel, "yweather:wind").getAttribute("chill");
    obj.realFeel = parseInt(attribute);
    
    attribute = Condition.getAttribute("text");
    obj.description = attribute.toString();
    
    attribute = Condition.getAttribute("code");
    obj.icon = parseInt(attribute);
    if(obj.icon == 3200)
    {
      obj.icon = 48;
    }
    
    obj.forecast = new Array;
		var Forecast = Source.findChild (Source.findChild(Channel, "item"), "yweather:forecast", true);
		
		// assume the days are in order, 1st entry is today
		var j=0;
		var firstTime = true;
		
		for (var i=0; i<Forecast.length; i++) {
		  var child = Forecast[i];
		  
			if (firstTime) // today
			{
				obj.hi = parseInt (child.getAttribute('high'));
				
				obj.lo = parseInt (child.getAttribute('low'));
				
				firstTime = false;
			}

			var foreobj = {daycode:null, hi:0, lo:0, icon:-1};

			foreobj.daycode = Source.dayCodes[child.getAttribute('day').toUpperCase()];
			foreobj.hi = parseInt (child.getAttribute('high'));
			foreobj.lo = parseInt (child.getAttribute('low'));
			foreobj.description = child.getAttribute('text');
			
      foreobj.icon = parseInt(child.getAttribute("code"));
      if(foreobj.icon == 3200)
      {
        foreobj.icon = 48;
      }
      
      foreobj.ouricon = Source.MiniIcons[foreobj.icon-1];
			
			//alert(j);
				
			obj.forecast[j++]=foreobj;
			if (j == 7) break; // only look ahead 7 days
		}
    
    callback(obj); 
  },
  
  findChild: function (element, nodeName, all)
  {
  	var child;
  	var children = [];
  	var i=0;
  	
  	for (child = element.firstChild; child != null; child = child.nextSibling)
  	{
  	  if((child.nodeName == nodeName) && (all))
  	    children[i++]=child;
  		else if (child.nodeName == nodeName)
  			return child;
  	}
  	
  	return ((all)?children:null);
  },
};
