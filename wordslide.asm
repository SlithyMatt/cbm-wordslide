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
.byte " guess the word ",$0D
.byte "                ",$0D
.byte " ",$B0,$C3,$C3,$C3,$C3,$C3,$C3,$C3,$C3,$C3,$C3,$AE,$0D
.byte " ",$C2,"qwertyuiop",$C2,$0D
.byte " ",$C2,"asdfghjkl ",$C2,$0D
.byte " ",$C2," zxcvbnm  ",$C2,$0D
.byte " ",$AD,$C3,$C3,$C3,$C3,$C3,$C3,$C3,$C3,$C3,$C3,$BD,0

answer:
.res 5

letter_status:
.res 26

letter_coords:
.byte 21,2  ; A
.byte 22,7  ; B
.byte 22,5  ; C
.byte 21,4  ; D
.byte 20,4  ; E
.byte 21,5  ; F
.byte 21,6  ; G
.byte 21,7  ; H
.byte 20,9  ; I
.byte 21,8  ; J
.byte 21,9  ; K
.byte 21,10 ; L
.byte 22,9  ; M
.byte 22,8  ; N
.byte 20,10 ; O
.byte 20,11 ; P
.byte 20,2  ; Q
.byte 20,5  ; R
.byte 21,3  ; S
.byte 20,6  ; T
.byte 20,8  ; U
.byte 22,6  ; V
.byte 20,3  ; W
.byte 22,4  ; X
.byte 20,7  ; Y
.byte 22,3  ; Z

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
.res 3

remainder:
guess_index:
.res 1

correct:
.res 1

random_seed:
.res 2

guess:
.res 5

guess_colors:
.res 5

not_word:
.byte "not a word    ",0

try_again:
.byte "try again     ",0

you_win:
.byte "you win!      ",$0D," play again? y/n",0

you_lose:
.byte "the word was ",$0D," play again? y/n",0

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
@start_game:
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
   tax
@init_letter_loop:
   sta letter_status,x
   inx
   cpx #26
   bne @init_letter_loop
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
   ldx #<you_lose
   ldy #>you_lose
   jsr print_message
   ldx #17
   ldy #14
   clc
   jsr PLOT
   ldx #0
@reveal_loop:
   lda answer,x
   jsr CHROUT
   inx
   cpx #5
   bne @reveal_loop
   jmp @play_again
@win:
   ldx #<you_win
   ldy #>you_win
   jsr print_message
@play_again:
   jsr GETIN
   cmp #$4E ; N
   beq @quit
   cmp #$59 ; Y
   bne @play_again
   jmp @start_game
@quit:
   ldx #24
   ldy #0
   clc
   jsr PLOT
   rts

print_message: ; X/Y - address of null-terminated string
   stx ZP_PTR
   sty ZP_PTR+1
   ldx #17
   ldy #1
   clc
   jsr PLOT
   ldy #0
@loop:
   lda (ZP_PTR),y
   beq @return
   jsr CHROUT
   iny
   jmp @loop
@return:
   rts

play_round:
   ldx #0
   txa
@clear_color_loop:
   sta guess_colors,x
   inx
   cpx #5
   bne @clear_color_loop
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
   beq @wait_enter
   ; move cursor forward
   lda #$1D
   jsr CHROUT
   jmp @letter_loop
@wait_enter:
   txa
   pha
   jsr GETIN
   tay
   pla
   tax
   tya
   cmp #$0D
   beq @check
   cmp #$14
   bne @wait_enter
   ; backspace, so place cursor back in last box
   lda #$9D
   jsr CHROUT
   dex
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
   ; multiply index by 52 (32 + 16 + 4)
   asl
   asl
   tax            ; X = i * 4
   asl
   asl
   sta ZP_PTR
   rol ZP_PTR+1   ; ZP_PTR = i * 16
   txa
   adc ZP_PTR
   sta scratch
   lda ZP_PTR+1
   adc #0
   sta scratch+1  ; scratch = i * 20
   asl ZP_PTR
   rol ZP_PTR+1   ; ZP_PTR = i * 32
   lda scratch
   adc ZP_PTR
   sta ZP_PTR
   lda scratch+1
   adc ZP_PTR+1
   sta ZP_PTR+1   ; ZP_PTR = i * 52
   lda guess+1
   sec
   sbc #$41       ; get second letter index (j)
   asl
   adc ZP_PTR
   sta ZP_PTR
   lda #0
   adc ZP_PTR+1
   sta ZP_PTR+1   ; ZP_PTR = i*52 + j*2
   lda #<WORD_TABLE
   adc ZP_PTR
   sta ZP_PTR
   lda #>WORD_TABLE
   adc ZP_PTR+1
   sta ZP_PTR+1   ; ZP_PTR = address of first ij--- word
   ldy #0
   lda (ZP_PTR),y
   bne @start_search
   iny
   lda (ZP_PTR),y
   beq @not_found
@start_search:
   ldy #0
   lda (ZP_PTR),y
   sta scratch
   iny
   lda (ZP_PTR),y
   sta ZP_PTR+1
   lda scratch
   sta ZP_PTR
@compare_word:
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
   bne @compare_letter
   jmp @found
@compare_letter:
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
   jmp @compare_word
@not_found:
   ldx #<not_word
   ldy #>not_word
   jsr print_message
@reset_cursor:
   lda guess_index
   asl
   clc
   adc #4
   tax
   ldy #4
   clc
   jsr PLOT
.repeat 3
   lda #$20
   jsr CHROUT
   lda #$1D
   jsr CHROUT
.endrepeat
   lda #$20
   jsr CHROUT
   lda #$9D
.repeat 9      ; move cursor back 9 positions
   jsr CHROUT
.endrepeat
   jmp play_round
@found:
   ldy #0
   sty correct
@compare_loop:
   jsr compare_letter
   iny
   cpy #5
   bne @compare_loop
   lda correct
   cmp #5
   beq @update_keyboard
   ldx #<try_again
   ldy #>try_again
   jsr print_message
   jsr correct_yellows
@update_keyboard:
   ldx #0
@keyboard_loop:
   lda letter_status,x
   beq @next_key
   jsr update_key
@next_key:
   inx
   cpx #26
   bne @keyboard_loop
   ; return to white text
   lda #$05
   jsr CHROUT
   rts

update_key: ; X = key index
   stx scratch
   txa
   asl
   tax
   lda letter_coords,x
   inx
   ldy letter_coords,x
   tax
   jsr PLOT
   ldx scratch
   lda letter_status,x
   and #$04
   bne @clear
   lda letter_status,x
   and #$02
   bne @green
   ; make letter yellow
   lda #$9E
   jsr CHROUT
   jmp @print_letter
@green:
   lda #$1E
   jsr CHROUT
@print_letter:
   txa
   clc
   adc #$41
   jmp @print
@clear:
   lda #$20
@print:
   jsr CHROUT
   rts

compare_letter:   ; Y = letter index
   lda guess,y
   cmp answer,y
   beq @green
   ; check rest of answer for this letter
   ldx #0
@check_loop:
   cmp answer,x
   beq @yellow
   inx
   cpx #5
   bne @check_loop
   ; letter not found
   lda guess,y
   sec
   sbc #$41
   tax
   lda #$04
   sta letter_status,x
   jmp @return
@green:
   ; letter in correct position
   inc correct
   sec
   sbc #$41
   tax
   lda #$02
   sta letter_status,x
   lda #5
   jsr reverse_letter
   jmp @return
@yellow:
   ; letter found, but wrong position
   lda guess,y
   sec
   sbc #$41
   tax
   lda letter_status,x
   ora #$01
   sta letter_status,x
   lda #7
   jsr reverse_letter
@return:
   rts

reverse_letter:   ; A = color, Y = letter index
   tax         ; X = color
   sta guess_colors,y
.if .def(__CX16__)
   stz $9F25   ; data port 0
   tya
   asl
   asl
   adc #4
   sta $9F20   ; low byte VRAM address = X coordinate (letter index*2 + 2)
   lda guess_index
   asl
   adc #4
   sta $9F21   ; high byte VRAM address = Y coordinate (guess index*2 + 4)
   stz $9F22   ; bank = 0, stride = 0
   lda $9F23   ; get screen code
   ora #$80    ; reverse it
   sta $9F23
   inc $9F20   ; go to color
   stx $9F23   ; set foreground
.elseif .def(__C64__)
   lda #0
   sta ZP_PTR+1
   lda guess_index
   asl
   adc #4         ; A = row
   asl
   asl
   asl
   sta scratch    ; row * 8
   asl
   asl
   sta ZP_PTR
   rol ZP_PTR+1  ; ZP_PTR = row * 32
   adc scratch
   sta ZP_PTR
   lda ZP_PTR+1
   adc #$04
   sta ZP_PTR+1   ; ZP_PTR = start of row in screen RAM
   tya
   asl
   adc #2
   adc ZP_PTR
   sta ZP_PTR
   lda ZP_PTR+1
   adc #0
   sta ZP_PTR+1   ; ZP_PTR = letter position in screen RAM
   stx scratch    ; scratch = color
   ldx #0
   lda (ZP_PTR,x) ; get screen code
   ora #$80       ; reverse it
   sta (ZP_PTR,x) ; update code
   lda ZP_PTR+1
   adc #$D4
   sta ZP_PTR+1   ; ZP_PTR = letter position in color RAM
   lda scratch
   sta (ZP_PTR,x) ; set color
.elseif .def(__VIC20__)
   ; TBD
.endif
   lda guess_colors,y
   rts

correct_yellows:
   ldx #0
@yellow_loop:
   lda guess_colors,x
   cmp #7
   beq @check_yellow
@next_yellow:
   inx
   cpx #5
   bne @yellow_loop
   jmp @return
@check_yellow:
   ldy #0
   sty scratch    ; answer count of letter
   sty scratch+1  ; green count of letter
   sty scratch+2  ; yellow count of letter
@count_loop:
   lda answer,y
   cmp guess,x
   bne @check_yellow_guess
   inc scratch          ; Y = index where letter is found
   lda guess_colors,y
   cmp #5
   bne @check_yellow_guess
   inc scratch+1        ; correct letter guessed for this index
   jmp @next_count
@check_yellow_guess:
   lda guess_colors,y
   cmp #7
   bne @next_count
   lda guess,x
   cmp guess,y
   bne @next_count
   inc scratch+2        ; matching letter marked yellow
@next_count:
   iny
   cpy #5
   bne @count_loop
   lda scratch
   sec
   sbc scratch+1        ; A = number of unguessed/misplaced letters
   beq @clear_yellow
   cmp scratch+2
   bmi @clear_yellow
   jmp @next_yellow
@clear_yellow:
   lda #0
   sta guess_colors,x
   txa
   pha
   asl
   adc #2
   tay
   lda guess_index
   asl
   adc #4
   tax
   jsr PLOT
   pla
   tax
   lda guess,x
   jsr CHROUT
   jmp @next_yellow
@return:
   rts
