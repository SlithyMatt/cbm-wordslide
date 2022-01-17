.org $080D
.segment "STARTUP"
.segment "INIT"
.segment "ONCE"
.segment "CODE"

   jmp start

.include "cbm_kernal.inc"

load_text:
.byte "loading...",0

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
.byte " ",$AD,$C3,$B1,$C3,$B1,$C3,$B1,$C3,$B1,$C3,$BD,$0D,$0D
.byte " guess the word ",$0D,$0D
.byte " ",$B0,$C3,$C3,$C3,$C3,$C3,$C3,$C3,$C3,$C3,$C3,$AE,$0D
.byte " ",$C2,"qwertyuiop",$C2,$0D
.byte " ",$C2,"asdfghjkl ",$C2,$0D
.byte " ",$C2," zxcvbnm  ",$C2,$0D
.byte " ",$AD,$C3,$C3,$C3,$C3,$C3,$C3,$C3,$C3,$C3,$C3,$BD,0

answer:
.res 5

letter_status:
.res 26

filename:
.byte "words.bin"
end_filename:
FILENAME_LENGTH = end_filename - filename

WORD_TABLE = $6000

LUT_SIZE = 26*26*2

WORD_ZERO = WORD_TABLE + LUT_SIZE

word_table_size:
.res 2

scratch:
.res 2

remainder:
guess_index:
.res 1

correct:
.res 1

random_seed:
.res 2

guess:
.res 5

not_word:
.byte "not a word    ",0

try_again:
.byte "try again     ",0

.if .def(__CX16__)
ZP_PTR = $30
.elseif .def(__C64__)
ZP_PTR = $FB
.elseif .def(__VIC20__)
ZP_PTR = $8B
.endif

start:
   ldx #0
@load_loop:
   lda load_text,x
   beq @load
   jsr CHROUT
   inx
   jmp @load_loop
@load:
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
   ; seed random number generator
.if .def (__CX16__)
   jsr $FECF ; entropy_get
   stx random_seed
   sty random_seed+1
   eor random_seed
   sta random_seed
   txa
   eor random_seed+1
   sta random_seed+1
.elseif .def(__C64__)
   ; use SID
   lda #$FF  ; maximum frequency value
   sta $D40E ; voice 3 frequency low byte
   sta $D40F ; voice 3 frequency high byte
   lda #$80  ; noise waveform, gate bit off
   sta $D412 ; voice 3 control register
.elseif .def(__VIC20__)
   ; TBD
.endif
   jsr RDTIM
   pha
   eor random_seed
   stx random_seed
   eor random_seed
   sta random_seed
   pla
   eor random_seed+1
   sty random_seed+1
   eor random_seed+1
   sta random_seed+1
   ; load word table from disk
   lda #1
   ldx #8
   ldy #0
   jsr SETLFS
   lda #FILENAME_LENGTH
   ldx #<filename
   ldy #>filename
   jsr SETNAM
   lda #0
   ldx #<WORD_TABLE
   ldy #>WORD_TABLE
   jsr LOAD
   sec
   txa
   sbc #<WORD_TABLE
   sta word_table_size
   tya
   sbc #>WORD_TABLE
   sta word_table_size+1
   lda word_table_size
   sbc #<LUT_SIZE
   sta word_table_size
   lda word_table_size+1
   sbc #>LUT_SIZE
   sta word_table_size+1
   ; divide by 5 to get word count
   lda #0
   sta remainder
   ldx #16
@div5_loop:
   asl word_table_size
   rol word_table_size+1
   rol remainder
   lda remainder
   sec
   sbc #5
   bcc @next_bit
   sta remainder
   inc word_table_size
@next_bit:
   dex
   bne @div5_loop
   ; display initial screen text
   ldx #0
@init_loop:
   lda screen_text,x
   jsr CHROUT
   inx
   bne @init_loop       ; keep looping until X = 0
@init_page2:
   lda screen_text+$100,x
   beq @select_word     ; break out of loop at null terminator
   jsr CHROUT
   inx
   jmp @init_page2
@select_word:
   ; randomly select a word
.if .def (__CX16__)
   jsr $FECF ; entropy_get
   pha
   eor random_seed
   stx random_seed
   eor random_seed
   sta random_seed
   pla
   eor random_seed+1
   sty random_seed+1
   eor random_seed+1
   sta random_seed+1
.elseif .def(__C64__)
   ; use SID
   lda $D41B
   pha
   eor random_seed
   sta random_seed
   pla
   eor random_seed+1
   sta random_seed+1
.elseif .def(__VIC20__)
   ; TBD
.endif
   lda random_seed+1
   and #$3F                ; clear top 2 bits to help keep in range
   sta ZP_PTR+1
   cmp word_table_size+1
   bpl @select_word        ; too high, regenerate
   bne @word_found
   lda random_seed
   cmp word_table_size
   bpl @select_word        ; too high, regenerate
