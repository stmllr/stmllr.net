---
layout: post
title: Cirrus Logic Audio Card on Raspberry Pi 2 with Debian Jessie
date: 2015-08-31 09:42
excerpt: WARNING! In my opinion the hardware drivers of the Cirrus Logic Audio Card never left an experimental state and the card is not usable in production. It's an odyssey to put it into operation on a Raspberry Pi 2. Here's a summary about the current state, pointing to useful resources and providing a tutorial to get the card up and running with Debian Jessie.
tags:
  - Raspberry Pi
  - Cirrus Logic
  - Audio
  - Linux Kernel
---

[UPDATE 2015/09/01] Updated installation instructions for the devicetree drivers. Thanks to HiassofT.

### Motivation

* The audio card does not work out of the box on a Raspberry Pi 2 (at least until 2015/08/31).
* Official documentation is served as a PDF file but PDF is not the web.
* No social media channel from Cirrus Logic found which provides frequent update for users.
* Useful information can be found in the Element14 community forum, but IMO it is hidden through bad UX.
* [Build instructions from the official Cirrus repository](https://github.com/CirrusLogic/rpi-linux/wiki/Building-the-code) are outdated in a few places.
* [A lot of frustration in the web](http://www.diyaudio.com/forums/pc-based/270908-raspberry-pi-cirruslogic-audio-card-fail.html).
* A summary would save other peoples time and work.

Credits go the the brave authors and contributors who shared their knowledge and code.

### The Cirrus Logic Audio

The [Cirrus Logic Audio Card](http://uk.farnell.com/wolfson-microelectronics/cirrus-logic-audio-card/cirrus-logic-audio-card-for-raspberry/dp/2448312?searchRef=SearchLookAhead) is a high quality sound card (24-bit, 192kHz) and comes with analogue line-in/-out,
SPDIF in/out and an onboard stereo microphone. It connects to the 40-pin GPIO of the Raspberry Pi 2.

![Cirrus Logic Audio Card on the Raspberry Pi 2](/files/images/rpi2-cirrus/rpi2-cirrus-logic-audio-card.jpg)

More details can be found in the [official manual](http://www.element14.com/community/docs/DOC-72078?ICID=CirrusLogicAudio-topMain-usermanual)
and the [specs datasheets](http://www.element14.com/community/docs/DOC-71261?ICID=CirrusLogicAudio-topMain-techspecs#downloads).

### But it doesn't fit into my case...

Craig Berscheidt from [Built-to-Spec](http://www.built-to-spec.com/) has designed a custom case.
He fortunately provides the design files at [thingiverse](http://www.thingiverse.com/thing:785289)
and the corresponding assembly instructions at the [Built-to-Spec blog](http://www.built-to-spec.com/blog/raspberry-pi-b-cirrus-logic-audio-card-case/).
If you don't have a laser cutter, just **buy your case** at the [Built-to-Spec store](http://builttospecstore.storenvy.com/products/12911260-rpi-b-cirrus-logic-audio-card-case).

Since RPi 2 has [the same form factor as RPi B+](https://www.raspberrypi.org/products/raspberry-pi-2-model-b/),
the case from Built-to-Spec fits. The PCB clips are a bit brittle, be careful when snapping them onto the Raspberry Pi.

### And then it says: no soundcards found...

You plugged everything in and together, installed a raspbian image to your sd card, but...

    ~ $ aplay -l
    aplay: device_list:268: no soundcards found...

or anything but the cirrus soundcard:

    ~ $ aplay -l
    **** List of PLAYBACK Hardware Devices ****
    card 0: ALSA [bcm2835 ALSA], device 0: bcm2835 ALSA [bcm2835 ALSA]
      ...
    card 0: ALSA [bcm2835 ALSA], device 1: bcm2835 ALSA [bcm2835 IEC958/HDMI]

As stated before, the card does not run out of the box on a Raspberry Pi 2.
You have to [build custom kernel modules](#building-and-installing-the-drivers-for-the-cirrus-logic-audio-card) and add the driver to the [device tree](https://www.raspberrypi.org/documentation/configuration/device-tree.md).

### Installing Debian Jessie

One of the benefits of Raspberry Pi 2 is, that it comes with an ARMv7 processor architecture.
ARMv7 is widely supported by linux distributions and it doesn't require prebuilt Raspbian packages.
For Debian, the port of your choice is called [*armhf* (arm hardfloat port)](https://wiki.debian.org/ArmHardFloatPort)
often refered to as "EABI hard-float ABI".

Sjoerd Simons from Collabora [provides prebuild Debian Jessie images for Raspberry Pi 2](https://images.collabora.co.uk/rpi2/).
The [documentation can be found in a blog post](http://sjoerd.luon.net/posts/2015/02/debian-jessie-on-rpi2/).

However, I did not manage to boot a custom kernel with Cirrus support on that image.
Therefore I suggest to [install](https://www.raspberrypi.org/documentation/installation/installing-images/README.md)
the [official Raspbian image](https://www.raspberrypi.org/downloads/raspbian/) first
and then upgrade to Jessie by following the [upgrade instruction in the Jessie release notes](https://www.debian.org/releases/stable/armhf/release-notes/ch-upgrading.en.html).

#### tl;dr

If you feel unfamiliar with the following steps, please follow the upgrade instructions mentioned above.
This section comes with no warranty:

* Go to `/etc/apt/` and replace any occurences of `wheezy` with `jessie` within `sources.list` and `sources.list.d/*` files.
* Remove the configuration file `/etc/apt/sources.list.d/collabora.list`. It's a repo for a lightweight browser which was
  optimized for the limited resources of the Raspberry Pi 1.
  Collabora does not provide builds for Jessie and I guess you don't need this browser on Raspbery Pi 2.
* Execute the following commands as root or using `sudo`:

      apt-get update
      apt-get upgrade
      apt-get dist-upgrade

  This will probably take some time. For some packages you will be ask to choose a particular configuration file.
  If you just started with a fresh installation, you can safely answer "Yes" to any of these questions and install
  the configuration from the maintainers package.

* Now reboot your machine.

### Building and installing the drivers for the Cirrus Logic Audio Card

Now to the nasty part. The kernel module from Cirrus has not made it into the official kernel repository.
You have to build it by yourself.
The fork from [HiassofT](https://github.com/HiassofT/rpi-linux) is currently the most active and recent one.
The following instructions are based on a [forum post on element14 by HiassofT](http://www.element14.com/community/thread/43711/l/driver-fixes-and-updates-to-kernel-31816-and-405):

    apt-get install screen bc
    screen
    git clone -b cirrus-4.1.y --single-branch --depth 1 https://github.com/HiassofT/rpi-linux.git
    cd rpi-linux/
    make bcm2709_defconfig && make -j4 && make -j4 modules

Now press `[CTRL a] + d` to quit your console session and let your Raspberry work hard in the background.
After half a day, get back to your session and install the build:

    screen -r
    sudo make modules_install
    sudo cp /boot/kernel7.img /boot/kernel7.img.orig-bak
    sudo ./scripts/mkknlimg arch/arm/boot/zImage /boot/kernel7.img
    sudo cp -f arch/arm/boot/dts/*.dtb /boot/
    sudo cp -f arch/arm/boot/dts/overlays/*.dtb arch/arm/boot/dts/overlays/README /boot/overlays/

Add the following lines to `/boot/config.txt`

    dtoverlay=rpi-cirrus-wm5102-overlay
    dtoverlay=i2s-mmap

And add the following lines to `/etc/modprobe.d/cirrus.conf`

    softdep arizona-spi pre: arizona-ldo1
    softdep spi-bcm2708 pre: fixed
    softdep spi-bcm2835 pre: fixed
    softdep snd-soc-wm8804-i2c pre: snd-soc-rpi-wsp-preinit
    softdep snd-soc-rpi-wsp pre: snd-soc-wm8804-i2c

    # To disable the buildin soundcard, also blacklist the `snd_bcm2835` module
    blacklist snd_bcm2835

Protect your kernel from being overridden by upgrades of the the bootloader packages when running `apt-get upgrade`:

    sudo apt-mark hold raspberrypi-bootloader

Reboot your Raspberry Pi.

Done.

### Testing the audio card

Login, open a terminal and execute the following command:

    ~ $ aplay -l
    card 1: sndrpiwsp [snd_rpi_wsp], device 0: WM5102 AiFi wm5102-aif1-0 []
      Subdevices: 1/1
      Subdevice #0: subdevice #0

Then create a mixer setup. Cirrus provides some convenience scripts to preconfigure mixer settings.
You can [download the scripts from the CirrusLogic repository](https://github.com/CirrusLogic/wiki-content/archive/master.zip).

After unpacking, activate the line-out channel by executing:

    ./scripts/Playback_to_Lineout.sh

Connect your stereo to the green audio jack and start your favorite music player.

### Way too complicated. Anything more easy?

Go and kick Cirrus to provide bug free drivers for their audio card through the official raspberry kernel.
It's a shame they announce compatibility with Raspberry Pi 2 but don't provide drivers for anyone except experienced kernel hackers.
Their prebuild system image is not an option, because it probably breaks on upgrades.

There are some Debian packages to install a pre-build kernel + modules by [autostatic](http://rpi.autostatic.com/).
However there's neither a build provided for Debian Jessie nor some source packages available.
Not sure if you receive kernel updates through this repo at all...
(I found that in the [middle of an element14 forum post](http://www.element14.com/community/message/151698/l/re-cirrus-logic-audio-card-working-on-the-raspberry-pi-2#151698))

### Conclusion

If you sell hardware for Raspberry Pi, ...

* provide stable drivers through the [offical raspberrypi linux kernel repository](https://github.com/raspberrypi/linux),
* provide a case if it does not fit into the usual cases,
* support your community with official updates, documentation and discussions,
* add an issue tracker to your source code repository,
* and don't fool your customers with bad promises about compatibility.

<section class="comments">
	<h3>Comments</h3>
	<ol>

		<li id="comment-f68551c6-24b8-4a81-bec4-1890576f7c7b">
			<span class="comment-author">Bob</span>
			<time class="comment-time" datetime="2015-10-07 00:14">on October 7, 2015 at 00:14</time>
			<p>
				Is there a way to get a single zip file of the sources for the driver, separate from the rest of the kernel?
				It seems to me that building a loadable kernel module would be the simplest path.  I've done a few of those in the past, and I think they are a lot easier than trying to embed a driver in the kernel.
				<br>
				I have the 4.1-rpi.y kernel source on an external drive.  I would be glad to try a few builds if it would help people out.
			</p>
		</li>

		<li id="comment-578bfc32-12fb-4381-aac8-d43ef21906ba">
			<span class="comment-author">Steffen</span>
			<time class="comment-time" datetime="2015-10-07 07:01">on October 7, 2015 at 07:01</time>
			<p>
				@Bob<br>Never thought about that. Not sure if you can make it without devicetree.
			</p>
		</li>

		<li id="comment-91642005-6841-4dc8-9223-3111c1896811">
			<span class="comment-author">Dave Whiteley</span>
			<time class="comment-time" datetime="2015-10-07 07:43">on October 7, 2015 at 07:43</time>
			<p>
				Many thanks for your work.
				<br>
				Documentation is difficult.  You have done it superbly.  If only others...
			</p>
		</li>

		<li id="comment-bca50934-640a-4cdb-97a6-22836e1a2888">
			<span class="comment-author">Tom</span>
			<time class="comment-time" datetime="2015-10-13 19:02">on October 13, 2015 at 19:02</time>
			<p>
				So I used Ragnar's image and it worked on Friday.  I had sound playing out the Cirrus board to speakers.
				Today I get "no soundcards found".  Did the RPI update without me knowing it and cause this?
			</p>
		</li>

		<li id="comment-adb6eef4-53ef-44b8-8db2-5952525ba74f">
			<span class="comment-author">Steffen</span>
			<time class="comment-time" datetime="2015-10-13 20:58">on October 13, 2015 at 20:58</time>
			<p>
				@Tom, can you post the output of the following commands:<br>
				<ul>
					<li>dpkg -l raspberrypi-bootloader</li>
					<li>uname -r</li>
					<li>dmesg</li>
				</ul>
			</p>
		</li>

		<li id="comment-c2fadb30-afe6-4242-89fd-db5b86161675">
			<span class="comment-author">Gert Kok</span>
			<time class="comment-time" datetime="2015-10-24 09:16">on October 24, 2015 at 09:16</time>
			<p>
				Just above the bold tl;dr on this page is a link to an official Raspbian image. At that page an official Jessie can be found as well. I used that.<br>
        <br>
        Version:September 2015<br>
        Release date:2015-09-24<br>
        Kernel version:4.1<br>
        <br>
        Following your instructions I now have  1.20150923-1   and 4.1.10-v7+ but still no audiodevices are to be found.
        <br>
        selected output from messages:<br>
        Oct 24 08:44:54 zoonyx kernel: [    6.339437] arizona_spi: disagrees about version of symbol arizona_dev_init<br>
        Oct 24 08:44:54 zoonyx kernel: [    6.339474] arizona_spi: Unknown symbol arizona_dev_init (err -22)<br>
        Oct 24 08:44:54 zoonyx kernel: [    6.339533] arizona_spi: disagrees about version of symbol arizona_dev_exit<br>
        Oct 24 08:44:54 zoonyx kernel: [    6.339548] arizona_spi: Unknown symbol arizona_dev_exit (err -22)<br>
        Oct 24 08:44:54 zoonyx kernel: [    6.383694] wm8804: probe of 1-003a failed with error -5<br>
        <br>
        what can I do more?<br>
        ----------------------------------------------------------------------------------------<br>
        Will there be a day when the 'hold' on the installed kernel can be removed?<br>
			</p>
		</li>

		<li id="comment-f1331296-9d08-4757-b00c-2e2a933046e0">
			<span class="comment-author">Steffen</span>
			<time class="comment-time" datetime="2015-10-26 11:23">on October 26, 2015 at 11:23</time>
			<p>
				@Gert, it seems the package structure has been modified for the Jessie Raspbian image
				and the kernel has been ripped off from the raspberrypi-bootloader package.
				I'd need some time to investigate and test my setup instructions with the new Raspbian image.
				This could take some time since I am quite busy ATM. In the meantime I suggest to stick to the wheezy image and the "tl;dr" procedure.
			</p>
			<p>Unless cirrus provides stable audio drivers to be merged into the official rpi kernel, you will have to deal with the 'hold' workaround.</p>
		</li>

		<li id="comment-e61c70eb-73af-40bb-b639-3e33c8b1495b">
			<span class="comment-author">unsys</span>
			<time class="comment-time" datetime="2015-11-18 09:47">on November 11, 2015 at 09:47</time>
			<p>
				Thanks, helped me a lot :) would donate some bits if would post your bitcoin pub address near GPG
			</p>
		</li>

		<li id="comment-d2aea990-8255-4539-a69d-0aa8c5723e24">
			<span class="comment-author">Marino</span>
			<time class="comment-time" datetime="2015-11-20 07:19">on November 20, 2015 at 07:19</time>
			<p>
				Hi,

				at first, thank you for your work to create that tutorial.
				I tryed to use this tutorial for my Pi2 with Raspbian Jessie, Cirrus Logic Audio and the original 7" touch display.<br><br>

				After installation is no audiodevice found. When I use the original tutorial the card 0 exists two times.
				The first one with 8 sub devices, the second one with one sub device. But no "WM5102 AiFi wm5102-aif1-0 "-expression in it.<br><br>

				More confusing for me, the touch is not working any more after that.
				In my understanding this should add the cirrus driver to the kerne and overwrite that with the existing one.
				So either the driver for the touch has been overwritten or there is a problem and the driver doesn't work anymore
				because of an other problem.<br><br>

				Do you have any a hint for me, what I can do to get the Pi2 with Cirrus and Touch working together and not only separately?<br><br>

				kind regards<br>
				Marino
			</p>
		</li>

		<li id="comment-fcf994da-aaf0-4c66-9bbc-d901753c4db3">
			<span class="comment-author">Marino</span>
			<time class="comment-time" datetime="2015-11-20 07:20">on November 20, 2015 at 07:20</time>
			<p>
				Sorry, dass ich nochmal störe. Ich sehe gerade, dass Du aus Freiburg kommst.
				Du kannst natürlich auch gerne auf deutsch antworten, falls das einfacher ist :)
			</p>
		</li>

		<li id="comment-af6aba8e-a42d-458c-b8e8-c5c2e5e87f3c">
			<span class="comment-author">Marino</span>
			<time class="comment-time" datetime="2015-11-20 09:26">on November 20, 2015 at 09:26</time>
			<p>
				english:<br>
				I don't wanna annoy you, but I've got a tip, which was not mentioned before.
				When you compile with "make" the Pi2 only uses one core, which is a maximum of 25% for the CPU load.
				You can get a CPU load of 100%, when you use the option "-j4". So with the command "make -j4" the Pi2 uses all
				of the 4 cores und goes up straight to 99-100% CPU load.<br><br>

				In my case, I try to compile with Wheezy instead of Jessie in the hope to get the Cirrus and the official Touch
				display working simultaneously. So using 4 Cores instead of only 1 is a big step.

				Deutsch:<br>
				Nicht, dass ich noch störe, aber ich habe einen Tipp, der bisher nicht erwähnt wird.<br><br>

				Möchte man kompilieren mit dem Befehl "make", so nutzt der Pi2 nur einen Kern. Das dauert natürlich ewig.
				Die CPU-Last wird also zu maximal 25% genutzt.<br><br>

				Nutzt man einen Pi2, so kann man mit der Option -j4 den Pi2 dazu bringen, alle Kerne zum Kompilieren zu nutzen.
				Also dann mit "make -j4" und schon steigt die CPU-Last auf 100%. <br><br>

				Da ich damit ja gerade teste und mal mit Wheezy ausprobiere, ob ich anschließend auch kein Touch mehr nutzen kann,
				kommt mir das gerade sehr gelegen. Schnell fertig ist es dann zwar nicht, aber immerhin.
			</p>
		</li>

		<li id="comment-25697a87-0278-485a-a6f9-fa03ca838aa3">
			<span class="comment-author">Steffen</span>
			<time class="comment-time" datetime="2015-11-20 12:01">on November 20, 2015 at 12:01</time>
			<p>
				Marino, thanks for your valuable comments. Sorry for the delay in publishing and answering them.
				All comments are moderated because of massive spam. And currently I hardly have any time for this blog.<br><br>

				I guess the two audio devices you see are onboard bcm2835. Could be that you can't find the cirrus
				device because the rpi kernel packages from the Raspbian distribution have changed significantly.
				I didn't have time or the need to dig into that.<br><br>

				The cirrus driver itself seems to be in such a bad state, that it breaks other hardware. I have read about that
				in some forums, e.g. <a href="http://www.diyaudio.com/forums/pc-based/270908-raspberry-pi-cirruslogic-audio-card-fail.html">
				http://www.diyaudio.com/forums/pc-based/270908-raspberry-pi-cirruslogic-audio-card-fail.html</a><br><br>

				I suggest to use a cheap USB soundcard if you just want to have better sound quality on audio-out.
				If you need more fancy HQ features, try a different device, e.g. one of the <a href="https://www.hifiberry.com/">
				HiFiBerry</a> who's drivers are part of the official Raspbian distribution. Though I never tested this one.<br><br>

				It's a shame that Cirrus sells a product which is IMHO not ready for production. I added a big fat warning
				on top of this blog post.<br><br>

				Thanks for your hint about "make -j4". I have added it to the tutorial.
			</p>
		</li>

		<li id="comment-c9f96513-c98f-40ea-a045-c8a332be3472">
			<span class="comment-author">Marino</span>
			<time class="comment-time" datetime="2015-11-20 21:30">on November 20, 2015 at 21:30</time>
			<p>
				Hi Steffen,<br><br>

				there is no problem with publishing with delay. The only problem was, that I worked on the Pi during the delay
				and could not edit my posts :)<br><br>

				Last week I saw a stereo pre-amplifiert. This amplifier has the ability to convolve audio in realtime with filters.
				They use a Pi2 with the cirrus for that (<a href="http://www.audiovero.de/preamp-14-cleanvolver.php">http://www.audiovero.de/preamp-14-cleanvolver.php</a>).
				Intereseting to know how they done it ;)<br><br>

				In my case I need a display to show the video from my door communication system. Atm my normal DECT-Phones are
				used to do the audio part und open the door (Asterisk and then a Fritzbox as Client with the phones, which are
				managed by the Fritzbox).<br>
				Later I want to test, if the Pi is also capable to be a SIP-Client. For Video and audio.
				Thats what I need the Cirrus for. Speaker and Mic on ohne board without big cirumstances I thought.
				Bad Idea, I know. Now I know better ;)<br><br>

				But the part of audio convolving was also a point to test that. It runs on that hardware and I need that for my
				system and don't want to run a PC every time. So that was the second reason to go with the Cirrus.
				But that needs a digital input and a digital output.<br><br>

				For Door Communication I need Mic, Speaker and Touchdisplay. For test with audio convolving a display is not
				necessary, but even without It is the change to get the cirrus running nearly impossible for me.<br><br>

				At least I could give you the hint with make -j4.<br><br>

				I think me cirrus is going back to the seller, because of the lack of function.
				I testet 2 days and the cirrus is still not working with wheezy or jessie.
				In that time I could work and buy hardware that is capable to do his job, even if it costs a hack of a lot more money.
			</p>
		</li>

		<li id="comment-e7914380-831f-4ae0-811d-cc077dc33e8b">
			<span class="comment-author">Ronald</span>
			<time class="comment-time" datetime="2015-12-12 00:39">on December 12, 2015 at 00:39</time>
			<p>Thanks for the information for installing the Cirrus Logic Audio board.<br>
				I first installed the “2015-11-21-raspbian-jessie.img” image and then used your installation procedure. The card is working perfect.<br><br>

				But for my project I want to use next to the Cirrus Logic audio card the Adafruit 2.8” TFT/Touch screen.<br>
				I have not found any information about building code for both the Logic audio card and the TFT display.<br>
				The result is always a not working raspberry pi.<br><br>

				Do you or anybody have any suggestions?
			</p>
		</li>

		<li id="comment-8c66e31c-2b97-4b37-b1bb-411607eecd80">
			<span class="comment-author">Steffen</span>
			<time class="comment-time" datetime="2015-12-15 09:59">on December 15, 2015 at 09:59</time>
			<p>Ronald, I have neither experiences with the rasbian-jessie image nor with the TFT screen.<br>
				It looks like adafruit provides a compiled kernel including the TFT drivers. You would need to get the sources
				of these drivers from Adafruit, merge them with the ones from cirrus onto the rasbian kernel repository
				and then compile the kernel modules on your own.<br>
				I'm sorry that I can't provide any more details.<br><br>

				Any hardware without proper drivers merged into the official raspbian image heavily suck for the end users.
			</p>
		</li>

	</ol>
</section>
