# vCR Glove Firmware

This directory contains the Arduino firmware for the two vCR Glove electronic units.

The same firmware is used for both the left-hand and right-hand units. A setting near the beginning of the program (IS_LEFT_HAND) identifies which hand is being programmed.

## Requirements

The firmware is intended for the:

- Seeed Studio XIAO nRF52840
- Arduino IDE
- vCR Glove PCB and electronics described in this repository

Install the Arduino IDE and the required board support and libraries before compiling the program.

## Opening the Firmware

Open:

`vCR_Glove.ino`

in the Arduino IDE.

The Arduino IDE should recognize the file as the `vCR_Glove` sketch.

## Selecting the Hand

Before uploading the firmware, locate the following setting near the beginning of the program:

`IS_LEFT_HAND`

Set this value appropriately for the unit being programmed:

- `IS_LEFT_HAND = 1` - left-hand unit
- `IS_LEFT_HAND = 0` - right-hand unit

Both units use otherwise identical firmware.

## Programming the First Unit

1. Turn the vCR Glove unit power switch **OFF**.
2. Connect the unit to the computer using a USB cable.
3. Start the Arduino IDE and open `vCR_Glove.ino`.
4. Set `IS_LEFT_HAND` for the hand being programmed.
5. Select the **Seeed Studio XIAO nRF52840** as the target board.
6. Select the COM port assigned to the connected XIAO.
7. Verify/compile the program.
8. Upload the firmware to the unit.

After a successful upload, disconnect the USB cable.

## Programming the Second Unit

1. Connect the second hand unit to the computer by USB with its power switch **OFF**.
2. Change `IS_LEFT_HAND` to the setting for the second hand.
3. Select the COM port assigned to the second XIAO.
4. Verify/compile the program.
5. Upload the firmware.
6. Disconnect the USB cable.

Both units are now programmed with the same firmware but with their respective left/right hand identifiers.

## Operation

With both units programmed and disconnected from USB:

1. Turn on both units.
2. Press the START button on either unit.
3. The two units establish Bluetooth communication and begin the synchronized stimulation sequence after a short delay.

Only one START button needs to be pressed.

Turning the units off stops operation. After power is restored, stimulation does not begin until a START button is pressed.

## Source Code

Operating parameters and hardware assignments are defined in the Arduino source code. These include the actuator drive parameters, burst timing, channel sequencing, amplitude control, indicator LEDs, amplifier control, and Bluetooth synchronization.

The firmware supplied here corresponds to the vCR Glove hardware documented in this repository.

## Arduino IDE Configuration

The firmware was compiled and tested using the following Arduino board configuration:

* **Board:** Seeed XIAO nRF52840 Sense
* **Board support package:** Seeed nRF52 Boards
* **Tested version:** 1.1.13

Install the `Seeed nRF52 Boards` package using the Arduino IDE Boards Manager and select **Seeed XIAO nRF52840 Sense** as the target board.

The firmware uses:

`#include <bluefruit.h>`

`#include <math.h>`

`#include <nrf.h>`

No separately installed Arduino libraries are required for these includes. In particular, the Bluefruit support used by this firmware is supplied by the `Seeed nRF52 Boards` package.

The similarly named **Seeed nRF52 mbed-enabled Boards** package should not be substituted for the board package specified above.

## Single-frequency mode:

250 Hz on all channels. Closest to the published Tass-style stimulation.

## Multi-frequency mode:
Experimental option using 207.65, 233.08, 277.18, and 311.13 Hz.
Finger order and frequency order are independently shuffled each CR cycle.
This mode has not been evaluated clinically and is not part of the published Tass protocol.

## License

The firmware is licensed under the MIT License. See:

`../LICENSE.txt`