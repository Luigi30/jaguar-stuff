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
	
	.globl _line_x1_value	;all uint32_t
	.globl _line_x2_value
	.globl _line_y1_value
	.globl _line_y2_value
	.globl _line_clut_color
	
;Registers for line drawing.
	LINE_X1		.equr	r10
	LINE_X2		.equr	r11
	LINE_Y1		.equr	r12
	LINE_Y2		.equr	r13
	PIXEL_OFFSET	.equr	r14
	
	X_DIST		.equr	r15
	Y_DIST		.equr	r16
	
	SLOPE		.equr	r17
	
	;fixed point division
	DIV_TEMP_HI	.equr	r18
	DIV_TEMP_LO	.equr	r19
	DIVIDEND	.equr	r20
	DIVISOR		.equr	r21
	
	B_A1_BASE	.equr	r22
	B_A1_PIXEL	.equr	r23
	B_A1_FPIXEL	.equr	r24
	B_A1_INC	.equr	r25
	B_A1_FINC	.equr	r26
	B_A1_FLAGS	.equr	r27
	B_A1_STEP	.equr	r28
	B_B_PATD	.equr	r29
	B_B_COUNT	.equr	r30
	B_B_CMD		.equr	r31

	.include "regmacros.inc"
	
	.macro BLIT_XY x,y
	move	\x,TEMP1
	move	\y,TEMP2
	shlq	#16,TEMP1
	or		TEMP2,TEMP1
			.endm
			
	.phrase
_draw_something::
	.gpu
	.org G_RAM

	;Find the scanline offset for Y
	LoadValue	_line_y1_value,LINE_Y1
	move	LINE_Y1,TEMP1
	shlq	#2,TEMP1		;TEMP1 is now the offset into the scanline table
	
	movei	#_scanline_offset_table,TEMP2
	add		TEMP1,TEMP2
	load	(TEMP2),PIXEL_OFFSET
	
	LoadValue	_jag_vidmem,TEMP1
	add		PIXEL_OFFSET,TEMP1		;TEMP1 is now the VRAM address for LINE_Y1.
	
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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	.phrase
_blit_line::
	.gpu
	.org G_RAM
	
	LoadValue	_line_x1_value,LINE_X1
	LoadValue	_line_x2_value,LINE_X2
	LoadValue	_line_y1_value,LINE_Y1
	LoadValue	_line_y2_value,LINE_Y2
	
	;Calculate abs(x2-x1) and abs(y2-y1)
	move	LINE_X2,X_DIST
	sub		LINE_X1,X_DIST
	abs		X_DIST
	
	move	LINE_Y2,Y_DIST
	sub		LINE_Y1,Y_DIST
	abs		Y_DIST
	
	movei	#_line_x1_value,TEMP1
	movei	#_line_x2_value,TEMP2
	
	store	X_DIST,(TEMP1)
	store	Y_DIST,(TEMP2)
	
	movei	#blit_line_done,JUMPADDR
	jump	t,(JUMPADDR)
	nop
	
	;Slope calculation.
.calculate_slope:
	;TODO: check for division by 0
	move	Y_DIST,DIVIDEND
	move	X_DIST,DIVISOR
	
	;Set up for 16.16 divide
	moveq	#1,TEMP1
	movei	#G_DIVCTRL,TEMP2
	store	TEMP1,(TEMP2)
	
	div		DIVISOR,DIVIDEND	;destination / source
	move	DIVIDEND,SLOPE		;slope = DIVISOR/DIVIDEND
	
	;Set up for 16.16 divide
	moveq	#0,TEMP1
	movei	#G_DIVCTRL,TEMP2
	store	TEMP1,(TEMP2)
	
.do_blit:

	;Set up registers for writing
	movei	#A1_BASE,B_A1_BASE
	movei	#A1_PIXEL,B_A1_PIXEL
	movei	#A1_FPIXEL,B_A1_FPIXEL
	movei	#A1_INC,B_A1_INC
	movei	#A1_FINC,B_A1_FINC
	movei	#A1_FLAGS,B_A1_FLAGS
	movei	#A1_STEP,B_A1_STEP
	movei	#B_PATD,B_B_PATD
	movei	#B_PATD,B_B_COUNT
	movei	#B_COUNT,B_B_CMD
	
;Write to these registers.
	movei	#_jag_vidmem,TEMP1
	store	TEMP1,(B_A1_BASE)
	
	BLIT_XY	LINE_X1,LINE_Y1
	store	TEMP1,(B_A1_PIXEL)
	
	moveq	#0,TEMP1
	store	TEMP1,(B_A1_FPIXEL)
	
	move	SLOPE,TEMP1
	shrq	#16,TEMP1
	store	TEMP1,(B_A1_INC)
	
	move	SLOPE,TEMP1
	movei	#$0000FFFF,TEMP2
	and		TEMP2,TEMP1
	store	TEMP1,(B_A1_FINC)
	
	movei	#PITCH1|PIXEL8|WID320|XADDINC,TEMP1
	store	TEMP1,(B_A1_FLAGS)
	
	movei	#$00010000,TEMP1
	store	TEMP1,(B_A1_STEP)
	
	moveq	#1,TEMP1
	store	TEMP1,(B_B_PATD)
	
	moveq	#1,TEMP1
	move	Y_DIST,TEMP2
	addq	#1,TEMP2
	BLIT_XY	TEMP1,TEMP2
	store	TEMP1,(B_B_COUNT)
	
	movei	#PATDSEL|UPDA1|UPDA1F|LFU_S,TEMP1
	store	TEMP1,(B_B_CMD)
	
blit_line_done:	
	StopGPU
	nop
	
	.long
	.68000
_blit_line_end::