CC=/Developer/Platforms/iPhoneOS.platform/Developer/usr/bin/arm-apple-darwin9-gcc-4.0.1
CPP=/Developer/Platforms/iPhoneOS.platform/Developer/usr/bin/arm-apple-darwin9-g++-4.0.1
LD=$(CC)

SDKVER=3.0
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

CFLAGS= -I$(SDK)/var/include \
  -I/var/include \
  -I/var/include/gcc/darwin/4.0 \
  -I"$(SDK)/usr/include" \
  -I"/Developer/Platforms/iPhoneOS.platform/Developer/usr/include" \
  -I"/Developer/Platforms/iPhoneOS.platform/Developer/usr/lib/gcc/arm-apple-darwin9/4.0.1/include" \
  -DDEBUG -Diphoneos_version_min=2.0

Target=WeatherIcon.dylib

all:	package

WeatherIconSettings: WeatherIconSettings.o
		$(LD) $(LDFLAGS) -bundle -o $@ $(filter %.o,$^)
		ldid -S WeatherIconSettings

WeatherIconPlugin: WeatherIconPlugin.o
		$(LD) $(LDFLAGS) -bundle -o $@ $(filter %.o,$^)
		ldid -S WeatherIconPlugin

LockWeatherPlugin: WeatherIconPlugin.o LockWeatherPlugin.o
		$(LD) $(LDFLAGS) -bundle -o $@ $(filter %.o,$^)
		ldid -S LockWeatherPlugin

$(Target):	Tweak.o
		$(LD) $(LDFLAGS) -dynamiclib -init _TweakInit -o $@ $^
		ldid -S $(Target)

%.o:	%.mm
		$(CPP) -c $(CFLAGS) $< -o $@

clean:
		rm -f *.o $(Target) WeatherIconSettings WeatherIconPlugin
		rm -rf package

lockweather: LockWeatherPlugin
	mkdir -p package/lock/DEBIAN
	mkdir -p package/lock/Library/LockInfo/Plugins
	cp -r com.ashman.lockinfo.LockWeatherPlugin.bundle package/lock/Library/LockInfo/Plugins
	cp com.ashman.lockinfo.WeatherIconPlugin.bundle/*.png package/lock/Library/LockInfo/Plugins/com.ashman.lockinfo.LockWeatherPlugin.bundle/.
	cp -r com.ashman.lockinfo.WeatherIconPlugin.bundle/*.lproj package/lock/Library/LockInfo/Plugins/com.ashman.lockinfo.LockWeatherPlugin.bundle/.
	cp LockWeatherPlugin package/lock/Library/LockInfo/Plugins/com.ashman.lockinfo.LockWeatherPlugin.bundle
	cp lockweather-control package/lock/DEBIAN/control
	find package/lock -name .svn -print0 | xargs -0 rm -rf
	dpkg-deb -b package/lock LockWeatherPlugin_$(shell grep ^Version: lockweather-control | cut -d ' ' -f 2).deb

lockinfo: WeatherIconPlugin
	mkdir -p package/lockinfo/DEBIAN
	mkdir -p package/lockinfo/Library/LockInfo/Plugins
	cp -r com.ashman.lockinfo.WeatherIconPlugin.bundle package/lockinfo/Library/LockInfo/Plugins
	cp WeatherIconPlugin package/lockinfo/Library/LockInfo/Plugins/com.ashman.lockinfo.WeatherIconPlugin.bundle
	cp lockinfo-control package/lockinfo/DEBIAN/control
	find package/lockinfo -name .svn -print0 | xargs -0 rm -rf
	dpkg-deb -b package/lockinfo WeatherIconPlugin_$(shell grep ^Version: lockinfo-control | cut -d ' ' -f 2).deb

package:	$(Target) WeatherIconSettings lockinfo lockweather
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
	cp -r DEB/* package/weathericon
	cp control package/weathericon/DEBIAN
	find package/weathericon -name .svn -print0 | xargs -0 rm -rf
	dpkg-deb -b package/weathericon WeatherIcon_$(shell grep ^Version: control | cut -d ' ' -f 2).deb
