#ifndef MATRIX_H
#define MATRIX_H

#define DSP_FUNCTION_LOAD(X) jag_dsp_load(D_RAM, X, X ## _end - X );
#define DSP_FUNCTION_GO(X) jag_dsp_go((uint32_t *)X, 0);
#define DSP_FUNCTION_OFFSET(X) ( (uint32_t *)(0xF1B000 + (dsp_matrix_functions_end - X)) )

#include <jagcore.h>
#include <jaglib.h>

#include <string.h>

#include "fixed.h"

typedef struct matrix44_t {
  FIXED_32 data[4][4];
} Matrix44;

//DSP functions under matrix.h's purvew
extern uint8_t dsp_matrix_identity_set[];
extern uint8_t dsp_matrix_identity_set_end[];

extern uint8_t dsp_matrix_functions[];
extern uint8_t dsp_matrix_functions_end[];

extern uint8_t dsp_matrix_add[];
extern uint8_t dsp_matrix_add_end[];

extern uint8_t dsp_matrix_sub[];
extern uint8_t dsp_matrix_sub_end[];

extern Matrix44 *dsp_matrix_ptr_m1;
extern Matrix44 *dsp_matrix_ptr_m2;

extern Matrix44 dsp_matrix_operand_1;
extern Matrix44 dsp_matrix_operand_2;
extern Matrix44 dsp_matrix_result;

//C functions, some of which call DSP functions
Matrix44 *Matrix44_Alloc();
void Matrix44_Free(Matrix44 *m);

void Matrix44_Identity(Matrix44 *m);

extern Matrix44 MATRIX_PRESET_IDENTITY;

#endif
