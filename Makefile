TAG=3.19

all: prepare build copy

prepare:
	test -d linux || git clone -v \
	https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git \
	linux
	cd linux && git fetch
	gpg --list-keys 00411886 || \
	gpg --keyserver keys.gnupg.net --recv-key 00411886

build:
	cd linux && git verify-tag v$(TAG)
	cd linux && git checkout v$(TAG)
	cd linux && ( git branch -D build || true )
	cd linux && git checkout -b build
	if test -x patch/patch-$(TAG); \
	then cd linux && ../patch/patch-$(TAG); \
	else true; fi
	cp config/config-$(TAG) linux/.config
	cd linux && make oldconfig
	rm -f linux/arch/arm/boot/zImage
	cd linux && make -j3 zImage dtbs modules
	cat linux/arch/arm/boot/dts/sun7i-a20-bananapi.dtb >> \
	linux/arch/arm/boot/zImage
	cd linux && make LOADADDR=0x40008000 uImage

copy:
	rm linux/deploy -rf
	mkdir -p linux/deploy
	VERSION=$$(cd linux && make --no-print-directory kernelversion) && \
	cp linux/.config linux/deploy/config-$$VERSION
	VERSION=$$(cd linux && make --no-print-directory kernelversion) && \
	cp linux/arch/arm/boot/uImage linux/deploy/$$VERSION.uImage
	dd if=/dev/zero of=linux/deploy/dummy bs=1024 count=4
	VERSION=$$(cd linux && make --no-print-directory kernelversion) && \
	cat linux/deploy/dummy >> linux/deploy/$$VERSION.uImage
	cd linux && make modules_install INSTALL_MOD_PATH=deploy
	cd linux && make headers_install INSTALL_HDR_PATH=deploy/headers
	VERSION=$$(cd linux && make --no-print-directory kernelversion) && \
	cd linux && mkdir -p deploy/usr/src/linux-headers-$$VERSION
	VERSION=$$(cd linux && make --no-print-directory kernelversion) && \
	cd linux && mv deploy/headers/* \
	deploy/usr/src/linux-headers-$$VERSION
	VERSION=$$(cd linux && make --no-print-directory kernelversion) && \
	mkdir -p -m 755 linux/deploy/lib/firmware/$$VERSION; true
	VERSION=$$(cd linux && make --no-print-directory kernelversion) && \
	mv linux/deploy/lib/firmware/* \
	linux/deploy/lib/firmware/$$VERSION; true
	VERSION=$$(cd linux && make --no-print-directory kernelversion) && \
	cd linux/deploy && tar -czf $$VERSION-modules-firmware.tar.gz lib
	VERSION=$$(cd linux && make --no-print-directory kernelversion) && \
	cd linux/deploy && tar -czf $$VERSION-headers.tar.gz usr

install:
	mkdir -p -m 755 $(DESTDIR)/boot/uboot;true
	VERSION=$$(cd linux && make --no-print-directory kernelversion) && \
	cp linux/deploy/$$VERSION.uImage $(DESTDIR)/boot/uImage
	VERSION=$$(cd linux && make --no-print-directory kernelversion) && \
	cp linux/deploy/$$VERSION.uImage $(DESTDIR)/boot
	VERSION=$$(cd linux && make --no-print-directory kernelversion) && \
	cp linux/deploy/config-$$VERSION $(DESTDIR)/boot
	VERSION=$$(cd linux && make --no-print-directory kernelversion) && \
	cp linux/deploy/$$VERSION-modules-firmware.tar.gz $(DESTDIR)/boot
	VERSION=$$(cd linux && make --no-print-directory kernelversion) && \
	cp linux/deploy/$$VERSION-headers.tar.gz $(DESTDIR)/boot
	VERSION=$$(cd linux && make --no-print-directory kernelversion) && \
	tar -xzf linux/deploy/$$VERSION-modules-firmware.tar.gz -C $(DESTDIR)/

clean:
	test -d linux && cd linux && rm -f .config || true
	test -d linux && cd linux git clean -df || true

uimage:
	cd linux && git verify-tag v$(TAG)
	cd linux && git checkout v$(TAG)
	cd linux && ( git branch -D build || true )
	cd linux && git checkout -b build
	if test -x patch/patch-$(TAG); \
	then cd linux && ../patch/patch-$(TAG); \
	else true; fi
	cp config/config-$(TAG) linux/.config
	cd linux && make oldconfig
	rm -f linux/arch/arm/boot/zImage
	cd linux && make -j3 zImage dtbs
	cat linux/arch/arm/boot/dts/sun7i-a20-bananapi.dtb >> \
	linux/arch/arm/boot/zImage
	cd linux && make LOADADDR=0x40008000 uImage
