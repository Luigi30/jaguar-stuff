#include "matrix.h"

Matrix44 *dsp_matrix_ptr_m1;
Matrix44 *dsp_matrix_ptr_m2;

Matrix44 *Matrix44_Alloc(){
  return calloc(1, sizeof(Matrix44));
}

void Matrix44_Free(Matrix44 *m){
  free(m); 
}

void Matrix44_Identity(Matrix44 *m){
	jag_dsp_load(D_RAM, dsp_matrix_identity_set, dsp_matrix_identity_set_end-dsp_matrix_identity_set);
	jag_dsp_go((uint32_t *)D_RAM, 0);
	jag_dsp_wait();
	
	memcpy(m, &dsp_matrix_result, sizeof(Matrix44));
}

Matrix44 *Matrix44_Multiply(){
  //TODO: on DSP
  
}
