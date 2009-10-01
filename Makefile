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

$(Target):	Tweak.o
		$(LD) $(LDFLAGS) -dynamiclib -init _TweakInit -o $@ $^
		ldid -S $(Target)

%.o:	%.mm
		$(CPP) -c $(CFLAGS) $< -o $@

clean:
		rm -f *.o $(Target) WeatherIconSettings WeatherIconPlugin
		rm -rf package

package:	$(Target) WeatherIconSettings WeatherIconPlugin
	mkdir -p package/weathericon/DEBIAN
	mkdir -p package/weathericon/Library/MobileSubstrate/DynamicLibraries
	mkdir -p package/weathericon/Library/PreferenceLoader/Preferences
	mkdir -p package/weathericon/System/Library/PreferenceBundles
	mkdir -p package/weathericon/System/Library/CoreServices/SpringBoard.app
	mkdir -p package/weathericon/Library/LockInfo/Plugins
	cp $(Target) package/weathericon/Library/MobileSubstrate/DynamicLibraries
	cp *.plist package/weathericon/Library/MobileSubstrate/DynamicLibraries
	cp Preferences/* package/weathericon/Library/PreferenceLoader/Preferences
	cp -r WeatherIconSettings.bundle package/weathericon/System/Library/PreferenceBundles
	cp WeatherIconSettings package/weathericon/System/Library/PreferenceBundles/WeatherIconSettings.bundle
	cp -r WeatherIconPlugin.bundle package/weathericon/Library/LockInfo/Plugins
	cp WeatherIconPlugin package/weathericon/Library/LockInfo/Plugins/WeatherIconPlugin.bundle
	cp *.png package/weathericon/System/Library/CoreServices/SpringBoard.app
	cp control package/weathericon/DEBIAN
	find package/weathericon -name .svn -print0 | xargs -0 rm -rf
	dpkg-deb -b package/weathericon weathericon_$(shell grep ^Version: control | cut -d ' ' -f 2)_iphoneos-arm.deb

lockinfo: WeatherIconPlugin
	mkdir -p package/lockinfo/DEBIAN
	mkdir -p package/lockinfo/Library/
	cp -r Themes package/lockinfo/Library/
	cp lockinfo-control package/lockinfo/DEBIAN/control
	find package/lockinfo -name .svn -print0 | xargs -0 rm -rf
	dpkg-deb -b package/lockinfo wili_$(shell grep ^Version: lockinfo-control | cut -d ' ' -f 2).deb
