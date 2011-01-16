CC=/Developer/Platforms/iPhoneOS.platform/Developer/usr/bin/arm-apple-darwin10-gcc-4.2.1
CPP=/Developer/Platforms/iPhoneOS.platform/Developer/usr/bin/arm-apple-darwin10-g++-4.2.1
LD=$(CC)

SDKVER=4.2
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
  -DDEBUG -Diphoneos_version_min=2.0 -g

Target=WeatherIcon.dylib

all:	package

HTCPlugin: WeatherIconPlugin.o CalendarScrollView.o BaseWeatherPlugin.o HTCPlugin.o
	$(LD) $(LDFLAGS) -bundle -o $@ $(filter %.o,$^)
	ldid -S HTCPlugin

WeatherIconSettings: WeatherIconSettings.o
		$(LD) $(LDFLAGS) -bundle -o $@ $(filter %.o,$^)
		ldid -S WeatherIconSettings

WeatherIconPlugin: WeatherIconPlugin.o
		$(LD) $(LDFLAGS) -bundle -o $@ $(filter %.o,$^)
		ldid -S WeatherIconPlugin

WeatherIconStatusBar.dylib: WeatherIconStatusBar.o
		$(LD) $(LDFLAGS) -dynamiclib -init _WeatherIconStatusBarInit -o $@ $^
		ldid -S WeatherIconStatusBar.dylib

ClockPlugin: CalendarScrollView.o ClockPlugin.o
		$(LD) $(LDFLAGS) -bundle -o $@ $(filter %.o,$^)
		ldid -S ClockPlugin

