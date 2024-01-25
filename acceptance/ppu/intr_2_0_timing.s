; Copyright (C) 2014-2022 Joonas Javanainen <joonas.javanainen@gmail.com>
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

; Tests how long does it take to get from STAT mode=2 interrupt to STAT mode=0 interrupt
; No sprites, scroll or window.

; Verified results:
;   pass: DMG, MGB, SGB, SGB2, CGB, AGB, AGS
;   fail: -

.include "common.s"

.macro clear_interrupts
  xor a
  ldh (<IF), a
.endm

.macro wait_mode ARGS mode
- ldh a, (<STAT)
  and $03
  cp mode
  jr nz, -
.endm

  ld sp, DEFAULT_SP

  wait_vblank
  ld hl, STAT
  ld a, INTR_STAT
  ldh (<IE), a

.macro test_iter ARGS delay
  call setup_and_wait_mode2
  nops delay
  call setup_and_wait_mode0
.endm

  test_iter 4
  ld d, b
  test_iter 3
  ld e, b
  setup_assertions
  assert_d $07
  assert_e $08
  quit_check_asserts

setup_and_wait_mode2:
  wait_ly $42
  wait_mode $00
  wait_mode $03
  ld a, %00100000
  ldh (<STAT), a
  clear_interrupts
  ei

  halt
  nop
  jp fail_halt

setup_and_wait_mode0:
  ld a, %00001000
  ldh (<STAT), a
  clear_interrupts
  ei
  xor a
  ld b,a
- inc b
  jr -

fail_halt:
  quit_failure_string "FAIL: HALT"

.org INTR_VEC_STAT
  add sp,+2
  ret
