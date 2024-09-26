; Copyright (C) 2014-2024 Joonas Javanainen <joonas.javanainen@gmail.com>
;
; Permission is hereby granted, free of charge, to any person obtaining a copy
; of this software and associated documentation files (the "Software"), to deal
; in the Software without restriction, including without limitation the rights
; to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
; copies of the Software, and to permit persons to whom the Software is
; furnished to do so, subject to the following conditions:
;
; The above copyright notice and this permission notice shall be included in
; all copies or substantial portions of the Software.
;
; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
; IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
; FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
; AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
; LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
; OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
; SOFTWARE.

; Boot ROM dump utility intended to be used with some kind of external glitch
; mechanism to prevent the boot ROM from disabling itself.

; Copies $0000-$08FF to cartridge RAM and serial out, with $0100-$0200 already
; set to $00 for convenience.
; If boot ROM has been disabled (= glitch has failed):
;   - plays one low beep and shows a sad face
; If boot ROM has not been disabled (= glitch has succeeded):
;   - plays two high beeps and shows a happy face

; The face might not always appear if the glitch has upset the PPU too much, but
; the audio is a quite good indicator of success/failure. However, if you get
; *very* unlucky, the CPU might jump directly to the end where the audio is played
; but the data is never copied. If this happens, just try again.

.include "hardware.s"
.include "macros.s"

; RAMG address must be outside boot ROM area(s), or any writes to it won't be
; seen by the cartridge
.define RAMG $1000

.rombanks 4
.emptyfill $00

.gbheader
  name "DUMPER"
  licenseecodeold $42
  cartridgetype $03 ; MBC1/RAM/battery
  destinationcode $00
  nintendologo
  romsize
  ramsize 2
  romgbc
.endgb

.bank 0 slot 0
.org $0100
  nop
  jp $7D00

.bank 1 slot 1
.org $3D00
  di

enable_cartridge_ram:
  ld a, $0a
  ld (RAMG), a

copy_to_cartridge_ram:
  ld hl, $a000
  ld de, $0000
  ld bc, $0100
  call memcpy

  ld hl, $a100
  ld bc, $0100
  xor a
  call memset

  ld hl, $a200
  ld de, $0200
  ld bc, $0700
  call memcpy

disable_cartridge_ram:
  xor a
  ld (RAMG), a

compare_data:
  ld hl, $0000
  ld c, $00

- ld a, (hl+)
  dec c
  jr z, finish
  or a
  jr z, -

finish:
  ld sp, $e000
  ld a, c
  or a
  jr z, +
  ld a, %1
+ ldh (<hram.is_success), a

  call disable_ppu_safe
  call reset_screen

  @choose_tilemap:
    ldh a, (<hram.is_success)
    or a
    jr nz, +
    ld de, tilemap_sadface
    jr @setup_tilemap
+   ld de, tilemap_happyface

  @setup_tilemap:
    ld hl, $9880
    ld b, 10
-   push bc
    ld bc, 20
    call memcpy
    pop af
    dec a
    and a
    jr z, @setup_tile
    ld bc, 12
    add hl, bc
    ld b, a
    jr -

  @setup_tile:
    ld a, $ff
    ld hl, $8ff0
    ld bc, 16
    call memset

  enable_ppu

  @setup_audio:
    ld a, $ff
    ldh (<NR50), a
    ldh (<NR51), a
    ldh (<NR52), a
    xor a
    ldh (<NR10), a
    ld a, $80
    ldh (<NR11), a
    ld a, $F8
    ldh (<NR12), a
    xor a
    ldh (<NR13), a

  ldh a, (<hram.is_success)
  or a
  jr nz, success

failure:
  ld a, $C0
  ldh (<NR14), a
  jr end

success:
  ld a, $C7
  ldh (<NR14), a

  ld bc, $3000
- ld a, b
  or c
  jr z, ++
  dec bc
  jr -

++
  ld a, $9F
  ldh (<NR11), a
  ld a, $F8
  ldh (<NR12), a
  ld a, $20
  ldh (<NR13), a
  ld a, $C7
  ldh (<NR14), a

end:
  call copy_to_serial
  halt_execution

copy_to_serial:
  call is_serial_broken
  ret c

  ld de, $0000
  ld bc, $0100
  call serial_memcpy

  ld bc, $0100
- ld a, b
  or c
  jr z, ++
  xor a
  call serial_send_byte
  dec bc
  jr -

++
  ld de, $0200
  ld bc, $0700
  jp serial_memcpy

tilemap_happyface:
  .db $00 $00 $00 $00 $FF $FF $00 $00 $00 $00 $00 $00 $00 $00 $FF $FF $00 $00 $00 $00
  .db $00 $00 $00 $00 $FF $FF $00 $00 $00 $00 $00 $00 $00 $00 $FF $FF $00 $00 $00 $00
  .db $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00
  .db $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00
  .db $00 $00 $00 $FF $FF $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $FF $FF $00 $00 $00
  .db $00 $00 $00 $00 $FF $FF $00 $00 $00 $00 $00 $00 $00 $00 $FF $FF $00 $00 $00 $00
  .db $00 $00 $00 $00 $00 $FF $FF $00 $00 $00 $00 $00 $00 $FF $FF $00 $00 $00 $00 $00
  .db $00 $00 $00 $00 $00 $00 $FF $FF $00 $00 $00 $00 $FF $FF $00 $00 $00 $00 $00 $00
  .db $00 $00 $00 $00 $00 $00 $00 $FF $FF $FF $FF $FF $FF $00 $00 $00 $00 $00 $00 $00
  .db $00 $00 $00 $00 $00 $00 $00 $00 $00 $FF $FF $00 $00 $00 $00 $00 $00 $00 $00 $00

tilemap_sadface:
  .db $00 $00 $00 $00 $FF $FF $00 $00 $00 $00 $00 $00 $00 $00 $FF $FF $00 $00 $00 $00
  .db $00 $00 $00 $00 $FF $FF $00 $00 $00 $00 $00 $00 $00 $00 $FF $FF $00 $00 $00 $00
  .db $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00
  .db $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00
  .db $00 $00 $00 $00 $00 $00 $00 $00 $00 $FF $FF $00 $00 $00 $00 $00 $00 $00 $00 $00
  .db $00 $00 $00 $00 $00 $00 $00 $FF $FF $FF $FF $FF $FF $00 $00 $00 $00 $00 $00 $00
  .db $00 $00 $00 $00 $00 $00 $FF $FF $00 $00 $00 $00 $FF $FF $00 $00 $00 $00 $00 $00
  .db $00 $00 $00 $00 $00 $FF $FF $00 $00 $00 $00 $00 $00 $FF $FF $00 $00 $00 $00 $00
  .db $00 $00 $00 $00 $FF $FF $00 $00 $00 $00 $00 $00 $00 $00 $FF $FF $00 $00 $00 $00
  .db $00 $00 $00 $FF $FF $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $FF $FF $00 $00 $00

.define CART_CGB
.define FORCE_SECTIONS
.include "lib/clear_vram.s"
.include "lib/disable_ppu_safe.s"
.include "lib/is_serial_broken.s"
.include "lib/memcpy.s"
.include "lib/memset.s"
.include "lib/reset_screen.s"
.include "lib/serial_memcpy.s"
.include "lib/serial_send_byte.s"
.include "lib/wait_ly_with_timeout.s"

.org $4000 - 3
  jp $7D00

.ramsection "HRAM" slot HRAM_SLOT
  hram.is_success db
.ends
