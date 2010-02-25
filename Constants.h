#include <Foundation/Foundation.h>

static NSArray* defaultIcons = [[NSArray arrayWithObjects:
        @"tstorms", @"tstorms", @"tstorms", @"tstorms", @"tstorms",
        @"snow", @"snow", @"snow", @"showers", @"showers",
        @"showers", @"showers", @"showers", @"snow", @"snow",
        @"snow", @"snow", @"snow", @"snow", @"cloudy",
        @"cloudy", @"cloudy", @"cloudy", @"cloudy", @"cloudy",
        @"sunny", @"cloudy", @"cloudy", @"cloudy", @"partly_cloudy",
        @"partly_cloudy", @"sunny", @"sunny", @"sunny", @"sunny",
        @"showers", @"sunny", @"tstorms", @"tstorms", @"tstorms",
        @"showers", @"snow", @"snow", @"snow", @"partly_cloudy",
        @"tstorms", @"snow", @"tstorms", nil] retain];

static NSArray* defaultNightIcons = [[NSArray arrayWithObjects:
        @"tstorms", @"tstorms", @"tstorms", @"tstorms", @"tstorms",
        @"snow", @"snow", @"snow", @"showers", @"showers",
        @"showers", @"showers", @"showers", @"snow", @"snow",
        @"snow", @"snow", @"snow", @"snow", @"cloudy",
        @"cloudy", @"cloudy", @"cloudy", @"cloudy", @"cloudy",
        @"sunny", @"cloudy", @"cloudy", @"cloudy", @"partly_cloudy_night",
        @"partly_cloudy_night", @"moon", @"moon", @"moon", @"moon",
        @"showers", @"sunny", @"tstorms", @"tstorms", @"tstorms",
        @"showers", @"snow", @"snow", @"snow", @"partly_cloudy_night",
        @"tstorms", @"snow", @"tstorms", nil] retain];

static NSArray* descriptions = [[NSArray arrayWithObjects:
        @"Tornado", @"Tropical Storm", @"Hurricane", @"Severe Thunderstorms", @"Thunderstorms",
        @"Mixed Rain and Snow", @"Mixed Rain and Sleet", @"Mixed Snow and Sleet", @"Freezing Drizzle", @"Drizzle",
        @"Freezing Rain", @"Showers", @"Showers", @"Snow Flurries", @"Light Snow Showers",
        @"Blowing Snow", @"Snow", @"Hail", @"Sleet", @"Dust",
        @"Foggy", @"Haze", @"Smoky", @"Blustery", @"Windy",
        @"Cold", @"Cloudy", @"Mostly Cloudy", @"Mostly Cloudy", @"Partly Cloudy",
        @"Partly Cloudy", @"Clear", @"Sunny", @"Fair", @"Fair",
        @"Mixed Rain and Hail", @"Hot", @"Isolated Thunderstorms", @"Scattered Thunderstorms", @"Scattered Thunderstorms",
        @"Scattered Showers", @"Heavy Snow", @"Scattered Snow Showers", @"Heavy Snow", @"Partly Cloudy",
        @"Thunderstorms", @"Snow Showers", @"Isolated Thunderstorms", nil] retain];

