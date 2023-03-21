.if .def(__VIC20__)
INITMEM := $FD8D
FRESTOR := $FD52
INITVIA := $FDF9
INITSK  := $E518

INITVCTRS := $E45B
INITBA    := $E3A4
FREMSG    := $E404
READY     := $C474

.segment "LOADADDR"
.export __LOADADDR__: absolute = 1
.addr   *+2

.segment "STARTUP"

; Startup code
.word   reset
.word   $FEA9

; Cart signature
.byte   $41,$30,"CBM"

reset:
   jsr     INITMEM                 ; initialise and test RAM
   jsr     FRESTOR                 ; restore default I/O vectors
   jsr     INITVIA                 ; initialise I/O registers
   jsr     INITSK                  ; initialise hardware

   jsr     INITVCTRS               ; initialise BASIC vector table
   jsr     INITBA                  ; initialise BASIC RAM locations
   jsr     FREMSG                  ; print start up message and initialise memory pointers
   cli                             ; enable interrupts
.else
.org $080D
.segment "STARTUP"
.segment "INIT"
.segment "ONCE"
.segment "CODE"
.endif

   jmp start

.include "cbm_kernal.inc"

; Constants

load_text:
.byte "loading...",0

error_text:
.byte 5, "can't find words.bin!",0

screen_text:
.byte $92,$93,$8E,$05,$0D," word slide!",$0D
.byte " ",$B0,$C0,$B2,$C0,$B2,$C0,$B2,$C0,$B2,$C0,$AE,$0D
.byte " ",$DD," ",$DD," ",$DD," ",$DD," ",$DD," ",$DD,$0D
.byte " ",$AB,$C0,$DB,$C0,$DB,$C0,$DB,$C0,$DB,$C0,$B3,$0D
.byte " ",$DD," ",$DD," ",$DD," ",$DD," ",$DD," ",$DD,$0D
.byte " ",$AB,$C0,$DB,$C0,$DB,$C0,$DB,$C0,$DB,$C0,$B3,$0D
.byte " ",$DD," ",$DD," ",$DD," ",$DD," ",$DD," ",$DD,$0D
.byte " ",$AB,$C0,$DB,$C0,$DB,$C0,$DB,$C0,$DB,$C0,$B3,$0D
.byte " ",$DD," ",$DD," ",$DD," ",$DD," ",$DD," ",$DD,$0D
.byte " ",$AB,$C0,$DB,$C0,$DB,$C0,$DB,$C0,$DB,$C0,$B3,$0D
.byte " ",$DD," ",$DD," ",$DD," ",$DD," ",$DD," ",$DD,$0D
.byte " ",$AB,$C0,$DB,$C0,$DB,$C0,$DB,$C0,$DB,$C0,$B3,$0D
.byte " ",$DD," ",$DD," ",$DD," ",$DD," ",$DD," ",$DD,$0D
.byte " ",$AD,$C0,$B1,$C0,$B1,$C0,$B1,$C0,$B1,$C0,$BD,$0D,$0D
.byte " guess the word ",$0D
.byte "                ",$0D
.byte " ",$B0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$AE,$0D
.byte " ",$DD,"qwertyuiop",$DD,$0D
.byte " ",$DD,"asdfghjkl ",$DD,$0D
.byte " ",$DD," zxcvbnm  ",$DD,$0D
.byte " ",$AD,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$BD,0

letter_coords:
.byte 20,2  ; A
.byte 21,7  ; B
.byte 21,5  ; C
.byte 20,4  ; D
.byte 19,4  ; E
.byte 20,5  ; F
.byte 20,6  ; G
.byte 20,7  ; H
.byte 19,9  ; I
.byte 20,8  ; J
.byte 20,9  ; K
.byte 20,10 ; L
.byte 21,9  ; M
.byte 21,8  ; N
.byte 19,10 ; O
.byte 19,11 ; P
.byte 19,2  ; Q
.byte 19,5  ; R
.byte 20,3  ; S
.byte 19,6  ; T
.byte 19,8  ; U
.byte 21,6  ; V
.byte 19,3  ; W
.byte 21,4  ; X
.byte 19,7  ; Y
.byte 21,3  ; Z

filename:
.byte "words.bin"
end_filename:
FILENAME_LENGTH = end_filename - filename

WORD_TABLE = $2000

LUT_SIZE = 26*26*2

