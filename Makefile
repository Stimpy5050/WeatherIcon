CC=/Developer/Platforms/iPhoneOS.platform/Developer/usr/bin/arm-apple-darwin9-gcc-4.0.1
CPP=/Developer/Platforms/iPhoneOS.platform/Developer/usr/bin/arm-apple-darwin9-g++-4.0.1
LD=$(CC)

SDKVER=2.0
SDK=/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS$(SDKVER).sdk
LDFLAGS=	-framework Foundation \
		-framework UIKit \
		-framework CoreFoundation \
		-framework CoreGraphics \
		-framework GraphicsServices \
		-framework Preferences \
		-L"$(SDK)/usr/lib" \
		-F"$(SDK)/System/Library/Frameworks" \
		-F"$(SDK)/System/Library/PrivateFrameworks" \
		-lsubstrate \
		-lobjc 

CFLAGS= -I/Users/david/iPhone/package/var/include \
  -I/var/include \
  -I/var/include/gcc/darwin/4.0 \
  -I"$(SDK)/usr/include" \
  -I"/Developer/Platforms/iPhoneOS.platform/Developer/usr/include" \
  -I"/Developer/Platforms/iPhoneOS.platform/Developer/usr/lib/gcc/arm-apple-darwin9/4.2.1/include" \
  -DDEBUG -Diphoneos_version_min=2.0

Target=WeatherIcon.dylib

all:	$(Target) WeatherIconSettings

deploy: 	$(Target) WeatherIconSettings WeatherIconPlugin
		chmod 755 $(Target)
		chmod 755 WeatherIconSettings
		rm -f /Library/MobileSubstrate/DynamicLibraries/$(Target)
		cp $(Target) /Library/MobileSubstrate/DynamicLibraries/
		cp *.plist /Library/MobileSubstrate/DynamicLibraries/
		cp Preferences/* /Library/PreferenceLoader/Preferences
		cp -r WeatherIconSettings.bundle /System/Library/PreferenceBundles
		cp WeatherIconSettings /System/Library/PreferenceBundles/WeatherIconSettings.bundle
		cp -r WeatherIconPlugin.bundle /Library/LockInfo/Plugins
		rm -f /Library/LockInfo/Plugins/WeatherIconPlugin.bundle/WeatherIconPlugin
		cp WeatherIconPlugin /Library/LockInfo/Plugins/WeatherIconPlugin.bundle

install:	deploy
		restart

WeatherIconSettings: WeatherIconSettings.mm 
		$(CPP) $(CFLAGS) $(LDFLAGS) -bundle -o $@ $(filter %.mm,$^)
		ldid -S WeatherIconSettings

WeatherIconPlugin: WeatherIconPlugin.mm 
		$(CPP) $(CFLAGS) $(LDFLAGS) -bundle -o $@ $(filter %.mm,$^)
		ldid -S WeatherIconPlugin

$(Target):	WeatherIconController.o WeatherIcon.o
		$(CC) $(CFLAGS) $(LDFLAGS) -dynamiclib -init _TweakInit -o $@ $^
		ldid -S $(Target)

%.o:	%.mm
		$(CPP) -c $(CFLAGS) $< -o $@

clean:
		rm -f *.o $(Target) WeatherIconSettings
		rm -rf package

package:	$(Target) WeatherIconSettings
	mkdir -p package/weathericon/DEBIAN
	mkdir -p package/weathericon/Library/MobileSubstrate/DynamicLibraries
	mkdir -p package/weathericon/Library/PreferenceLoader/Preferences
	mkdir -p package/weathericon/System/Library/PreferenceBundles
	mkdir -p package/weathericon/System/Library/CoreServices/SpringBoard.app
	cp $(Target) package/weathericon/Library/MobileSubstrate/DynamicLibraries
	cp *.plist package/weathericon/Library/MobileSubstrate/DynamicLibraries
	cp Preferences/* package/weathericon/Library/PreferenceLoader/Preferences
	cp -r WeatherIconSettings.bundle package/weathericon/System/Library/PreferenceBundles
	cp WeatherIconSettings package/weathericon/System/Library/PreferenceBundles/WeatherIconSettings.bundle
	cp *.png package/weathericon/System/Library/CoreServices/SpringBoard.app
	cp control package/weathericon/DEBIAN
	find package/weathericon -name .svn -print0 | xargs -0 rm -rf
	dpkg-deb -b package/weathericon weathericon_$(shell grep ^Version: control | cut -d ' ' -f 2)_iphoneos-arm.deb
