Barebones AVR128Dx avr-gcc Project
==================================

This is a basic skeleton for programming the AVR128Dx series MCUs using avr-gcc.

 1. Install prerequisites
 1. Download the appropriate [Microchip "ATPACK" for your MCU](http://packs.download.atmel.com/)
 1. `make help ; make vars`

:information_source: _Don't have a programmer? Me did I! If you have a spar mcu
with USB serial facilities, you can make your own with a single passive
component and a handful of jumper wires in minutes!_ See **[doc/PROGRAMMER.md](./doc/PROGRAMMER.md) for more info.

Prerequisites
-------------

 - [`avr-gcc`](https://gcc.gnu.org/wiki/avr-gcc)
 - [`pymcuprog`](https://pypi.org/project/pymcuprog/)
 - `make`


Instructions
------------
 1. Install the prerequisites (Mac: `brew install avr-gcc make ; pip3 install pymcuprog`)
 1. Download the appropriate [Microchip "ATPACK" for your MCU](http://packs.download.atmel.com/).
 1. Extract the atpack (it's a zip file), e.g. `unzip /path/to/Atmel.AVR-Dx_DFP.2.2.253.atpack -d /path/to/Atmel.AVR-Dx_DFP.2.2.253_atpack`

Then:

```bash
ATPACK="/path/to/Atmel.AVR-Dx_DFP.2.2.253_atpack" \
USBDEVICE="/dev/tty.usb<whatever> \
make upload
```


### Usage

The `ATPACK` and `USBDEVICE` environment variables are required. The default
architecture is `avr128da28` (because that's what I have on hand). You can
change this using the `DEVICE` environment variable.

 - `make help` for target information.
 - `make vars` for env variables.

### Wait.."atpack"?
:warning: If your `avr-gcc` is built with `avr128dx` support, skip the
atpack stuff and delete any lines that contain `ATPACK` from the [Makefile](./Makefile).

See [Supporting "unsupported" Devices in the avr-gcc Wiki for more info](https://gcc.gnu.org/wiki/avr-gcc#Supporting_.22unsupported.22_Devices).
