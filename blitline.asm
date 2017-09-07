	include "jaguar.inc"
	
	xdef	_Line_X1
	xdef	_Line_Y1
	xdef	_Line_X2
	xdef	_Line_Y2
	
	xdef	_CPU_Draw_Line

; COORDONNEES DU SEGMENT;
; SEGMENT COORDINATES;
_Line_X1:        dc.w    50
_Line_Y1:        dc.w    100
_Line_X2:        dc.w    150
_Line_Y2:        dc.w    150

DeltaX:        dc.w    0
DeltaY:        dc.w    0
AbsDeltaX:    dc.w    0
AbsDeltaY:    dc.w    0
SigneDeltaX:    dc.w    0
SigneDeltaY:    dc.w    0
Prec_w:        dc.w    $FFFF
Prec_l:        dc.l    $FFFF
Prec_l_swapped:    dc.l    $FFFF0000
    
_CPU_Draw_Line:    movem.l    d0-d7/a0-a6,-(a7)

    move.l    #0,A1_FSTEP
    move.l    #0,A1_STEP
    move.l    #0,A1_FPIXEL

    move.w    _Line_Y1,d0
    swap    d0
    move.w    _Line_X1,d0
    move.l    d0,A1_PIXEL

    moveq    #0,d0
    move.w    _Line_X2,d0
    sub.w    _Line_X1,d0
    move.w    #1,SigneDeltaX
    move.w    d0,DeltaX
    bpl.s    Positif_deltax
    neg.w    d0
    move.w    #-1,SigneDeltaX
Positif_deltax:
    move.w    d0,AbsDeltaX

    moveq    #0,d0
    move.w    _Line_Y2,d0
    sub.w    _Line_Y1,d0
    move.w    #1,SigneDeltaY
    move.w    d0,DeltaY
    bpl.s    Positif_deltay
    neg.w    d0
    move.w    #-1,SigneDeltaY
Positif_deltay:
    move.w    d0,AbsDeltaY
        
    tst.w    DeltaX
    bne.s    DeltaX_Pas_egal_a_zero_01
    tst.w    DeltaY
    bne.s    DeltaY_Pas_egal_a_zero_01    

    moveq    #1,d0
    swap    d0
    move.w    #1,d0
    move.l    d0,B_COUNT
    move.l    #0,A1_FINC
    jmp        Go_blit

DeltaY_Pas_egal_a_zero_01:

    moveq    #1,d0
    swap    d0
    move.w    AbsDeltaY,d0
    add.w    #1,d0
    move.l    d0,B_COUNT

    move.l    #0,A1_FINC

    moveq    #0,d0
    move.w    SigneDeltaY,d0
    swap    d0
    move.l    d0,A1_INC

    jmp        Go_blit

DeltaX_Pas_egal_a_zero_01:

    tst.w    DeltaY
    bne.s    DeltaY_Pas_egal_a_zero_02    

    moveq    #1,d0
    swap    d0
    move.w    AbsDeltaX,d0
    add.w    #1,d0
    move.l    d0,B_COUNT

    move.l    #0,A1_FINC

    moveq    #0,d0
    move.w    SigneDeltaX,d0
    move.l    d0,A1_INC

    jmp        Go_blit

DeltaY_Pas_egal_a_zero_02:

    move.w    AbsDeltaY,d0
    sub.w    AbsDeltaX,d0
    bne        AbsDeltaY_different_de_AbsDeltaX

    moveq    #1,d0
    swap    d0
    move.w    AbsDeltaX,d0
    add.w    #1,d0
    move.l    d0,B_COUNT

    move.l    #0,A1_FINC

    move.w    SigneDeltaY,d0
    swap    d0
    move.w    SigneDeltaX,d0
    move.l    d0,A1_INC
    
    jmp        Go_blit

AbsDeltaY_different_de_AbsDeltaX:
    tst.w    d0
    bpl        AbsDeltaY_inferieur_a_absdeltax

    moveq    #1,d0
    swap    d0
    move.w    AbsDeltaX,d0
    add.w    #1,d0
    move.l    d0,B_COUNT
    
    move.w    AbsDeltaY,d1
    swap    d1
    move.w    Prec_l,d1
    divu    AbsDeltaX,d1
    and.l    #$FFFF,d1

    tst.w    DeltaY
    bpl.s    DeltaY_positif_03
    neg.l    d1
    move.l    Prec_l_swapped,A1_FPIXEL
DeltaY_positif_03:

    moveq    #0,d0
    move.w    d1,d0
    swap    d0
    move.l    d0,A1_FINC

    move.w    SigneDeltaX,d1
    move.l    d1,A1_INC

    jmp        Go_blit
                
AbsDeltaY_inferieur_a_absdeltax:

    moveq    #1,d0
    swap    d0
    move.w    AbsDeltaY,d0
    add.w    #1,d0
    move.l    d0,B_COUNT

    move.w    AbsDeltaX,d1
    swap.w    d1
    move.w    Prec_l,d1
    divu    AbsDeltaY,d1
    and.l    #$FFFF,d1

    tst.w    DeltaX
    bpl.s    DeltaX_positif_04
    neg.l    d1
    move.l    Prec_l,A1_FPIXEL
DeltaX_positif_04:

    moveq    #0,d0
    move.w    d1,d0
    move.l    d0,A1_FINC

    move.w    SigneDeltaY,d1
    swap    d1
    move.l    d1,A1_INC

Go_blit:
    lea        B_SRCD,a0

    move.l    #-1,(a0)+
    move.l    #-1,(a0)+

    move.l    #_jag_vidmem,A1_BASE
    move.l    #PITCH1|PIXEL16|WID320|XADDINC,A1_FLAGS
    move.l    #UPDA1|UPDA1F|LFU_REPLACE,B_CMD    

    lea        B_CMD,a0
Wait_blitter_end_1:
    move.l    (a0),d0
    btst    #0,d0
    beq.s    Wait_blitter_end_1

Exit_line:    
    movem.l    (a7)+,d0-d7/a0-a6
    rts