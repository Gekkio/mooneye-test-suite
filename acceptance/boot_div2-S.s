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

; Tests the value and relative phase of DIV after boot
; Bootrom duration on real SGB/SGB2 depends on the header bytes, including the
; global checksum, which in turn depends on every byte in the ROM.
; This tests uses a different checksum bytes than the other one to expose
; hard-coded boot ROM durations.

; Verified results:
;   pass: SGB, SGB2
;   fail: DMG, MGB, CGB, AGB, AGS

; Use a fixed (invalid) checksum to avoid test flakiness
.define CART_NO_GLOBAL_CHECKSUM

.include "common.s"

  nops 37
  ; This read should happen immediately after DIV has incremented
  ldh a, (<DIV)
  push af

  ; With 57 NOPs here, the next read should happen immediately after the next
  ; increment. So, the relative phase between the read and the increment
  ; remains the same
  nops 57
  ldh a, (<DIV)
  push af

  ; This time we have only 56 NOPs, so the next read should happen immediately
  ; *before* the increment because we're altering the relative phase and
  ; reading one M-cycle earlier.
  nops 56
  ldh a, (<DIV)
  push af

  ; Since we're back to 57 NOPs, the next read should happen once again
  ; immediately *before* the increment. Phase is not changed here, but the change
  ; in the earlier step remains.
  nops 57
  ldh a, (<DIV)
  push af

  ; Same thing here...
  nops 57
  ldh a, (<DIV)
  push af

  ; This time we have 58 NOPs, which alters the phase and the read should
  ; happen after the increment once again.
  nops 58
  ldh a, (<DIV)
  push af

  pop af
  ld l, a
  pop af
  ld h, a
  pop af
  ld e, a
  pop af
  ld d, a
  pop af
  ld c, a
  pop af
  ld b, a
  setup_assertions
  assert_b $d9
  assert_c $da
  assert_d $da
  assert_e $db
  assert_h $dc
  assert_l $de
  quit_check_asserts

.org $014e
  .dw $a796
