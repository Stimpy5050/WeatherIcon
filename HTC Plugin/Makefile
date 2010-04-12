CC=/Developer/Platforms/iPhoneOS.platform/Developer/usr/bin/arm-apple-darwin9-gcc-4.0.1
CPP=/Developer/Platforms/iPhoneOS.platform/Developer/usr/bin/arm-apple-darwin9-g++-4.0.1
LD=$(CC)
platform=/Developer/Platforms/iPhoneOS.platform
allocate=${platform}/Developer/usr/bin/codesign_allocate
export CODESIGN_ALLOCATE=${allocate}
export COPYFILE_DISABLE=TRUE

SDKVER=3.0
SDK=/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS$(SDKVER).sdk
LDFLAGS+= -framework Foundation
LDFLAGS+= -framework UIKit
LDFLAGS+= -framework CoreFoundation
LDFLAGS+= -framework CoreGraphics
LDFLAGS+= -framework GraphicsServices
LDFLAGS+= -framework Preferences
LDFLAGS+= -L"$(SDK)/usr/lib"
LDFLAGS+= -F"$(SDK)/System/Library/Frameworks"
LDFLAGS+= -F"$(SDK)/System/Library/PrivateFrameworks"
LDFLAGS+= -lsubstrate
LDFLAGS+= -lobjc

CFLAGS+= -I$(SDK)/var/include
CFLAGS+= -I/var/include
CFLAGS+= -I/var/include/gcc/darwin/4.0
CFLAGS+= -I"$(SDK)/usr/include"
CFLAGS+= -I"/Developer/Platforms/iPhoneOS.platform/Developer/usr/include"
CFLAGS+= -I"/Developer/Platforms/iPhoneOS.platform/Developer/usr/lib/gcc/arm-apple-darwin9/4.0.1/include"
CFLAGS+= -I"$(SDK)/System/Library/PrivateFrameworks/"
CFLAGS+= -DDEBUG
CFLAGS+= -Diphoneos_version_min=2.0
CFLAGS+= -F"$(SDK)/System/Library/Frameworks"
CFLAGS+= -F"$(SDK)/System/Library/PrivateFrameworks"

HTCPlugin: WeatherIconPlugin.o LockWeatherPlugin.o HTCPlugin.o
		$(LD) $(LDFLAGS) -bundle -o $@ $(filter %.o,$^)
		codesign -fs "CBurgess" HTCPlugin

LockWeatherPlugin: WeatherIconPlugin.o  LockWeatherPlugin.o
		$(LD) $(LDFLAGS) -bundle -o $@ $(filter %.o,$^)
		codesign -fs "CBurgess" LockWeatherPlugin
		
%.o:	%.mm
		$(CPP) -c $(CFLAGS) $< -o $@

clean:
		rm -f *.o WeatherIconPlugin HTCPlugin LockWeatherPlugin

HTC: HTCPlugin
	cp HTCPlugin ../../Plugin

HTC-DEB: HTCPlugin
	mkdir -p package/lock/DEBIAN
	mkdir -p package/lock/Library/LockInfo/Plugins
	cp -r com.burgch.lockinfo.HTCPlugin.bundle package/lock/Library/LockInfo/Plugins
	cp HTCPlugin package/lock/Library/LockInfo/Plugins/com.burgch.lockinfo.HTCPlugin.bundle
	cp HTC-control package/lock/DEBIAN/control
	find package/lock -name .svn -print0 | xargs -0 rm -rf
	find package/lock -name .DS_Store -print0 | xargs -0 rm -rf
	find package/lock -name Thumbs.db -print0 | xargs -0 rm -rf
	find package/lock -name pspbrwse.jbf -print0 | xargs -0 rm -rf
	find package/lock -name *.pspimage -print0 | xargs -0 rm -rf
	dpkg-deb -b package/lock HTCPlugin_$(shell grep ^Version: HTC-control | cut -d ' ' -f 2).deb
	
LW: LockWeatherPlugin
	cp LockWeatherPlugin ../../Plugin