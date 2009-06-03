/*

  WeatherIcon plugin
  
    Show current weather and 6 days forecast
    
*/
//console.log('loading weather...');

var WeatherIcon = new Plugin('weathericon');

WeatherIcon.bundleIdentifier = 'com.ashman.lockinfo.WeatherIconPlugin';
WeatherIcon.expandable = 'Forecast';
WeatherIcon.daysCode = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
WeatherIcon.reservedHeight = 141;
WeatherIcon.nbTry = 0;
WeatherIcon.neverUpdated = true;

WeatherIcon.callback = function(data) {
  
	if (data.weather) {
	  WeatherIcon.Design.clean();
	  
	  var header = WeatherIcon.Design.generateHeader(''); 
	  
	  var icon = document.createElement('img');
	  icon.className = 'weatherIcon';

	  if (Settings.weathericon.useIcon)
	    	  icon.src=data.weather.icon;
	  else
		icon.src = "plugins/weathericon/Icon Sets/"+Settings.weathericon.iconSet+"/"+Icons.MiniIcons[data.weather.code]+Settings.weathericon.iconExt;
    
    	  header.appendChild(icon);
	  
	  var city = WeatherIcon.Design.generateCustom(data.weather.city.toLowerCase(), 'city', null, 'span');
	  city.style.textTransform='capitalize';
	  header.appendChild(city);
	  
	  header.appendChild(WeatherIcon.Design.generateCustom(data.weather.temp+"º", 'temp', null, 'span'));
				
	  var desc = WeatherIcon.Design.generateCustom($L(data.weather.description.toUpperCase()).toLowerCase(), 'desc', null, 'span');
	  desc.style.textTransform='capitalize';
	  header.appendChild(desc);

		WeatherIcon.Design.appendCustom(header);
		
		

		
		var Forecast = WeatherIcon.Design.appendCustom('','Forecast','Forecast');
		
		  
  		for (i = 0;i < data.weather.forecast.length && data.weather.forecast[i]; i++)
//  		for (i = 0;i < 0 && data.weather.forecast[i]; i++)
  		{
  			var forecast = data.weather.forecast[i];
  			
  		  var days = document.createElement('div');
  		  days.className = 'dayD';
  		  
        
        var iconD = document.createElement('div');
        iconD.className = 'icon';
        
        var icon = document.createElement('img');
        icon.className = 'weatherIcon';
	  if (Settings.weathericon.useIcon)
	    	  icon.src=forecast.icon;
	  else
		icon.src = "plugins/weathericon/Icon Sets/"+Settings.weathericon.iconSet+"/"+Icons.MiniIcons[forecast.code]+Settings.weathericon.iconExt;
        
        iconD.appendChild(icon);
        
        days.appendChild(iconD);
        
        var day = document.createElement('div');
        day.className = 'day';
        day.innerText = $L(WeatherIcon.daysCode[forecast.daycode].ucfirst());
        days.appendChild(day);
        
        var desc = document.createElement('div');
        desc.className = 'desc';
        desc.innerText = $L(forecast.description.toUpperCase()).toLowerCase();
        desc.style.textTransform = 'capitalize';
        days.appendChild(desc);
        
        var tempD = document.createElement('div');
        tempD.className = 'temp';
        
        var hi = document.createElement('div');
        hi.className='hi';
        hi.innerText = forecast.high+"º";
        
        tempD.appendChild(hi);
        
        var low = document.createElement('div');
        low.className='low';
        low.innerText = forecast.low+"º";
        
        tempD.appendChild(low);
        
        days.appendChild(tempD)
        
        Forecast.appendChild(days);
  		}
  	}
  	
/*
  	if(Settings.allowExpand && Settings.weathericon.allowExpand)
	      WeatherIcon.Design.appendCustom('. . .','expand');
		
		Forecast.style.display = (Settings.weathericon.defState == 'shrinked' && WeatherIcon.neverUpdated || WeatherIcon.neverUpdated !== true && !WeatherIcon.expanded)?'none':'block';
		WeatherIcon.expanded=!(Settings.weathericon.defState == 'shrinked' && WeatherIcon.neverUpdated || WeatherIcon.neverUpdated !== true && !WeatherIcon.expanded);
		WeatherIcon.reservedHeight = ((Settings.weathericon.defState == 'shrinked' && WeatherIcon.neverUpdated || WeatherIcon.neverUpdated !== true && !WeatherIcon.expanded)?Forecast.getDimensions().height:0);
	}
*/
};

var Icons = {
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
  ]
}


Controller.registerPlugin(WeatherIcon);
