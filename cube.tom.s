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
	.globl	_back_buffer
	.globl	_scanline_offset_table
	
	;all FIXED_32
	.globl _line_x1_value
	.globl _line_x2_value
	.globl _line_y1_value
	.globl _line_y2_value
	.globl _line_clut_color
	
;Registers for line drawing.
	LINE_X1		.equr	r10
	LINE_Y1		.equr	r11
	LINE_X2		.equr	r12
	LINE_Y2		.equr	r13
	
	X_DIST		.equr	r15
	Y_DIST		.equr	r16

	DIVIDEND	.equr	r17
	DIVISOR		.equr	r18
	SLOPE		.equr	r19
		
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

	.macro DEBUG_DUMP variable,destination
	movei	#\variable,TEMP1
	load	(TEMP1),TEMP1
	movei	#\destination,TEMP2
	store	TEMP1,(TEMP2)
	.endm
	
	.macro BLIT_XY x,y
	move	\x,TEMP2
	move	\y,TEMP1
	shlq	#16,TEMP1
	or	TEMP2,TEMP1
	.endm
			
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	.phrase
_blit_line::
	.gpu
	.org G_RAM

	movei   #G_FLAGS,r1       ; Status flags
	load    (r1),r0	
	bset    #14,r0
	store   r0,(r1)           ; Switch the GPU/DSP to bank 1
	
	LoadValue	_line_x1_value,LINE_X1
	LoadValue	_line_x2_value,LINE_X2
	LoadValue	_line_y1_value,LINE_Y1
	LoadValue	_line_y2_value,LINE_Y2

	;; TODO: Fix the issue with B_COUNT being set wrong on mostly-vertical lines
	;; when there is a decimal value in the slope
	movei	#$FFFF0000,TEMP1
*	and	TEMP1,LINE_X1
*	and	TEMP1,LINE_X2
*	and	TEMP1,LINE_Y1
*	and	TEMP1,LINE_Y2

	;; X1 > X2? Swap the points if so.
	cmp	LINE_X1,LINE_X2
	jr	hi,.calculateDistances

	move	LINE_X1,TEMP1
	move	LINE_X2,LINE_X1
	move	TEMP1,LINE_X2

	move	LINE_Y1,TEMP1
	move	LINE_Y2,LINE_Y1
	move	TEMP1,LINE_Y2
	
.calculateDistances:	
	;Calculate abs(x2-x1) and abs(y2-y1)
	move	LINE_X2,X_DIST
	sub	LINE_X1,X_DIST
	abs	X_DIST
	
	move	LINE_Y2,Y_DIST
	sub	LINE_Y1,Y_DIST
	abs	Y_DIST

setup_blit:	
;; Set up registers for writing
	movei	#A1_BASE,B_A1_BASE
	movei	#A1_PIXEL,B_A1_PIXEL
	movei	#A1_FPIXEL,B_A1_FPIXEL
	movei	#A1_INC,B_A1_INC
	movei	#A1_FINC,B_A1_FINC
	movei	#A1_FLAGS,B_A1_FLAGS
	movei	#A1_STEP,B_A1_STEP
	movei	#B_PATD,B_B_PATD
	movei	#B_COUNT,B_B_COUNT
	movei	#B_CMD,B_B_CMD

.preset_registers:
	;; pre-set the blit registers

	movei	#_back_buffer,TEMP1
	load	(TEMP1),TEMP1
	move	TEMP1,r5
	store	TEMP1,(B_A1_BASE)

	movei	#_line_clut_color,TEMP2
	load	(TEMP2),TEMP1
	store	TEMP1,(B_B_PATD)

	movei	#0,TEMP1
	movei	#A1_CLIP,TEMP2
	store	TEMP1,(TEMP2)
	
.draw_line:
	movei	#dy_greater,TEMP1
	movei	#dx_greater,TEMP2
	movei	#dx_equals_dy,JUMPADDR
	cmp	X_DIST,Y_DIST
	jump	hi,(TEMP1) 	;dy_greater
	nop
	cmp	X_DIST,Y_DIST
	jump	eq,(JUMPADDR)	;dx_equals_dy
	nop
	jump	t,(TEMP2)	;dx_greater
	nop

dy_greater:
	movei	#6,r6

.calc_slope:
	move	X_DIST,DIVIDEND
	move	Y_DIST,DIVISOR
	
	;Set up for 16.16 divide
	moveq	#1,TEMP1
	movei	#G_DIVCTRL,TEMP2
	store	TEMP1,(TEMP2)

	;; dx / dy
	div	DIVISOR,DIVIDEND	;destination / source
	move	DIVIDEND,SLOPE		;slope = DIVISOR/DIVIDEND
	
	;; back to integer divide
	moveq	#0,TEMP1
	movei	#G_DIVCTRL,TEMP2
	store	TEMP1,(TEMP2)

	movei	#.y2_is_greater,JUMPADDR
	cmp	LINE_Y1,LINE_Y2	
	jump	cc,(JUMPADDR)
	nop
	jump	eq,(JUMPADDR)
	nop

.y1_is_greater:
	;; YINC = -1
	;; XINC = (dx<<16) / dy

	movei	#$FFFF0000,TEMP1
	store	TEMP1,(B_A1_INC)
	store	SLOPE,(B_A1_FINC)

	movei	#.set_registers,JUMPADDR
	jump	t,(JUMPADDR)

.y2_is_greater:
	;; YINC = 1
	;; XINC = (dx<<16) / dy

	movei	#$00010000,TEMP1
	store	TEMP1,(B_A1_INC)
	store	SLOPE,(B_A1_FINC)
	
