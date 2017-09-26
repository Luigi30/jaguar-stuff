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

*	.globl	_FIXED_SINE_TABLE 
*	.globl	_FIXED_COSINE_TABLE

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

;;; Zero out the matrix at dsp_matrix_ptr_m1
	.phrase
_dsp_matrix_zero::
	LoadValue _dsp_matrix_ptr_m1,PTR_MATRIX_1

	movei	#0,TEMP1

	movei	#0,LOOPCOUNTER
	movei	#16,LOOPEND
	movei	#.zero_loop,JUMPADDR

	movei	#SIZE_UINT32*0,PTR_INDEX
	
.zero_loop:
	store	TEMP1,(PTR_INDEX+PTR_MATRIX_1)

	addq	#SIZE_UINT32,PTR_INDEX

	cmpq	#15,LOOPCOUNTER
	jr	ne,.zero_loop	;if LOOPCOUNTER < 15, loop.
	addq	#1,LOOPCOUNTER

	StopDSP
	nop

	.68000
_dsp_matrix_zero_end::

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

;;; 4x4 matrix multiplication:
;;;	Multiply the matrix in dsp_matrix_operand_1 by dsp_matrix_operand_2.
;;; 	Store the result in dsp_matrix_result.
	.phrase
_dsp_matrix_multiply::
	;; Zero out the result matrix.
	movei	#_dsp_matrix_operand_1,PTR_MATRIX_1
	movei	#_dsp_matrix_operand_2,PTR_MATRIX_2
	movei	#_dsp_matrix_result,PTR_MATRIX_R
	
.zero:
	movei	#0,TEMP1

	movei	#0,LOOPCOUNTER
	movei	#16,LOOPEND
	movei	#.zero_loop,JUMPADDR

	movei	#SIZE_UINT32*0,PTR_INDEX
	
.zero_loop:
	store	TEMP1,(PTR_INDEX+PTR_MATRIX_R)

	addq	#SIZE_UINT32,PTR_INDEX

	cmpq	#15,LOOPCOUNTER
	jr	ne,.zero_loop	;if LOOPCOUNTER < 15, loop.
	addq	#1,LOOPCOUNTER

;;; Now we can do the multiplication.
.do_multiply:
	rightRow 	.equr r10
	row		.equr r11
	col		.equr r12
	LIMIT		.equr r13

	LEFT_INDEX	.equr r21
	RIGHT_INDEX	.equr r22
	PRODUCT_INDEX	.equr r23

	LEFT		.equr r16
	RIGHT		.equr r17
	PRODUCT		.equr r18

	FOUR		.equr r24
	SIXTEEN		.equr r25
	
	movei	#4,LIMIT
	movei	#0,rightRow
	movei	#0,row
	movei	#0,col
	movei	#0,PTR_INDEX

	movei	#4,FOUR
	movei	#16,SIXTEEN
	
*for(rightRow=0; rightRow<4; rightRow++)
*{
*	for(row=0; row<4; row++)
*	{
*		for(col=0; col<4; col++)
*		{
*			buffer.data[row][rightRow] += left->data[row][col] * right->data[col][rightRow];
*		}
*	}
*}	

.colLoop:
	move	LEFT_INDEX,r14
	move	RIGHT_INDEX,r15
	
	load	(r14+PTR_MATRIX_1),LEFT
	load	(r15+PTR_MATRIX_2),RIGHT
	mult	LEFT,RIGHT	;RIGHT = (uint16_t)LEFT * (uint16_t)RIGHT
	move	RIGHT,PRODUCT
	
	shrq	#16,LEFT
	shrq	#16,RIGHT
	mult	LEFT,RIGHT	;RIGHT = ((uint16_t)LEFT >> 16) * ((uint16_t)RIGHT >> 16)
	shlq	#16,RIGHT
	add	RIGHT,PRODUCT	;PRODUCT = high + low

	move	PRODUCT_INDEX,r14
	store	PRODUCT,(r14+PTR_MATRIX_R)

	addq	#1,col

	add	FOUR,LEFT_INDEX
	add	SIXTEEN,RIGHT_INDEX

	StopDSP
	nop
	.68000
_dsp_matrix_multiply_end::

;;; Rotations.
	.macro	LoadTrigTables
	    movei	_FIXED_SINE_TABLE,TEMP1
	    move	TEMP1,SIN_TABLE

	    movei	_FIXED_COSINE_TABLE,TEMP1
	    move	TEMP1,COS_TABLE
	.endm
	
	PTR_ORIENTATION		.equr	r10
	PTR_MATRIX		.equr	r11
	DEGREES			.equr	r12

	MATRIX_OFFSET		.equr	r14
	TRIG_TABLE_OFFSET	.equr	r15

	FIXED_SIN		.equr	r16
	FIXED_COS		.equr	r17

	SIN_TABLE		.equr	r18
	COS_TABLE		.equr	r19

	SIN_DEGREES		.equr	r20
	COS_DEGREES		.equr	r21

	FIXED_ONE		.equr	r30
	FIXED_ZERO		.equr	r31
	
