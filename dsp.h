#ifndef DSP_H
#define DSP_H

#include <jagcore.h>
#include <jaglib.h>

#include <stdlib.h>
#include <stdio.h>
#include <stdbool.h>
#include <string.h>
#include <time.h>

#include "shared.h"
#include "fixed.h"

void DSP_LOAD_MATRIX_PROGRAM();
void DSP_START(uint8_t *function);

/**************************
 * Matrix stuff
 **************************/
typedef struct matrix44_t Matrix44;

/* Matrix functions */
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

/* Matrix operand storage */
extern Matrix44 dsp_matrix_operand_1;
extern Matrix44 dsp_matrix_operand_2;
extern Matrix44 dsp_matrix_result;
extern Vector3FX dsp_matrix_vector;

/* Vector operand storage */
extern Vector3FX dsp_vector_operand_1;
extern Vector3FX dsp_vector_operand_2;
extern Vector3FX dsp_vector_result;

#endif