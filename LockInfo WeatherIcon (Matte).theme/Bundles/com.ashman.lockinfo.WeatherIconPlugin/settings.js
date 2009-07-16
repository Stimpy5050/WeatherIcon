if(!Settings.weathericon)
  Settings.weathericon = {};

Settings.weathericon = Object.extend({
  
  //Allow weather expansion (allow click on it)
  //Allow: allowExpand: true
  //Disallow: allowExpand: false
  allowExpand: true,
  
  //Set the default state of weather. A small bar (shrinked) or the forecast displayed (stretched)
  //Small bar: defState: 'shrinked'
  //Forecast visible: defState: 'stretched'
  //If allowExpand is set to false, you won't be able to change this state clicking on the weather bar
  defState: 'stretched',
  
  //Use inline forecast instead of colums
  inlineForecast: false,
  
  //You can set a limit number of day forecast to show in inline mode
  inlineLimit: 3,
  
  //Switch to inline forecast instead of columns when less than 4 days forecast
  autoInline: false,
  
}, Settings.weathericon);
