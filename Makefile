Compiler=g++

LDFLAGS=	-lobjc \
				-framework Foundation \
				-framework UIKit \
				-framework CoreFoundation \
				-framework CoreGraphics \
				-framework CoreLocation \
				-framework GraphicsServices \
				-framework Celestial \
				-multiply_defined suppress \
				-L/usr/lib \
				-F/System/Library/Frameworks \
				-F/System/Library/PrivateFrameworks \
				-dynamiclib \
				-init _WeatherIconInitialize \
				-Wall \
				-Werror \
				-lsubstrate \
				-lobjc \
				-ObjC++ \
				-fobjc-exceptions \
				-march=armv6 \
				-mcpu=arm1176jzf-s \
				-fobjc-call-cxx-cdtors

CFLAGS= -dynamiclib \
  -fsigned-char -g -fobjc-exceptions \
  -Wall -Wundeclared-selector -Wreturn-type \
  -Wredundant-decls \
  -Wchar-subscripts \
  -Winline -Wswitch -Wshadow \
  -I/var/include \
  -I/var/include/gcc/darwin/4.0 \
  -D_CTYPE_H_ \
  -D_BSD_ARM_SETJMP_H \
  -D_UNISTD_H_

Objects= WeatherView.o WeatherIcon.o

Target=WeatherIcon.dylib

all:	$(Target)

install: 	$(Target)
		chmod 755 $(Target)
		rm -f /Library/MobileSubstrate/DynamicLibraries/$(Target)
		cp $(Target) /Library/MobileSubstrate/DynamicLibraries/
		restart

$(Target):	$(Objects)
		$(Compiler) $(LDFLAGS) -o $@ $^
		ldid -S $(Target)

%.o:	%.mm
		$(Compiler) -c $(CFLAGS) $< -o $@

clean:
		rm -f *.o $(Target)
		rm -rf package

package:	$(Target)
	mkdir -p package/DEBIAN
	mkdir -p package/Library/Themes
	mkdir -p package/Library/MobileSubstrate/DynamicLibraries
	mkdir -p package/System/Library/CoreServices/SpringBoard.app
	cp -a Default*.theme package/Library/Themes
	cp -a Transparent*.theme package/Library/Themes
	cp -a Weather\ Icon.theme package/Library/Themes
	cp -a $(Target) package/Library/MobileSubstrate/DynamicLibraries
	cp -a *.png package/System/Library/CoreServices/SpringBoard.app
	cp -a control package/DEBIAN
	find package -name .svn -print0 | xargs -0 rm -rf
	find package/Library/Themes/ -name control -print0 | xargs -0 rm -rf
	dpkg-deb -b package weathericon_$(shell grep ^Version: control | cut -d ' ' -f 2)_iphoneos-arm.deb
