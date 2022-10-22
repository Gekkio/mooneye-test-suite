# Mooneye Test Suite

Mooneye Test Suite is a suite of Game Boy test ROMs.

[![Build Status](https://github.com/Gekkio/mooneye-test-suite/workflows/ci/badge.svg)](https://github.com/Gekkio/mooneye-test-suite/actions)

[Prebuilt binary test ROMs are available here](https://gekkio.fi/files/mooneye-test-suite/). They are automatically
built and deployed whenever there's new changes in the main branch.

For documentation about known behaviour, see [Game Boy: Complete Technical Reference](https://github.com/Gekkio/gb-ctr)

## Suite structure

* `acceptance`: the main "acceptance" tests which form the bulk of the test suite and are easily verifiable on hardware
* `emulator-only`: tests that are complicated to verify on hardware (e.g. require special test hardware), so they are commonly executed only on emulators
* `madness`: nope
* `manual-only`: tests that require manual verification (e.g. looking at the screen, or listening to audio) on real hardware
* `misc`: extra tests for CGB / AGB hardware that are not part of the main suite
* `utils`: utilities that are not really tests, but might be useful to some people

## Test naming

Some tests are expected to pass only a single console model:

* dmg = Game Boy
* mgb = Game Boy Pocket
* sgb = Super Game Boy
* sgb2 = Super Game Boy 2
* cgb = Game Boy Color
* agb = Game Boy Advance
* ags = Game Boy Advance SP

In addition to model differences, SoC revisions can affect the behaviour.
Revision 0 refers always to the initial version of a SoC (e.g. CPU CGB). AGB
and AGS use the same SoC models, but in two different packages. The following
SoC models have several revisions:

* DMG: 0, A, B, C
* CGB: 0, A, B, C, D, E
* AGB: 0, A, A E, B, B E. Revision E also exists, but only in Game Boy Micro
  (OXY) so it is out of this project's scope. However, A E and B E are most
  likely actually just E revision in A or B-compatible package.

In general, hardware can be divided to a couple of groups based on their
behaviour. Some tests are expected to pass on a single or multiple groups:

* G = dmg+mgb
* S = sgb+sgb2
* C = cgb+agb+ags
* A = agb+ags

For example, a test with GS in the name is expected to pass on dmg+mgb +
sgb+sgb2.

## Pass/fail reporting

Most tests report a single pass/fail state using [a simple protocol](https://github.com/Gekkio/mooneye-test-suite/blob/a2dac64c1c17b4efb98e168ab0ad3beaae6bff4c/common/lib/quit.s#L58) which is
designed to make it easy to detect the test result in both emulators and real
hardware. On real hardware you can use the link port to read data sent by the
test ROM. In emulators you can either use the link port, or detect the
use of the `LD B, B` opcode, which is used as a "debug breakpoint" in some
emulators.

A passing test:

- writes the Fibonacci numbers 3/5/8/13/21/34 to the registers B/C/D/E/H/L
- executes an `LD B, B` opcode
- sends the same Fibonacci numbers using the link port. In emulators, the
  serial interrupt doesn't need to be implemented since the mechanism uses busy
  looping to wait for the transfer to complete instead of relying on the
  interrupt
- executes an `LD B, B` opcode, followed by an infinite JR loop (JR pointing to itself)

A failing test:

- writes the byte `0x42` to the registers B/C/D/E/H/L
- executes an `LD B, B` opcode
- sends the byte `0x42` 6 times using the serial port
- executes an `LD B, B` opcode, followed by an infinite JR loop (JR pointing to itself)

If you don't have a full Game boy system, pass/fail reporting can be sped up by
making sure LY (`0xff44`) and SC (`0xff02`) both return 0xff when read. This will
bypass some unnecessary drawing code and waiting for serial transfer to finish.

## Hardware testing

There's tons of documentation and tons of emulators in the internet, but in the
end I only trust real hardware. I follow a fairly "scientific" process when
developing emulation for a feature:

1. Think of different ways how it might behave on real hardware
2. Make a hypothesis based on the most probable behaviour
3. Write a test ROM for such behaviour
4. Run the test ROM on real hardware. If the test ROM made an invalid
   hypothesis, go back to 1.
5. Success!

All test ROMs are manually run with these devices:

| Device              | Model    | Mainboard    | SoC              | Detailed information                                                            |
| ------------------- | -------- | ------------ | ---------------- | ---------------                                                                 |
| Game Boy            | DMG-01   | DMG-CPU-01   | DMG-CPU          | [G01176542](https://gbhwdb.gekkio.fi/consoles/dmg/G01176542.html)               |
| Game Boy            | DMG-01   | DMG-CPU-02   | DMG-CPU A        | [G02487032](https://gbhwdb.gekkio.fi/consoles/dmg/G02487032.html)               |
| Game Boy            | DMG-01   | DMG-CPU-04   | DMG-CPU B        | [G10888299](https://gbhwdb.gekkio.fi/consoles/dmg/G10888299.html)               |
| Game Boy            | DMG-01   | DMG-CPU-06   | DMG-CPU C        | [GM6058180](https://gbhwdb.gekkio.fi/consoles/dmg/GM6058180.html)               |
| Super Game Boy      | SHVC-027 | SGB-R-10     | SGB-CPU-01       | [SGB Unit #2 \[gekkio\]](https://gbhwdb.gekkio.fi/consoles/sgb/gekkio-2.html)   |
| Game Boy Pocket     | MGB-001  | MGB-CPU-01   | CPU MGB          | [M10280516](https://gbhwdb.gekkio.fi/consoles/mgb/M10280516.html)               |
| Super Game Boy 2    | SHVC-042 | SHVC-SGB2-01 | CPU SGB2         | [SGB2 Unit #1 \[gekkio\]](https://gbhwdb.gekkio.fi/consoles/sgb2/gekkio-1.html) |
| Game Boy Color      | CGB-001  | CGB-CPU-01   | CPU CGB          | [C10203977](https://gbhwdb.gekkio.fi/consoles/cgb/C10203977.html)               |
| Game Boy Color      | CGB-001  | CGB-CPU-01   | CPU CGB A        | [C10400331](https://gbhwdb.gekkio.fi/consoles/cgb/C10400331.html)               |
| Game Boy Color      | CGB-001  | CGB-CPU-02   | CPU CGB B        | [C11778414](https://gbhwdb.gekkio.fi/consoles/cgb/C11778414.html)               |
| Game Boy Color      | CGB-001  | CGB-CPU-03   | CPU CGB C        | [CGB Unit #1 \[gekkio\]](https://gbhwdb.gekkio.fi/consoles/cgb/gekkio-1.html)   |
| Game Boy Color      | CGB-001  | CGB-CPU-05   | CPU CGB D        | [CH20983903](https://gbhwdb.gekkio.fi/consoles/cgb/CH20983903.html)             |
| Game Boy Color      | CGB-001  | CGB-CPU-06   | CPU CGB E        | [CH24224683](https://gbhwdb.gekkio.fi/consoles/cgb/CH24224683.html)             |
| Game Boy Advance    | AGB-001  | AGB-CPU-01   | CPU AGB          | [AH10045235](https://gbhwdb.gekkio.fi/consoles/agb/AH10045235.html)             |
| Game Boy Advance    | AGB-001  | AGB-CPU-10   | CPU AGB A        | [AH12465671](https://gbhwdb.gekkio.fi/consoles/agb/AH12465671.html)             |
| Game Boy Player     | DOL-017  | DOL-GBS-20   | CPU AGB A E      | [GBS Unit #3 \[gekkio\]](https://gbhwdb.gekkio.fi/consoles/gbs/gekkio-3.html) |
| Game Boy Advance SP | AGS-001  | C/AGS-CPU-01 | CPU AGB B        | [XJH10027945](https://gbhwdb.gekkio.fi/consoles/ags/XJH10027945.html)           |
| Game Boy Advance SP | AGS-001  | C/AGS-CPU-21 | CPU AGB B E      | [XEH17807928](https://gbhwdb.gekkio.fi/consoles/ags/XEH17807928.html)           |

### Additional devices

I also have access to more devices with different mainboard revisions, but I
think the CPU revision is all that matters if we study the deterministic
behaviour and not analog characteristics (e.g. audio filtering), or behaviour
that is known to be non-deterministic. Even if audio sounded different between
two units with the same CPU revision but different mainboard revisions, I'd
expect the difference to be caused by individual device variation or different
revisions of support chips (e.g. RAM/AMP/REG).

The main "test fleet" is already very big, so I only test on these devices if
there's evidence of behaviour that depends on mainboard revision or individual
units.

| Device              | Model    | Mainboard    | SoC              | Detailed information                                                          |
| ------------------- | -------- | ------------ | -----------      | ----                                                                          |
| Game Boy            | DMG-01   | DMG-CPU-01   | DMG-CPU          | [G01036814](https://gbhwdb.gekkio.fi/consoles/dmg/G01036814.html)             |
| Game Boy            | DMG-01   | DMG-CPU-03   | DMG-CPU B        | [G06551776](https://gbhwdb.gekkio.fi/consoles/dmg/G06551776.html)             |
| Game Boy            | DMG-01   | DMG-CPU-05   | DMG-CPU B        | [G13289095](https://gbhwdb.gekkio.fi/consoles/dmg/G13289095.html)             |
| Game Boy            | DMG-01   | DMG-CPU-06   | DMG-CPU B        |                                                                               |
| Game Boy            | DMG-01   | DMG-CPU-07   | DMG-CPU B (blob) | [G38953646](https://gbhwdb.gekkio.fi/consoles/dmg/G38953646.html)             |
| Game Boy            | DMG-01   | DMG-CPU-08   | DMG-CPU C (blob) |                                                                               |
| Super Game Boy      | SNSP-027 | SGB-R-10     | SGB-CPU-01       | [SGB Unit #7 \[gekkio\]](https://gbhwdb.gekkio.fi/consoles/sgb/gekkio-7.html) |
| Game Boy Pocket     | MGB-001  | MGB-ECPU-01  | CPU MGB          | [MH12573718](https://gbhwdb.gekkio.fi/consoles/mgb/MH12573718.html)           |
| Game Boy Pocket     | MGB-001  | MGB-LCPU-01  | CPU MGB          | [M12827347](https://gbhwdb.gekkio.fi/consoles/mgb/M12827347.html)             |
| Game Boy Pocket     | MGB-001  | MGB-LCPU-02  | CPU MGB          | [MH20284468](https://gbhwdb.gekkio.fi/consoles/mgb/MH20284468.html)           |
| Game Boy Light      | MGB-101  | MGL-CPU-01   | CPU MGB          | [L10610653](https://gbhwdb.gekkio.fi/consoles/mgl/L10610653.html)             |
| Game Boy Color      | CGB-001  | CGB-CPU-04   | CPU CGB D        | [C19220030](https://gbhwdb.gekkio.fi/consoles/cgb/C19220030.html)             |
| Game Boy Advance    | AGB-001  | AGB-CPU-02   | CPU AGB          | [AJ12569062](https://gbhwdb.gekkio.fi/consoles/agb/AJ12569065.html)           |
| Game Boy Advance    | AGB-001  | AGB-CPU-03   | CPU AGB A        | [AJ14804298](https://gbhwdb.gekkio.fi/consoles/agb/AJ14804298.html)           |
| Game Boy Advance    | AGB-001  | AGB-CPU-04   | CPU AGB A        | [AJ15529163](https://gbhwdb.gekkio.fi/consoles/agb/AJ15529163.html)           |
| Game Boy Player     | DOL-017  | DOL-GBS-10   | CPU AGB A        | [GBS Unit #1 \[gekkio\]](https://gbhwdb.gekkio.fi/consoles/gbs/gekkio-1.html) |
| Game Boy Advance SP | AGS-001  | C/AGS-CPU-10 | CPU AGB B        | [XEH12776954](https://gbhwdb.gekkio.fi/consoles/ags/XEH12776954.html)         |
| Game Boy Advance SP | AGS-001  | C/AGS-CPU-11 | CPU AGB B        | [XJF10485171](https://gbhwdb.gekkio.fi/consoles/ags/XJF10485171.html)         |
| Game Boy Advance SP | AGS-001  | C/AGS-CPU-30 | CPU AGB B E      | [XEH20137204](https://gbhwdb.gekkio.fi/consoles/ags/XEH20137204.html)         |
| Game Boy Advance SP | AGS-101  | C/AGT-CPU-01 | CPU AGB B E      | [XU72764025-1](https://gbhwdb.gekkio.fi/consoles/ags/XU72764025-1.html)       |

I'm still looking for the following mainboards, but these are probably not
required for reverse engineering:

* SGB-R-01
* SGB-N-01
* SGB-N-10
* C/AGS-CPU-20
* DOL-GBS-01

**For now, the focus is on DMG/MGB/SGB/SGB2, so not all tests pass on
CGB/AGB/AGS or emulators emulating those devices.**

# License and copyright

Mooneye Test Suite is licensed under MIT.
Copyright (C) 2014-2022 Joonas Javanainen <joonas.javanainen@gmail.com>