WORD_ZERO = WORD_TABLE + LUT_SIZE

LUT_AB = WORD_TABLE + 2 ; Assuming there are no AA--- words
LUT_EA = WORD_TABLE + (4*26*2)
LUT_HA = WORD_TABLE + (7*26*2)
LUT_LA = WORD_TABLE + (11*26*2)
LUT_PA = WORD_TABLE + (15*26*2)
LUT_TA = WORD_TABLE + (19*26*2)
LUT_WA = WORD_TABLE + (22*26*2)

lut_segments:
.word LUT_AB,LUT_EA,LUT_HA,LUT_LA,LUT_PA,LUT_TA,LUT_WA

not_word:
.byte "not a word    ",0

try_again:
.byte "try again     ",0

you_win:
.byte "you win!      ",$0D," play again? y/n",0

you_lose:
.byte "the word was ",$0D," play again? y/n",0

; Variables
.if .def(__C64__) || .def (__CX16__)
answer:
.res 5

letter_status:
.res 26

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

last_address:
.res 2

.else
; Fixed variable addresses for ROM-based build
answer = $1200
letter_status = answer+5
word_table_size = letter_status+26
scratch = word_table_size+2
remainder = scratch+3
guess_index = remainder
correct = guess_index+1
random_seed = correct+1
guess = random_seed+2
guess_colors = guess+5
last_address = guess_colors+5

ready_prompt:
.byte $92,$93,$8E,$05,$0D,"slithy games presents",$0D
.byte "      word slide!",$0D,$0D
.byte "   hit any key when",$0D
.byte "you are ready to play!",0
.endif

.if .def(__CX16__)
ZP_PTR = $30
ZP_PTR_2 = $32
.elseif .def(__C64__)
ZP_PTR = $FB
ZP_PTR_2 = $FD
.elseif .def(__VIC20__)
; Use tape variables, since we are ROM-based
ZP_PTR = $9E
ZP_PTR_2 = $A7
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
   lda #$0E    ; black background, blue border, non-inverted
   sta $900F   ; background/border color VIC register
   ldx #0
@print_ready:
   lda ready_prompt,x
   beq @wait_anykey
   jsr CHROUT
   inx
   jmp @print_ready
@wait_anykey:
   jsr GETIN
   beq @wait_anykey
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
.endif
   jsr RDTIM
   pha
   eor random_seed
   stx random_seed
   eor random_seed
   sta random_seed
.if .def(__VIC20__)
   ; use first byte for RND seed
   sta $8B
.endif
   pla
   eor random_seed+1
   sty random_seed+1
   eor random_seed+1
   sta random_seed+1
.if .def(__C64__) || .def (__CX16__)
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
   bcc @success
   ldx #0
@error_loop:
   lda error_text,x
   beq @error_quit
   jsr CHROUT
   inx
   jmp @error_loop
@error_quit:
   jmp @quit
@success:
   sec
   stx word_table_size
   sty word_table_size+1
.else
   ; determine VIC-20 word table size
   ; first, search backwards from end of LUT
   lda #<WORD_ZERO
   sta ZP_PTR
   lda #>WORD_ZERO
   sta ZP_PTR+1
   dec ZP_PTR+1  ; Put base address for search 255 bytes before the end
   ldy #255
@lut_end_search:
   lda (ZP_PTR),y
   bne @calc_size_adjust
   dey
   lda (ZP_PTR),y
   bne @calc_size
   dey
   cpy #0
   bne @lut_end_search
@calc_size_adjust:
   dey
@calc_size:
   lda (ZP_PTR),y
   tax
   iny
   lda (ZP_PTR),y
   stx ZP_PTR
   sta ZP_PTR+1
   ldy #0
@word_end_search:
   lda (ZP_PTR),y
   beq @set_size
   dey
   cpy #0
   bne @word_end_search
@set_size:
   tay
   clc
   adc ZP_PTR
   sta word_table_size
   lda ZP_PTR+1
   adc #0
   sta word_table_size+1
