	.include "jaguar.inc"
	.globl	_jag_vidmem
	.globl	_scanline_offset_table
	
	.include "regmacros.inc"
	
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
	store	TEMP1,(r8)
	add		TEMP2,TEMP1
	addq	#4,r8

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