@word_found:
   lda random_seed
   sta ZP_PTR              ; ZP_PTR = word index
   asl
   sta scratch
   lda ZP_PTR+1
   rol
   sta scratch+1
   asl scratch
   rol scratch+1           ; scratch = word index * 4
   lda scratch
   clc
   adc ZP_PTR
   sta ZP_PTR
   lda scratch+1
   adc ZP_PTR+1
   sta ZP_PTR+1            ; ZP_PTR = word index * 5
   lda ZP_PTR
   adc #<WORD_ZERO
   sta ZP_PTR
   lda ZP_PTR+1
   adc #>WORD_ZERO
   sta ZP_PTR+1            ; ZP_PTR = word address
   ; copy selected word to answer string variable
   ldy #0
@copy_loop:
   lda (ZP_PTR),y
   sta answer,y
   iny
   cpy #5
   bne @copy_loop
   ; initialize round
   lda #0
   sta guess_index
@game_loop:
   jsr play_round
   lda correct
   cmp #5
   beq @win
   inc guess_index
   lda guess_index
   cmp #6
   bne @game_loop
   ; lost the game

   jmp @play_again
@win:

@play_again:

   rts

play_round:
   ; position cursor in first guess letter
   lda guess_index
   asl
   clc
   adc #4
   tax
   ldy #2
   clc
   jsr PLOT
   ldx #0
@letter_loop:
   ; print cursor
   lda #$F9
   jsr CHROUT
   ; move cursor back
   lda #$9D
   jsr CHROUT
   txa
   pha
@wait_input:
   jsr GETIN
   cmp #$14
   beq @backspace
   cmp #$41
   bmi @wait_input   ; ignore < A
   cmp #$5B
   bpl @wait_input   ; ignore > Z
   tay
   jsr CHROUT
   pla
   tax
   tya
   sta guess,x
   inx
   cpx #5
   beq @check
   ; move cursor forward
   lda #$1D
   jsr CHROUT
   jmp @letter_loop
@backspace:
   pla
   tax
   beq @letter_loop
   ; print space
   lda #$20
   jsr CHROUT
   ; move cursor back three positions
   lda #$9D
   jsr CHROUT
   jsr CHROUT
   jsr CHROUT
   dex
   jmp @letter_loop
@check:
   ; first check to see if in word list
   lda guess
   sec
   sbc #$41       ; get first letter index (i) (e.g. A = 0)
   ldy #0
   sty ZP_PTR+1
   ; multiply index by 26 (16 + 8 + 2)
   asl
   tax            ; X = i * 2
   asl
   asl
   sta ZP_PTR     ; ZP_PTR = i * 8
   txa
   adc ZP_PTR
   tax            ; X = i * 10
   asl ZP_PTR
   rol ZP_PTR+1   ; ZP_PTR = i * 16
   txa
   adc ZP_PTR
   sta ZP_PTR
   lda #0
   adc ZP_PTR+1
   sta ZP_PTR+1   ; ZP_PTR = i * 26
   lda guess+1
   sec
   sbc #$41       ; get second letter index (j)
   clc
   adc ZP_PTR
   sta ZP_PTR
   lda #0
   adc ZP_PTR+1
   sta ZP_PTR+1   ; ZP_PTR = i *26 + j
   lda #<WORD_TABLE
   adc ZP_PTR
   sta ZP_PTR
   lda #>WORD_TABLE
   adc ZP_PTR+1
   sta ZP_PTR+1   ; ZP_PTR = address of first ij--- word
   bne @start_search
   lda ZP_PTR
   beq @not_found
@start_search:
   ldy #0
   lda (ZP_PTR),y
   cmp guess
   bne @not_found
   iny
   lda (ZP_PTR),y
   cmp guess+1
   bne @not_found
@next_letter:
   iny
   cpy #5
   beq @found
   lda (ZP_PTR),y
   cmp guess,y
   bne @next_word
   beq @next_letter
@next_word:
   lda ZP_PTR
   clc
   adc #5
   sta ZP_PTR
   lda ZP_PTR+1
   adc #0
   sta ZP_PTR+1
   jmp @start_search
@not_found:
   ldx #16
   ldy #1
   clc
   jsr PLOT
   ldx #0
@nf_loop:
   lda not_word,x
   beq @reset_cursor
   jsr CHROUT
   inx
   jmp @nf_loop
@reset_cursor:
   lda #$9D
.repeat 9      ; move cursor back 9 positions
   jsr CHROUT
.endrepeat
   jmp play_round
@found:
   ldx #0
   ldy #0
@compare_loop:
   jsr compare_letter
   iny
   cpy #5
   bne @compare_loop
   stx correct
   cpx #5
   bne @return
   ldx #0
@try_again_loop:
   lda try_again,x
   beq @return
   jsr CHROUT
   inx
   jmp @try_again_loop
@return:
   rts

compare_letter:   ; X = correct letters so far, Y = letter index