.endif
   ; subtract base address + LUT size
   lda word_table_size
   sec
   sbc #<WORD_ZERO
   sta word_table_size
   lda word_table_size+1
   sbc #>WORD_ZERO
   sta word_table_size+1
   ; divide by 2 to get word count
   lsr word_table_size+1
   ror word_table_size
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
   ; call RND()
   jsr $E094
   ; consolidate mantissa to two bytes
   lda $62
   eor $63
   sta random_seed
   lda $64
   eor $65
   sta random_seed+1
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
   asl ZP_PTR
   rol ZP_PTR+1            ; ZP_PTR = word index * 2
   lda ZP_PTR
   adc #<WORD_ZERO
   sta ZP_PTR
   lda ZP_PTR+1
   adc #>WORD_ZERO
   sta ZP_PTR+1            ; ZP_PTR = word address
   ; copy selected word to answer string variable
   ; first, decode last three letters
   ldy #0
   lda (ZP_PTR),y
   lsr
   lsr
   lsr
   ora #$40
   sta answer+2
   lda (ZP_PTR),y
   and #$07
   asl
   asl
   ora #$40
   sta answer+3
   iny
   lda (ZP_PTR),y
   lsr
   lsr
   lsr
   lsr
   lsr
   lsr
   ora answer+3
   sta answer+3
   lda (ZP_PTR),y
   and #$1F
   ora #$40
   sta answer+4
   ; finally, find preceding address in LUT to get first two letters
   lda ZP_PTR
   sta scratch
   lda ZP_PTR+1
   sta scratch+1           ; scratch = word address
   lda LUT_LA+1
   cmp scratch+1
   bmi @check_ta
   bne @check_ea
   lda LUT_LA
   sec
   sbc scratch
   beq @search_la
   bcc @check_ta
@check_ea:
   lda LUT_EA+1
   cmp scratch+1
   bmi @check_ha
   bne @search_ab
   lda LUT_EA
   sec
   sbc scratch
   beq @search_ea
   bcs @search_ab
@check_ha:
   lda LUT_HA+1
   cmp scratch+1
   bmi @search_ha
   bne @search_ea
   lda LUT_HA
   sec
   sbc scratch
   beq @search_ha
   bcc @search_ha
   bcs @search_ea
@check_ta:
   lda LUT_TA+1
   cmp scratch+1
   bmi @check_wa
   bne @check_pa
   lda LUT_TA
   sec
   sbc scratch
   beq @search_ta
   bcc @check_wa
@check_pa:
   lda LUT_PA+1
   cmp scratch+1
   bmi @search_pa
   bne @search_la
   lda LUT_PA
   sec
   sbc scratch
   beq @search_pa
   bcc @search_pa
   bcs @search_la
@check_wa:
   lda LUT_WA+1
   cmp scratch+1
   bmi @search_wa
   bne @search_ta
   lda LUT_WA
   sec
   sbc scratch
   beq @search_wa
   bcc @search_wa
   bcs @search_ta
@search_ab:
   ldx #0
   beq @search_entry
@search_ea:
   ldx #2
   bne @search_entry
@search_ha:
   ldx #4
   bne @search_entry
@search_la:
   ldx #6
   bne @search_entry
@search_pa:
   ldx #8
   bne @search_entry
@search_ta:
   ldx #10
   bne @search_entry
@search_wa:
   ldx #12
@search_entry:
   lda lut_segments,x
   sta ZP_PTR
   inx
   lda lut_segments,x
   sta ZP_PTR+1
   lda ZP_PTR
   sta last_address
   lda ZP_PTR+1
   sta last_address+1
   ldy #0
@search_loop:
   ; search for entries surrounding scratch
   lda (ZP_PTR),y
   tax
   iny
   lda (ZP_PTR),y
   iny
   ;beq @reverse_lut ; VICE 6510 doesn't clear Z on INY to non-zero value
   cmp #0
   beq @search_loop
   cmp scratch+1
   bmi @update_last
   bne @reverse_lut
   txa
   sec
   sbc scratch
   beq @update_last
   bcs @reverse_lut
@update_last:
   tya
   sec
   sbc #2
   clc
   adc ZP_PTR
   sta last_address
   lda #0
   adc ZP_PTR+1
   sta last_address+1
   jmp @search_loop
@reverse_lut:
   ; preceding LUT address found, convert offset to letters
   lda last_address
   sec
   sbc #<WORD_TABLE
   sta last_address
   lda last_address+1
   sbc #>WORD_TABLE
   sta last_address+1
   ; divide by 52
   lda #0
   sta remainder
   ldx #16
@div52_loop:
   asl last_address
   rol last_address+1
   rol remainder
   lda remainder
   sec
   sbc #52
   bcc @next_bit
   sta remainder
   inc last_address
