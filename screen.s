	.include "jaguar.inc"
	.globl	_jag_vidmem
	.globl	_scanline_offset_table
	
;Equates
BMP_WIDTH	.equ	320
BMP_HEIGHT	.equ	200

;Registers we want to be consistent with
TEMP1		.equr	r0
TEMP2		.equr	r1

LOOPCOUNTER	.equr	r2
LOOPEND		.equr	r3

PIXELOFFSET	.equr	r17
VIDMEMBASE	.equr	r18
VIDDEST		.equr	r19
	
;Macros
	.macro LoadValue val, reg
        movei	#\val,TEMP1
        load	(TEMP1),\reg
	.endm
	
	.macro	StopGPU
		moveq   #0,TEMP1         	; Stop GPU
		movei   #G_CTRL,TEMP2
		store   TEMP1,(TEMP2)
		nop
		nop
	.endm
	
;Create the scanline offset table.
	.phrase
_create_scanline_table::
	.gpu

	.org	G_RAM
	movei	#200,LOOPEND
	movei	#0,LOOPCOUNTER
	movei	#0,TEMP1
	movei	#BMP_WIDTH,TEMP2
	
	movei	#_scanline_offset_table,r8
	
.scanlineloop:
	storew	TEMP1,(r8)
	add		TEMP2,TEMP1
	addq	#2,r8

	addq	#1,LOOPCOUNTER	
	cmp		LOOPCOUNTER,LOOPEND
	jr		ne,.scanlineloop 			;the instruction after a jr is always executed :hmm:
	nop
	
	;end
	StopGPU
	.long
	.68000
_create_scanline_table_end::

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	.phrase
_blank_screen::
	.gpu

	.org	G_RAM
	LoadValue	_jag_vidmem,VIDMEMBASE
	
	move	VIDMEMBASE,VIDDEST
	movei	#320*20,TEMP1
	add		TEMP1,VIDDEST
	
	movei	#1,TEMP1
	store	TEMP1,(VIDDEST)
	
	;End the program, stop the GPU.
	StopGPU
	.long
	.68000
_blank_screen_end::

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;