.set_registers:
	move	LINE_X1,r18
	move	LINE_Y1,r19
	shrq	#16,r18
	shrq	#16,r19
	
	BLIT_XY	r18,r19
	store	TEMP1,(B_A1_PIXEL)

	movei	#0,TEMP1
	store	TEMP1,(B_A1_FPIXEL)

	movei	#PITCH1|PIXEL8|WID320|XADDINC,TEMP1
	store	TEMP1,(B_A1_FLAGS)

	movei	#$00000000,TEMP1
	store	TEMP1,(B_A1_STEP)

	movei	#blit_line_done,JUMPADDR
	cmpq	#0,Y_DIST
	jump	eq,(JUMPADDR)
	
	move	Y_DIST,TEMP1
	movei	#$FFFF0000,TEMP2
	and	TEMP2,TEMP1
	addq	#1,TEMP1
	store	TEMP1,(B_B_COUNT)
	
	movei	#blit_line_go,JUMPADDR
	jump	t,(JUMPADDR)
	nop
	
;;; 
dx_greater:
	movei	#7,r6

.calc_slope:
	move	Y_DIST,DIVIDEND
	move	X_DIST,DIVISOR
*	shlq	#16,DIVISOR
	
	;Set up for 16.16 divide
	moveq	#1,TEMP1
	movei	#G_DIVCTRL,TEMP2
	store	TEMP1,(TEMP2)

	;; dy / dx
	div	DIVISOR,DIVIDEND	;destination / source
	move	DIVIDEND,SLOPE		;slope = DIVISOR/DIVIDEND
	
	;; back to integer divide
	moveq	#0,TEMP1
	movei	#G_DIVCTRL,TEMP2
	store	TEMP1,(TEMP2)

	movei	#.y2_is_greater,JUMPADDR
	cmp	LINE_Y1,LINE_Y2	
	jump	cc,(JUMPADDR)
	nop
	jump	eq,(JUMPADDR)
	nop

;;; if y1 > y2
.y1_greater:
	movei	#11,r6
	;; YINC = 65536 - ((dy<<16)/dx)
	movei	#65536,TEMP1
	sub	SLOPE,TEMP1

	movei	#$FFFF0001,TEMP2
	store	TEMP2,(B_A1_INC)

	shlq	#16,TEMP1
	store	TEMP1,(B_A1_FINC)

	movei	#.set_registers,JUMPADDR
	jump	t,(JUMPADDR)
	nop

.y2_is_greater:
	movei	#12,r6
	;; YINC = (dy<<16) / dx
	movei	#$00000001,TEMP1 
	store	TEMP1,(B_A1_INC) 

	move	SLOPE,TEMP1
	shlq	#16,TEMP1
	store	TEMP1,(B_A1_FINC)

.set_registers:
	;; A1_PIXEL = LINE_X1,LINE_Y1
	move	LINE_X1,r18
	move	LINE_Y1,r19
	shrq	#16,r18
	shrq	#16,r19
	
	BLIT_XY	r18,r19
	store	TEMP1,(B_A1_PIXEL)

	movei	#0,TEMP1
	store	TEMP1,(B_A1_FPIXEL)

	movei	#PITCH1|PIXEL8|WID320|XADDINC,TEMP1
	store	TEMP1,(B_A1_FLAGS)

	movei	#$00000000,TEMP1
	store	TEMP1,(B_A1_STEP)
	
	;; B_COUNT  = 1<<16 + X_DIST>>16
	movei	#blit_line_done,JUMPADDR
	cmpq	#0,X_DIST
	jump	eq,(JUMPADDR)
	
	move	X_DIST,TEMP1
	shrq	#16,TEMP1
	movei	#$00010000,TEMP2
	add	TEMP2,TEMP1
	store	TEMP1,(B_B_COUNT)
	
	movei	#blit_line_go,JUMPADDR
	jump	t,(JUMPADDR)
	nop

;;; this works
dx_equals_dy:
	movei	#8,r6

	cmp	LINE_Y1,LINE_Y2	
	jr	hi,.y2_is_greater
	nop
	
.y1_is_greater:
	movei	#9,r6
	nop
	movei	#$FFFF0001,r20
	store	r20,(B_A1_INC)
	nop
	jr	t,.set_registers
	nop
	
.y2_is_greater:
	movei	#10,r6
	movei	#$00010001,r20
	store	r20,(B_A1_INC)
	
.set_registers:
	move	LINE_X1,r18
	move	LINE_Y1,r19
	shrq	#16,r18
	shrq	#16,r19
	
	BLIT_XY	r18,r19
	store	TEMP1,(B_A1_PIXEL)

	movei	#0,TEMP1
	store	TEMP1,(B_A1_FPIXEL)

	movei	#$00000000,TEMP1
	store	TEMP1,(B_A1_FINC)

	movei	#blit_line_done,JUMPADDR
	cmpq	#0,Y_DIST
	jump	eq,(JUMPADDR)
	
	move	Y_DIST,TEMP1
	movei	#$FFFF0000,TEMP2
	and	TEMP2,TEMP1
	addq	#1,TEMP1
	move	TEMP1,r5
	store	TEMP1,(B_B_COUNT)

blit_line_go:
	movei	#PITCH1|PIXEL8|WID320|XADDINC,TEMP1
	store	TEMP1,(B_A1_FLAGS)
	
	movei	#PATDSEL|UPDA1|UPDA1F|LFU_S,TEMP1
	store	TEMP1,(B_B_CMD)

	;; wait for blit to complete
wait_for_blitter:	
	movei	#$F02238,TEMP1
	load	(TEMP1),TEMP2
	btst	#0,TEMP2
	jr	eq,wait_for_blitter ;B_STATUS bit 0. 0 if busy, 1 if set.
	
blit_line_done:	
	StopGPU
	nop
	
	.long
	.68000
_blit_line_end::
