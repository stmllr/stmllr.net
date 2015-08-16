---
layout: post
title: Cirrus Logic Audio Card on Raspberry Pi 2
date: 2015-08-16 18:53
excerpt: The Cirrus Logic Audio Card does not work out of the box on your Raspberry Pi 2 and you are lost? Bt;dt.
tags:
  - RaspberryPi
  - Cirrus Logic
  - Audio
---

### Motivation

* The audio card does not work out of the box on a Raspberry Pi 2 (at least until 2015/08/16).
* Official documentation is served as a PDF file but PDF is not the web.
* No social media channel from Cirrus Logic found which provides frequent update for users.
* Element14 community forum comes with bad UX.
* A summary would save other peoples time and work.

### About Cirrus Logic Audio Card and Raspberry Pi 2

The Cirrus Logic Audio Card is a high quality sound card (24-bit, 192kHz) and comes with analogue line-in/-out,
SPDIF in/out and an onboard stereo microphone. It connects to the 40-pin GPIO of the Raspberry Pi 2.

![Cirrus Logic Audio Card on the Raspberry Pi 2](/files/images/rpi2-cirrus/rpi2-cirrus-logic-audio-card.jpg)

More details can be found in the [official manual](http://www.element14.com/community/docs/DOC-72078?ICID=CirrusLogicAudio-topMain-usermanual)
and the [specs datasheets](http://www.element14.com/community/docs/DOC-71261?ICID=CirrusLogicAudio-topMain-techspecs#downloads)

### But it does not fit into my case

Craig Berscheidt from [Built-to-Spec](http://www.built-to-spec.com/) has designed a custom case.
He fortunately provides the design files at [thingiverse](http://www.thingiverse.com/thing:785289)
and the corresponding assembly instructions at the [Built-to-Spec blog](http://www.built-to-spec.com/blog/raspberry-pi-b-cirrus-logic-audio-card-case/).
If you have no laser cutter, just **buy your case** at the [Built-to-Spec store](http://builttospecstore.storenvy.com/products/12911260-rpi-b-cirrus-logic-audio-card-case).

Since RPi 2 has [the same form factor as RPi B+}(https://www.raspberrypi.org/products/raspberry-pi-2-model-b/),
the case from Built-to-Spec should fit. However I did not (yet) try.

### And then it says: no soundcards found...

Everything plugged in and together, but...

    ~ $ aplay -l
    aplay: device_list:268: no soundcards found...

or alternatively:

    ~ $ alsamixer
    cannot open mixer: No such file or directory

As stated before, the card does not run out of the box on a Raspberry Pi 2.
You have to [build custom kernel modules](https://github.com/CirrusLogic/rpi-linux/wiki/Building-the-code)
and add the driver to the [device tree](https://www.raspberrypi.org/documentation/configuration/device-tree.md)

### Can I haz the codez?

    apt-get install screen
    screen
    git clone --depth 1 --branch cirrus-4.1.y-rebased https://github.com/stmllr/rpi-linux.git
    cd rpi-linux
    make bcm2709_defconfig
    make && make modules

Now press `[CTRL a] + d` to quit your console session and let Raspi work hard in the background.
After half a day, get back to your session

    screen -r
    sudo make modules_install
    ./tools/mkimage/mkknlimg arch/arm/boot/zImage /tmp/kernel7.img
    sudo mv /boot/kernel7.img ~/kernel7.img
    sudo mv /tmp/kernel7.img /boot/
    sudo mv /boot/overlays/rpi-cirrus-wm5102-overlay.dtb ~/rpi-cirrus-wm5102-overlay.dtb
    sudo cp arch/arm/boot/dts/rpi-cirrus-wm5102-overlay.dtb /boot/overlays/

Add the following line to `/boot/config.txt`

    dtoverlay=rpi-cirrus-wm5102-overlay

Add the following lines to `/etc/modprobe.d/raspi-blacklist.conf`

    softdep arizona-spi pre: arizona-ldo1
    softdep spi-bcm2708 pre: fixed

Reboot your RasPi. Done.

### Way too complicated. Anything more easy?

There are some Debian packages to install a pre-build kernel + modules by [autostatic](http://rpi.autostatic.com/).
However there are no source packages available. So it's up to you if you trust it.
Not sure if you receive kernel updates through this repo at all...
I stumbled upon this in the ["Cirrus Logic Audio Card working on the Raspberry Pi 2" post of the element14 community forum](http://www.element14.com/community/message/151698/l/re-cirrus-logic-audio-card-working-on-the-raspberry-pi-2#151698)

