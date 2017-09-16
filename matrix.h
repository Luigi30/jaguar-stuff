#ifndef MATRIX_H
#define MATRIX_H

#include <jagcore.h>
#include <jaglib.h>

#include "fixed.h"

typedef struct matrix44_t {
  FIXED_32 data[4][4];
} Matrix44;

//DSP functions under matrix.h's purvew
extern uint8_t matrix_identity_set[];
extern uint8_t matrix_identity_set_end[];

extern Matrix44 *dsp_matrix_ptr_m1;
extern Matrix44 *dsp_matrix_ptr_m2;

extern Matrix44 dsp_matrix_local;

//C functions, some of which call DSP functions
Matrix44 *Matrix44_Alloc();
void Matrix44_Free(Matrix44 *m);

void Matrix44_Identity(Matrix44 *m);

extern Matrix44 MATRIX_PRESET_IDENTITY;

#endif