_dsp_matrix_x_rotation::
	;; Create a rotation matrix for the X axis.
	;; The orientation is in dsp_matrix_vector.
	LoadTrigTables

	movei	#$00010000,FIXED_ONE
	movei	#$00000000,FIXED_ZERO

	movei	#G_HIDATA,r22
	move	FIXED_ZERO,r22
	
	movei	#_dsp_matrix_vector,PTR_ORIENTATION
	movei	#_dsp_matrix_ptr_result,PTR_MATRIX
	load	(PTR_MATRIX),PTR_MATRIX	;dereference the pointer

	load	(PTR_ORIENTATION),DEGREES
	shrq	#16,DEGREES	;take the integer section of the number
	move	DEGREES,TRIG_TABLE_OFFSET
	shlq	#2,TRIG_TABLE_OFFSET ;trig table entries are 4 bytes long

	movei	#$60000,TEMP1
	store	PTR_MATRIX,(TEMP1)

.set_matrix_values:
	store	FIXED_ONE,(PTR_MATRIX) 	;[0][0]
	addq	#4,PTR_MATRIX
	store	FIXED_ZERO,(PTR_MATRIX)	;[0][1]
	addq	#4,PTR_MATRIX
	store	FIXED_ZERO,(PTR_MATRIX)	;[0][2]
	addq	#4,PTR_MATRIX
	store	FIXED_ZERO,(PTR_MATRIX)	;[0][3]

	addq	#4,PTR_MATRIX
	store	FIXED_ZERO,(PTR_MATRIX)	;[1][0]
	addq	#4,PTR_MATRIX
	store	COS_DEGREES,(PTR_MATRIX);[1][1]
	addq	#4,PTR_MATRIX
	store	SIN_DEGREES,(PTR_MATRIX);[1][2]
	addq	#4,PTR_MATRIX
	store	FIXED_ZERO,(PTR_MATRIX) ;[1][3]

	addq	#4,PTR_MATRIX
	store	FIXED_ZERO,(PTR_MATRIX) ;[2][0]
	addq	#4,PTR_MATRIX
	move	SIN_DEGREES,TEMP1
	neg	TEMP1
	store	TEMP1,(PTR_MATRIX) 	;[2][1]
	addq	#4,PTR_MATRIX
	store	COS_DEGREES,(PTR_MATRIX);[2][2]
	addq	#4,PTR_MATRIX
	store	FIXED_ZERO,(PTR_MATRIX)	;[2][3]

	addq	#4,PTR_MATRIX
	store	FIXED_ZERO,(PTR_MATRIX) ;[3][0]
	addq	#4,PTR_MATRIX
	store	FIXED_ZERO,(PTR_MATRIX) ;[3][1]
	addq	#4,PTR_MATRIX
	store	FIXED_ZERO,(PTR_MATRIX) ;[3][2]
	addq	#4,PTR_MATRIX
	store	FIXED_ONE,(PTR_MATRIX) 	;[3][3]

	StopDSP
	nop
	.68000
_dsp_matrix_x_rotation_end::

_dsp_matrix_y_rotation::
	;; Create a rotation matrix for the X axis.
	;; The orientation is in dsp_matrix_vector.
	LoadTrigTables

	movei	#$00010000,FIXED_ONE
	movei	#$00000000,FIXED_ZERO
	
	movei	#_dsp_matrix_vector,PTR_ORIENTATION
	movei	#_dsp_matrix_ptr_result,PTR_MATRIX
	load	(PTR_MATRIX),PTR_MATRIX	;dereference the pointer

	movei	#4,r14
	load	(r14+PTR_ORIENTATION),DEGREES ;get Y value
	shrq	#16,DEGREES	;take the integer section of the number
	move	DEGREES,TRIG_TABLE_OFFSET
	shlq	#2,TRIG_TABLE_OFFSET ;trig table entries are 4 bytes long
	
	load	(TRIG_TABLE_OFFSET+SIN_TABLE),SIN_DEGREES
	load	(TRIG_TABLE_OFFSET+COS_TABLE),COS_DEGREES

