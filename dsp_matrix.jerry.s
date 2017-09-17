	;;  jump condition codes
	;;    %00000:   T    always
	;;    %00100:   CC   carry clear (less than)
	;;    %01000:   CS   carry set   (greater or equal)
	;;    %00010:   EQ   zero set (equal)
	;;    %00001:   NE   zero clear (not equal)
	;;    %11000:   MI   negative set
	;;    %10100:   PL   negative clear
	;;    %00101:   HI   greater than

	.include "jaguar.inc"
	.globl  _jag_vidmem
	.globl  _scanline_offset_table

	.include "regmacros.inc"

	SIZE_UINT32	.equ	4 ;bytes
	
;;; Global registers for these functions
	PTR_INDEX	.equr	r14 ;index into whatever register we're accessing
	
	PTR_MATRIX_1	.equr	r20 ;pointer to Matrix 1
	PTR_MATRIX_2	.equr	r21 ;pointer to Matrix 2
	PTR_MATRIX_R	.equr	r22 ;pointer to result matrix
	
;;; ;;;;;;;;;;;;;;;;
;;; DSP matrix functions
	.globl 	_dsp_matrix_ptr_m1
	.globl	_dsp_matrix_ptr_m2

_dsp_matrix_functions::
	
	.phrase
_dsp_matrix_identity_set::
	.dsp
	.org D_RAM

	movei	#_dsp_matrix_result,TEMP1
	move	TEMP1,PTR_MATRIX_1

	moveq	#0,TEMP1
	movei	#$00010000,TEMP2 ;fixed-point: 1.0

	;; Row 0
	movei	#SIZE_UINT32*0,PTR_INDEX
	store	TEMP2,(PTR_INDEX+PTR_MATRIX_1)

	movei	#SIZE_UINT32*1,PTR_INDEX
	store	TEMP1,(PTR_INDEX+PTR_MATRIX_1)

	movei	#SIZE_UINT32*2,PTR_INDEX
	store	TEMP1,(PTR_INDEX+PTR_MATRIX_1)

	movei	#SIZE_UINT32*3,PTR_INDEX
	store	TEMP1,(PTR_INDEX+PTR_MATRIX_1)

	;; Row 1
	movei	#SIZE_UINT32*4,PTR_INDEX
	store	TEMP1,(PTR_INDEX+PTR_MATRIX_1)

	movei	#SIZE_UINT32*5,PTR_INDEX
	store	TEMP2,(PTR_INDEX+PTR_MATRIX_1)

	movei	#SIZE_UINT32*6,PTR_INDEX
	store	TEMP1,(PTR_INDEX+PTR_MATRIX_1)

	movei	#SIZE_UINT32*7,PTR_INDEX
	store	TEMP1,(PTR_INDEX+PTR_MATRIX_1)

	;; Row 2
	movei	#SIZE_UINT32*8,PTR_INDEX
	store	TEMP1,(PTR_INDEX+PTR_MATRIX_1)

	movei	#SIZE_UINT32*9,PTR_INDEX
	store	TEMP1,(PTR_INDEX+PTR_MATRIX_1)

	movei	#SIZE_UINT32*10,PTR_INDEX
	store	TEMP2,(PTR_INDEX+PTR_MATRIX_1)

	movei	#SIZE_UINT32*11,PTR_INDEX
	store	TEMP1,(PTR_INDEX+PTR_MATRIX_1)
	
	;; Row 3
	movei	#SIZE_UINT32*12,PTR_INDEX
	store	TEMP1,(PTR_INDEX+PTR_MATRIX_1)

	movei	#SIZE_UINT32*13,PTR_INDEX
	store	TEMP1,(PTR_INDEX+PTR_MATRIX_1)

	movei	#SIZE_UINT32*14,PTR_INDEX
	store	TEMP1,(PTR_INDEX+PTR_MATRIX_1)

	movei	#SIZE_UINT32*15,PTR_INDEX
	store	TEMP2,(PTR_INDEX+PTR_MATRIX_1)
	
	StopDSP
	nop

	.68000
_dsp_matrix_identity_set_end::

;;; Add the matrices in operand_1 and operand_2, store the result
	.phrase
_dsp_matrix_add::
	movei	#0,LOOPCOUNTER
	movei	#16,LOOPEND
	movei	#.addition_loop,JUMPADDR
	
	movei	#_dsp_matrix_operand_1,PTR_MATRIX_1
	movei	#_dsp_matrix_operand_2,PTR_MATRIX_2
	movei	#_dsp_matrix_result,PTR_MATRIX_R

	movei	#SIZE_UINT32*0,PTR_INDEX

.addition_loop:
	load	(PTR_INDEX+PTR_MATRIX_1),TEMP1
	load	(PTR_INDEX+PTR_MATRIX_2),TEMP2
	add	TEMP1,TEMP2
	store	TEMP2,(PTR_INDEX+PTR_MATRIX_R)

	addq	#SIZE_UINT32,PTR_INDEX

	cmpq	#15,LOOPCOUNTER
	jr	ne,.addition_loop ;if LOOPCOUNTER < 15, loop.
	addq	#1,LOOPCOUNTER
	
	StopDSP
	nop

	.68000
_dsp_matrix_add_end::

	.phrase
_dsp_matrix_sub::
	movei	#0,LOOPCOUNTER
	movei	#16,LOOPEND
	movei	#.subtraction_loop,JUMPADDR
	
	movei	#_dsp_matrix_operand_1,PTR_MATRIX_1
	movei	#_dsp_matrix_operand_2,PTR_MATRIX_2
	movei	#_dsp_matrix_result,PTR_MATRIX_R

	movei	#SIZE_UINT32*0,PTR_INDEX

.subtraction_loop:
	load	(PTR_INDEX+PTR_MATRIX_1),TEMP1
	load	(PTR_INDEX+PTR_MATRIX_2),TEMP2
	sub	TEMP2,TEMP1
	store	TEMP1,(PTR_INDEX+PTR_MATRIX_R)

	addq	#SIZE_UINT32,PTR_INDEX

	cmpq	#15,LOOPCOUNTER
	jr	ne,.subtraction_loop ;if LOOPCOUNTER < 15, loop.
	addq	#1,LOOPCOUNTER
	
	StopDSP
	nop

	.68000
_dsp_matrix_sub_end::

_dsp_matrix_functions_end::
	
	.long
_dsp_matrix_operand_1::	dcb.l	16,$AA55AA55
_dsp_matrix_operand_2:: dcb.l	16,$AA55AA55
_dsp_matrix_result::	dcb.l	16,$AA55AA55

	.68000