LockWeatherPlugin: WeatherIconPlugin.o CalendarScrollView.o BaseWeatherPlugin.o LockWeatherPlugin.o
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
	cp com.ashman.lockinfo.WeatherIconPlugin.bundle/Theme.plist package/lock/Library/LockInfo/Plugins/com.ashman.lockinfo.LockWeatherPlugin.bundle/.
	cp -r com.ashman.lockinfo.WeatherIconPlugin.bundle/*.lproj package/lock/Library/LockInfo/Plugins/com.ashman.lockinfo.LockWeatherPlugin.bundle/.
	cp DEB/Library/WeatherIcon/*.png package/lock/Library/LockInfo/Plugins/com.ashman.lockinfo.LockWeatherPlugin.bundle/.
	cp LockWeatherPlugin package/lock/Library/LockInfo/Plugins/com.ashman.lockinfo.LockWeatherPlugin.bundle
	cp lockweather-control package/lock/DEBIAN/control
	find package/lock -name .svn -print0 | xargs -0 rm -rf
	dpkg-deb -b package/lock LockWeatherPlugin_$(shell grep ^Version: lockweather-control | cut -d ' ' -f 2).deb

clock: ClockPlugin
	mkdir -p package/clock/DEBIAN
	mkdir -p package/clock/Library/LockInfo/Plugins
	cp -r com.ashman.lockinfo.ClockPlugin.bundle package/clock/Library/LockInfo/Plugins
	cp ClockPlugin package/clock/Library/LockInfo/Plugins/com.ashman.lockinfo.ClockPlugin.bundle
	cp clock-control package/clock/DEBIAN/control
	find package/clock -name .svn -print0 | xargs -0 rm -rf
	find package/clock -name .DS_Store -print0 | xargs -0 rm -rf
	find package/clock -name Thumbs.db -print0 | xargs -0 rm -rf
	dpkg-deb -b package/clock ClockPlugin_$(shell grep ^Version: clock-control | cut -d ' ' -f 2).deb

HTC: HTCPlugin
	mkdir -p package/htc/DEBIAN
	mkdir -p package/htc/Library/LockInfo/Plugins
	cp -r com.burgch.lockinfo.HTCPlugin.bundle package/htc/Library/LockInfo/Plugins
	cp HTCPlugin package/htc/Library/LockInfo/Plugins/com.burgch.lockinfo.HTCPlugin.bundle
	cp HTC-control package/htc/DEBIAN/control
	find package/htc -name .svn -print0 | xargs -0 rm -rf
	find package/htc -name .DS_Store -print0 | xargs -0 rm -rf
	find package/htc -name Thumbs.db -print0 | xargs -0 rm -rf
	find package/htc -name pspbrwse.jbf -print0 | xargs -0 rm -rf
	find package/htc -name *.pspimage -print0 | xargs -0 rm -rf
	dpkg-deb -b package/htc HTCPlugin_$(shell grep ^Version: HTC-control | cut -d ' ' -f 2).deb

lockinfo: WeatherIconPlugin
	mkdir -p package/lockinfo/DEBIAN
	mkdir -p package/lockinfo/Library/LockInfo/Plugins
	cp -r com.ashman.lockinfo.WeatherIconPlugin.bundle package/lockinfo/Library/LockInfo/Plugins
	cp DEB/Library/WeatherIcon/*.png package/lockinfo/Library/LockInfo/Plugins/com.ashman.lockinfo.WeatherIconPlugin.bundle/.
	cp WeatherIconPlugin package/lockinfo/Library/LockInfo/Plugins/com.ashman.lockinfo.WeatherIconPlugin.bundle
	cp lockinfo-control package/lockinfo/DEBIAN/control
	find package/lockinfo -name .svn -print0 | xargs -0 rm -rf
	dpkg-deb -b package/lockinfo WeatherPlugin_$(shell grep ^Version: lockinfo-control | cut -d ' ' -f 2).deb

plugins:	lockinfo lockweather clock HTC

statusbar: WeatherIconStatusBar.dylib
	mkdir -p package/statusbar/DEBIAN
	mkdir -p package/statusbar/Library/MobileSubstrate/DynamicLibraries
	cp WeatherIconStatusBar.dylib package/statusbar/Library/MobileSubstrate/DynamicLibraries
	cp WeatherIconStatusBar.plist package/statusbar/Library/MobileSubstrate/DynamicLibraries
	cp statusbar-control package/statusbar/DEBIAN/control
	find package/statusbar -name .svn -print0 | xargs -0 rm -rf
	dpkg-deb -b package/statusbar WeatherIconStatusBar_$(shell grep ^Version: statusbar-control | cut -d ' ' -f 2).deb

package:	$(Target) WeatherIconStatusBar.dylib WeatherIconSettings lockinfo lockweather HTC clock
	mkdir -p package/weathericon/DEBIAN
	mkdir -p package/weathericon/Library/MobileSubstrate/DynamicLibraries
	mkdir -p package/weathericon/Library/PreferenceLoader/Preferences
	mkdir -p package/weathericon/System/Library/PreferenceBundles
	mkdir -p package/weathericon/System/Library/CoreServices/SpringBoard.app
	cp $(Target) package/weathericon/Library/MobileSubstrate/DynamicLibraries
	cp WeatherIcon.plist package/weathericon/Library/MobileSubstrate/DynamicLibraries
	cp WeatherIconStatusBar.dylib package/weathericon/Library/MobileSubstrate/DynamicLibraries
	cp WeatherIconStatusBar.plist package/weathericon/Library/MobileSubstrate/DynamicLibraries
	cp Preferences/* package/weathericon/Library/PreferenceLoader/Preferences
	cp -r WeatherIconSettings.bundle package/weathericon/System/Library/PreferenceBundles
	cp WeatherIconSettings package/weathericon/System/Library/PreferenceBundles/WeatherIconSettings.bundle
	cp *.png package/weathericon/System/Library/CoreServices/SpringBoard.app
	cp -r DEB/* package/weathericon
	cp control package/weathericon/DEBIAN
	find package/weathericon -name .svn -print0 | xargs -0 rm -rf
	find package/weathericon -name .DS_Store -print0 | xargs -0 rm
	dpkg-deb -b package/weathericon WeatherIcon_$(shell grep ^Version: control | cut -d ' ' -f 2).deb
