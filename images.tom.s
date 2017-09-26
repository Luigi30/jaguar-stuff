	.data
	
	.phrase
_atarifont::	;1bpp
	.include "images/atarifont.s"
	
	.phrase
; Converted with 'Jaguar image converter' (version 0.1.7) by Seb/The Removers
_bee_pal::
; bee.png
; 16 colors
; CLUT RGB 16
	dc.w	$0000, $B5AC, $1085, $DEF7, $294A, $BDEE, $D432, $1085, $CB2E, $AAA7, $BA2B, $8A61, $7A1D, $69D8, $A9E7, $2109
	
	.phrase
_beelogo::		;RGB16
	.include "images/beelogo.s"
	
	.phrase
_bee_frame1::	;4bpp
	.include "images/bee-wings1.s"
	
	.phrase
_bee_frame2::	;4bpp
	.include "images/bee-wings2.s"
	
	.phrase
_buttbot::		;1bpp
	.include "images/buttbot.s"
_buttbot_pal::
; buttbot.png
; 9 colors
; CLUT RGB 16
	dc.w	$4B9A, $39CE, $C9E0, $D266, $F3AC, $F431, $EDF6, $CBAB, $0180

	.phrase
_butttext::		;1bpp
	.include "images/butttext.s"
	