@next_bit:
   dex
   bne @div52_loop
   ; division complete, first letter = integer quotient
   lda last_address
   clc
   adc #$41
   sta answer
   ; second letter = remainder/2
   lda remainder
   lsr
   clc
   adc #$41
   sta answer+1
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
   ldx #16
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
   ldx #23
   ldy #0
   clc
   jsr PLOT
   rts

print_message: ; X/Y - address of null-terminated string
   stx ZP_PTR
   sty ZP_PTR+1
   ldx #16
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
   adc #3
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
   bne @start_search
   jmp @not_found
@start_search:
   lda ZP_PTR
   sta ZP_PTR_2
   lda ZP_PTR+1
   sta ZP_PTR_2+1
   ldy #0
   lda (ZP_PTR),y
   sta scratch
   iny
   lda (ZP_PTR),y
   sta ZP_PTR+1
   lda scratch
   sta ZP_PTR
   ; compress guess for comparison
   lda guess+2
   asl
   asl
   asl
   sta scratch
   lda guess+3
   and #$1F
   lsr
   lsr
   ora scratch
   sta scratch
   lda guess+3
   asl
   asl
   asl
   asl
   asl
   asl
   sta scratch+1
   lda guess+4
   and #$1F
   ora scratch+1
   sta scratch+1
   ; find next non-zero LUT address
   lda ZP_PTR_2
   clc
   adc #2
   sta ZP_PTR_2
   lda ZP_PTR_2+1
   adc #0
   sta ZP_PTR_2+1
   ldy #1
   ; loop checking for non-zero address before WORD_ZERO
@search_lut_loop:
   cmp #>WORD_ZERO
   bmi @check_lut_zero
   lda ZP_PTR_2
   cmp #<WORD_ZERO
   bpl @set_list_end
@check_lut_zero:
   lda (ZP_PTR_2),y
   bne @set_next_block
   lda ZP_PTR_2
   clc
   adc #2
   sta ZP_PTR_2
   lda ZP_PTR_2+1
   adc #0
   sta ZP_PTR_2+1
   jmp @search_lut_loop
@set_next_block:
   lda (ZP_PTR_2),y
   sta last_address+1
   dey
   lda (ZP_PTR_2),y
   sta last_address
   jmp @compare_word
@set_list_end:
   lda word_table_size
   asl
   sta last_address
   lda word_table_size+1
   rol
   sta last_address+1
   lda last_address
   clc
   adc #<WORD_ZERO
   sta last_address
   lda last_address+1
   adc #>WORD_ZERO
   sta last_address+1
@compare_word:
   ldy #0
   lda (ZP_PTR),y
   cmp scratch
   bne @next_word
   iny
   lda (ZP_PTR),y
   cmp scratch+1
   beq @found
@next_word:
   lda ZP_PTR
   clc
   adc #2
   sta ZP_PTR
   lda ZP_PTR+1
   adc #0
   sta ZP_PTR+1
   cmp last_address+1
   bmi @compare_word
   lda ZP_PTR
   cmp last_address
   bne @compare_word
@not_found:
   ldx #<not_word
   ldy #>not_word
   jsr print_message
@reset_cursor:
   lda guess_index
   asl
   clc
   adc #3
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
   adc #$B3
   sta $9F21   ; high byte VRAM address = $B0 + Y coordinate (guess index*2 + 4)
   lda #$01
   sta $9F22   ; bank = 1, stride = 0
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
   adc #3         ; A = row
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
   lda #0
   sta ZP_PTR+1
   lda guess_index
   asl
   adc #3         ; A = row
   asl
   sta scratch    ; row * 2
   asl
   sta scratch+1  ; row * 4
   asl
   asl
   sta ZP_PTR     ; ZP_PTR = row * 16
   adc scratch
   rol ZP_PTR+1
   adc scratch+1  ; ZP_PTR = row * 22
   sta ZP_PTR
   lda ZP_PTR+1
   adc #0
   sta ZP_PTR+1
   lda $0288
   adc ZP_PTR+1
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
   and #$03
   ora #$94
   sta ZP_PTR+1   ; ZP_PTR = letter position in color RAM
   lda scratch
   sta (ZP_PTR,x) ; set color
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
   adc #3
   tax
   jsr PLOT
   pla
   tax
   lda guess,x
   jsr CHROUT
   jmp @next_yellow
@return:
   rts
