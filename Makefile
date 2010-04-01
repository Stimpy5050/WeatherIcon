CC=/Developer/Platforms/iPhoneOS.platform/Developer/usr/bin/arm-apple-darwin9-gcc-4.0.1
CPP=/Developer/Platforms/iPhoneOS.platform/Developer/usr/bin/arm-apple-darwin9-g++-4.0.1
LD=$(CC)
platform=/Developer/Platforms/iPhoneOS.platform
allocate=${platform}/Developer/usr/bin/codesign_allocate
export CODESIGN_ALLOCATE=${allocate}

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

%.o:	%.mm
		$(CPP) -c $(CFLAGS) $< -o $@

clean:
		rm -f *.o WeatherIconPlugin HTCPlugin LockWeatherPlugin HTCHeaderView

HTC: HTCPlugin
	cp HTCPlugin ../Plugin