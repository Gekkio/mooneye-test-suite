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

.ifdef FORCE_SECTIONS
.section "wait_ly_with_timeout" FORCE
.else
.section "wait_ly_with_timeout"
.endif
; Inputs:
;   A expected LY value
; Outputs:
;   cf 0 if LY value was seen, 1 if the wait timed out
; Preserved: E, HL
wait_ly_with_timeout:
  ld d, a
  ld bc, $0000
- ldh a, (<LY)
  cp d
  ret z ; cf=0 if the right LY value was seen
  inc bc
  ld a, b
  or c
  jr nz, -

  @timeout:
    scf
    ret
.ends
