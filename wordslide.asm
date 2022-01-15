.org $080D
.segment "STARTUP"
.segment "INIT"
.segment "ONCE"
.segment "CODE"

   jmp start

.include "cbm_kernal.inc"

screen_text:
.byte $92,$93,$8E,$05,$0D," word slide!",$0D,$0D
.byte " ",$B0,$C3,$B2,$C3,$B2,$C3,$B2,$C3,$B2,$C3,$AE,$0D
.byte " ",$C2," ",$C2," ",$C2," ",$C2," ",$C2," ",$C2,$0D
.byte " ",$AB,$C3,$DB,$C3,$DB,$C3,$DB,$C3,$DB,$C3,$B3,$0D
.byte " ",$C2," ",$C2," ",$C2," ",$C2," ",$C2," ",$C2,$0D
.byte " ",$AB,$C3,$DB,$C3,$DB,$C3,$DB,$C3,$DB,$C3,$B3,$0D
.byte " ",$C2," ",$C2," ",$C2," ",$C2," ",$C2," ",$C2,$0D
.byte " ",$AB,$C3,$DB,$C3,$DB,$C3,$DB,$C3,$DB,$C3,$B3,$0D
.byte " ",$C2," ",$C2," ",$C2," ",$C2," ",$C2," ",$C2,$0D
.byte " ",$AB,$C3,$DB,$C3,$DB,$C3,$DB,$C3,$DB,$C3,$B3,$0D
.byte " ",$C2," ",$C2," ",$C2," ",$C2," ",$C2," ",$C2,$0D
.byte " ",$AB,$C3,$DB,$C3,$DB,$C3,$DB,$C3,$DB,$C3,$B3,$0D
.byte " ",$C2," ",$C2," ",$C2," ",$C2," ",$C2," ",$C2,$0D
.byte " ",$AD,$C3,$B1,$C3,$B1,$C3,$B1,$C3,$B1,$C3,$BD,$0D,$0D,$0D,$0D
.byte " ",$B0,$C3,$C3,$C3,$C3,$C3,$C3,$C3,$C3,$C3,$C3,$AE,$0D
.byte " ",$C2,"qwertyuiop",$C2,$0D
.byte " ",$C2,"asdfghjkl ",$C2,$0D
.byte " ",$C2," zxcvbnm  ",$C2,$0D
.byte " ",$AD,$C3,$C3,$C3,$C3,$C3,$C3,$C3,$C3,$C3,$C3,$BD,0

start:
   ; set background to black
.if .def(__CX16__)
   lda #$90    ; foreground = black
   jsr CHROUT
   lda #$01    ; swap background/foreground
   jsr CHROUT
   lda #64     ; half-resolution
   sta $9F2A   ; VERA H-Scale
   sta $9F2B   ; VERA V-Scale
.elseif .def(__C64__)
   lda #0      ; black
   sta $D021   ; background color VIC-II register
.elseif .def(__VIC20__)
   lda #0      ; black background and border
   sta $900F   ; background/border color VIC register
.endif
   ; display initial screen text
   ldx #0
@init_loop:
   lda screen_text,x
   jsr CHROUT
   inx
   bne @init_loop       ; keep looping until X = 0
@init_page2:
   lda screen_text+$100,x
   beq @init_loop_done  ; break out of loop at null terminator
   jsr CHROUT
   inx
   jmp @init_page2
@init_loop_done:
   rts
