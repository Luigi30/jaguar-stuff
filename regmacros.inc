;Equates
BMP_WIDTH	.equ	320
BMP_HEIGHT	.equ	200

;Registers we want to be consistent with
TEMP1		.equr	r0
TEMP2		.equr	r1

LOOPCOUNTER	.equr	r2
LOOPEND		.equr	r3

PIXELOFFSET	.equr	r4
VIDMEMBASE	.equr	r5
VIDDEST		.equr	r6

LOADTEMP	.equr	r7

JUMPADDR	.equr	r8
RETURNADDR	.equr	r9
	
;Macros
	.macro LoadValue val, reg
        movei	#\val,LOADTEMP
        load	(LOADTEMP),\reg
	.endm
	
	.macro	StopGPU
		moveq   #0,TEMP1         	; Stop GPU
		movei   #G_CTRL,TEMP2
		store   TEMP1,(TEMP2)
		nop
		nop
	.endm
	