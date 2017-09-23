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
	PIXEL_OFFSET	.equr	r14
	
	X_DIST		.equr	r15
	Y_DIST		.equr	r16
	
	SLOPE		.equr	r17

	;; pixel count
	PX_COUNT_X	.equr	r18
	PX_COUNT_Y	.equr	r19
	
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

	shrq	#16,LINE_X1
	shlq	#16,LINE_X1
	shrq	#16,LINE_X2
	shlq	#16,LINE_X2
	shrq	#16,LINE_Y1
	shlq	#16,LINE_Y1
	shrq	#16,LINE_Y2
	shlq	#16,LINE_Y2
	
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
		
	;Slope calculation.
.calculate_slope:
	;TODO: check for division by 0. In fixed point mode the result is 0xFFFFFFFF
	move	Y_DIST,DIVIDEND
	move	X_DIST,DIVISOR
	
	;Set up for 16.16 divide
	moveq	#1,TEMP1
	movei	#G_DIVCTRL,TEMP2
	store	TEMP1,(TEMP2)
	
	div	DIVISOR,DIVIDEND	;destination / source
	move	DIVIDEND,SLOPE		;slope = DIVISOR/DIVIDEND
	
	;; back to integer divide
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
	movei	#B_COUNT,B_B_COUNT
	movei	#B_CMD,B_B_CMD

;Write to these registers.
	;; buffer is at background_pixels
	movei	#_back_buffer,TEMP1
	load	(TEMP1),TEMP1
	move	TEMP1,r5
	store	TEMP1,(B_A1_BASE)
	
	;; start blitting from (X1,Y1)
	move	LINE_X1,r18
	shrq	#16,r18
	move	LINE_Y1,r19
	shrq	#16,r19
	
	BLIT_XY	r18,r19
	store	TEMP1,(B_A1_PIXEL)

	;; no fractional pixel to start
	moveq	#0,TEMP1
	store	TEMP1,(B_A1_FPIXEL)

	;; get the integer slope, store it in A1_INC
	move	SLOPE,TEMP1
	shrq	#16,TEMP1
	store	TEMP1,(B_A1_INC)

	;; get the fractional slope, store it in A1_FINC
	move	SLOPE,TEMP1
	movei	#$0000FFFF,TEMP2
	and	TEMP2,TEMP1
	store	TEMP1,(B_A1_FINC)

	;; 1-phrase pitch, 8-bit pixels, 320px width, XADD = 1
	cmpq	#0,SLOPE		;is slope 0?
	jr	eq,.slope_is_zero	;yes, add one to X per pixel instead of the slope register

	;; slope is not zero
	movei	#PITCH1|PIXEL8|WID320|XADDINC,TEMP1 ;always executed
	jr	t,.step_sign_check		    ;continue setting blitter registers
	store	TEMP1,(B_A1_FLAGS)		    ;always executed

.slope_is_zero:
	movei	#PITCH1|PIXEL8|WID320|XADDPIX,TEMP1 ;executed if slope == 0
	store	TEMP1,(B_A1_FLAGS)

.step_sign_check:
	;; check for negative slope
	move	LINE_Y1,TEMP1
	move	LINE_Y2,TEMP2
	sub	TEMP1,TEMP2
	jr	pl,.storeStep		 ;slope positive? jump over and store.
	movei	#$00010000,TEMP1	 ;step = (0,1). always executed.

	;; if we didn't jump, then the slope is negative.
	movei	#$FFFF0000,TEMP1 ;step = (0,-1).
.storeStep:
	store	TEMP1,(B_A1_STEP) ;and store the step
	
.slope_positive:
	movei	#_line_clut_color,TEMP2
	load	(TEMP2),TEMP1
	store	TEMP1,(B_B_PATD)

	cmpq	#0,Y_DIST
	jr	ne,.nothorizontal
	nop

.horizontal:
	move	X_DIST,PX_COUNT_X
	shrq	#16,PX_COUNT_X
	
	moveq	#1,PX_COUNT_Y
	jr	t,.copy_count
	nop
	
.nothorizontal:
*	move	X_DIST,PX_COUNT_X
*	shrq	#16,PX_COUNT_X
	movei	#1,PX_COUNT_X
	
	move	Y_DIST,PX_COUNT_Y
	shrq	#16,PX_COUNT_Y
	
*	addq	#1,PX_COUNT_Y

.copy_count:
	BLIT_XY	PX_COUNT_X,PX_COUNT_Y
	store	TEMP1,(B_B_COUNT)

	move	B_B_COUNT,TEMP1
	
	movei	#_line_x1_value,TEMP2
	store	TEMP1,(TEMP2)
	
	movei	#PATDSEL|UPDA1|UPDA1F|LFU_S,TEMP1
	store	TEMP1,(B_B_CMD)

	;; wait for blit to complete
wait_for_blit:	
	movei	#$F02238,TEMP1
	load	(TEMP1),TEMP2
	btst	#0,TEMP2
	jr	eq,wait_for_blit ;B_STATUS bit 0. 0 if busy, 1 if set.
	
blit_line_done:	
	StopGPU
	nop
	
	.long
	.68000
_blit_line_end::
