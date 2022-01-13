.org $080D
.segment "STARTUP"
.segment "INIT"
.segment "ONCE"
.segment "CODE"

   jmp start

.include "cbm_kernal.inc"

screen_text:
.byte $92,$93,$8E,$05,"word slide!",$0D,$0D
.byte $B0,$C3,$B2,$C3,$B2,$C3,$B2,$C3,$B2,$C3,$AE,$0D
.byte $C2," ",$C2," ",$C2," ",$C2," ",$C2," ",$C2,$0D
.byte $AB,$C3,$DB,$C3,$DB,$C3,$DB,$C3,$DB,$C3,$B3,$0D
.byte $C2," ",$C2," ",$C2," ",$C2," ",$C2," ",$C2,$0D
.byte $AB,$C3,$DB,$C3,$DB,$C3,$DB,$C3,$DB,$C3,$B3,$0D
.byte $C2," ",$C2," ",$C2," ",$C2," ",$C2," ",$C2,$0D
.byte $AB,$C3,$DB,$C3,$DB,$C3,$DB,$C3,$DB,$C3,$B3,$0D
.byte $C2," ",$C2," ",$C2," ",$C2," ",$C2," ",$C2,$0D
.byte $AB,$C3,$DB,$C3,$DB,$C3,$DB,$C3,$DB,$C3,$B3,$0D
.byte $C2," ",$C2," ",$C2," ",$C2," ",$C2," ",$C2,$0D
.byte $AB,$C3,$DB,$C3,$DB,$C3,$DB,$C3,$DB,$C3,$B3,$0D
.byte $C2," ",$C2," ",$C2," ",$C2," ",$C2," ",$C2,$0D
.byte $AD,$C3,$B1,$C3,$B1,$C3,$B1,$C3,$B1,$C3,$BD,$0D,$0D
.byte $B0,$C3,$C3,$C3,$C3,$C3,$C3,$C3,$C3,$C3,$C3,$AE,$0D
.byte $C2,"qwertyuiop",$C2,$0D
.byte $C2,"asdfghjkl ",$C2,$0D
.byte $C2," zxcvbnm  ",$C2,$0D
.byte $AD,$C3,$C3,$C3,$C3,$C3,$C3,$C3,$C3,$C3,$C3,$BD,0

start:
