; jump condition codes
;   %00000:   T    always
;   %00100:   CC   carry clear (less than)
;   %01000:   CS   carry set   (greater or equal)
;   %00010:   EQ   zero set (equal)
;   %00001:   NE   zero clear (not equal) 
;   %11000:   MI   negative set
;   %10100:   PL   negative clear
;   %00101:   HI   greater than

	.include "jaguar.inc"
	.globl	_jag_vidmem
	.globl	_scanline_offset_table

	.include "regmacros.inc"
	
	.phrase
_draw_something::
	.gpu
	.org G_RAM
	
	.globl _line_x1_value	;all uint32_t
	.globl _line_x2_value
	.globl _line_y_value
	.globl _line_clut_color

LINE_X1		.equr	r10
LINE_X2		.equr	r11
LINE_Y		.equr	r12
PIXEL_OFFSET	.equr	r13

	;Find the scanline offset for Y
	LoadValue	_line_y_value,LINE_Y
	move	LINE_Y,TEMP1
	shlq	#2,TEMP1		;TEMP1 is now the offset into the scanline table
	
	movei	#_scanline_offset_table,TEMP2
	add		TEMP1,TEMP2
	load	(TEMP2),PIXEL_OFFSET
	
	LoadValue	_jag_vidmem,TEMP1
	add		PIXEL_OFFSET,TEMP1		;TEMP1 is now the VRAM address for LINE_Y.
	
	;We have the scanline offset. Now draw on that line from x1 to x2.
	LoadValue	_line_x1_value,LINE_X1
	LoadValue	_line_x2_value,LINE_X2
	
	;Okay, draw.
	LoadValue _line_clut_color,TEMP2
	add		LINE_X1,TEMP1	;offset
	
.draw_horizontal_loop:
	storeb	TEMP2,(TEMP1)
	addq	#1,TEMP1
	
	;Draw until x1 == x2
	addq	#1,LINE_X1
	cmp		LINE_X1,LINE_X2
	jr		cc,.draw_horizontal_loop
	nop
	
	;end
	StopGPU
	nop
	
	.long
	.68000
_draw_something_end::
