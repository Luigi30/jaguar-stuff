#ifndef MATRIX_H
#define MATRIX_H

#include <jagcore.h>
#include <jaglib.h>

#include <math.h>
#include <string.h>

#include "dsp.h"
#include "fixed.h"

typedef struct matrix44_t {
  FIXED_32 data[4][4];
} Matrix44;

//C functions, some of which call DSP functions
Matrix44 *Matrix44_Alloc();
void Matrix44_Free(Matrix44 *m);
void Matrix44_Identity(Matrix44 *m);

void Matrix44_Multiply_Matrix44(Matrix44 *left, Matrix44 *right, Matrix44 *result);
void Matrix44_VectorProduct(Matrix44 *matrix, Vector3FX *vector, Vector3FX *destination);

void Matrix44_Translation(Vector3FX translation, Matrix44 *result);
void Matrix44_Rotation(Vector3FX rotation, Matrix44 *result);

void Matrix44_Z_Rotation(Vector3FX rotation, Matrix44 *result);

extern Matrix44 MATRIX_PRESET_IDENTITY;

#endif