.set_matrix_values:
	store	COS_DEGREES,(PTR_MATRIX);[0][0]
	addq	#4,PTR_MATRIX
	store	FIXED_ZERO,(PTR_MATRIX) ;[0][1]
	addq	#4,PTR_MATRIX
	move	SIN_TABLE,TEMP1
	neg	TEMP1
	store	TEMP1,(PTR_MATRIX) 	;[0][2]
	addq	#4,PTR_MATRIX
	store	FIXED_ZERO,(PTR_MATRIX) ;[0][3]

	addq	#4,PTR_MATRIX
	store	FIXED_ZERO,(PTR_MATRIX)	;[1][0]
	addq	#4,PTR_MATRIX
	store	FIXED_ONE,(PTR_MATRIX) 	;[1][1]
	addq	#4,PTR_MATRIX
	store	FIXED_ZERO,(PTR_MATRIX)	;[1][2]
	addq	#4,PTR_MATRIX
	store	FIXED_ZERO,(PTR_MATRIX) ;[1][3]

	addq	#4,PTR_MATRIX
	store	SIN_DEGREES,(PTR_MATRIX);[2][0]
	addq	#4,PTR_MATRIX
	store	FIXED_ZERO,(PTR_MATRIX) ;[2][1]
	addq	#4,PTR_MATRIX
	store	COS_DEGREES,(PTR_MATRIX);[2][2]
	addq	#4,PTR_MATRIX
	store	FIXED_ZERO,(PTR_MATRIX)	;[2][3]

	addq	#4,PTR_MATRIX
	store	FIXED_ZERO,(PTR_MATRIX) ;[3][0]
	addq	#4,PTR_MATRIX
	store	FIXED_ZERO,(PTR_MATRIX) ;[3][1]
	addq	#4,PTR_MATRIX
	store	FIXED_ZERO,(PTR_MATRIX) ;[3][2]
	addq	#4,PTR_MATRIX
	store	FIXED_ONE,(PTR_MATRIX) 	;[3][3]

	StopDSP
	nop
	.68000
_dsp_matrix_y_rotation_end::

_dsp_matrix_z_rotation::
	;; Create a rotation matrix for the X axis.
	;; The orientation is in dsp_matrix_vector.
	LoadTrigTables

	movei	#$00010000,FIXED_ONE
	movei	#$00000000,FIXED_ZERO
	
	movei	#_dsp_matrix_vector,PTR_ORIENTATION
	movei	#_dsp_matrix_ptr_result,PTR_MATRIX
	load	(PTR_MATRIX),PTR_MATRIX	;dereference the pointer

	movei	#8,r14
	load	(r14+PTR_ORIENTATION),DEGREES ;get Y value
	shrq	#16,DEGREES	;take the integer section of the number
	move	DEGREES,TRIG_TABLE_OFFSET
	shlq	#2,TRIG_TABLE_OFFSET ;trig table entries are 4 bytes long
	
	load	(TRIG_TABLE_OFFSET+SIN_TABLE),SIN_DEGREES
	load	(TRIG_TABLE_OFFSET+COS_TABLE),COS_DEGREES

.set_matrix_values:
	store	COS_DEGREES,(PTR_MATRIX);[0][0]
	addq	#4,PTR_MATRIX
	store	SIN_DEGREES,(PTR_MATRIX);[0][1]
	addq	#4,PTR_MATRIX
	store	FIXED_ZERO,(PTR_MATRIX) ;[0][2]
	addq	#4,PTR_MATRIX
	store	FIXED_ZERO,(PTR_MATRIX) ;[0][3]

	addq	#4,PTR_MATRIX
	move	SIN_DEGREES,TEMP1
	neg	TEMP1
	store	TEMP1,(PTR_MATRIX)	;[1][0]
	addq	#4,PTR_MATRIX
	store	COS_DEGREES,(PTR_MATRIX);[1][1]
	addq	#4,PTR_MATRIX
	store	FIXED_ZERO,(PTR_MATRIX) ;[1][2]
	addq	#4,PTR_MATRIX
	store	FIXED_ZERO,(PTR_MATRIX) ;[1][3]

	addq	#4,PTR_MATRIX
	store	FIXED_ZERO,(PTR_MATRIX) ;[2][0]
	addq	#4,PTR_MATRIX
	store	FIXED_ZERO,(PTR_MATRIX) ;[2][1]
	addq	#4,PTR_MATRIX
	store	FIXED_ONE,(PTR_MATRIX) 	;[2][2]
	addq	#4,PTR_MATRIX
	store	FIXED_ZERO,(PTR_MATRIX)	;[2][3]

	addq	#4,PTR_MATRIX
	store	FIXED_ZERO,(PTR_MATRIX) ;[3][0]
	addq	#4,PTR_MATRIX
	store	FIXED_ZERO,(PTR_MATRIX) ;[3][1]
	addq	#4,PTR_MATRIX
	store	FIXED_ZERO,(PTR_MATRIX) ;[3][2]
	addq	#4,PTR_MATRIX
	store	FIXED_ONE,(PTR_MATRIX)	;[3][3]

	StopDSP
	nop
	.68000
_dsp_matrix_z_rotation_end::
	
_dsp_matrix_functions_end::
	
	.long
	;; Operands for matrix functions
_dsp_matrix_operand_1::	dcb.l	16,$AA55AA55 ;operand 1
_dsp_matrix_operand_2:: dcb.l	16,$AA55AA55 ;operand 2
_dsp_matrix_result::	dcb.l	16,$AA55AA55 ;result matrix
_dsp_matrix_vector::	dcb.l	3,$11223344  ;matrix/vector product storage

_dsp_matrix_ptr_result::dcb.l	1            ;pointer to the matrix we want to write the result to

	;; Operands for vector functions
_dsp_vector_operand_1:: dcb.l	3,$11223344 ;vector operand 1
_dsp_vector_operand_2:: dcb.l	3,$11223344 ;vector operand 2
_dsp_vector_result::	dcb.l	3,$11223344 ;vector result
	
	.68000

