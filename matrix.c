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
	for(int row=0;row<4;row++){
		for(int col=0;col<4;col++){
			if(row == col) {
				m->data[row][col] = 0x00010000;	
			}
			else {
				m->data[row][col] = 0;
			}
		}
	}
	
	/*
	DSP_START(dsp_matrix_identity_set);
	jag_dsp_wait();
	
	memcpy(m, &dsp_matrix_result, sizeof(Matrix44));
	*/
	
}

void Matrix44_Multiply_Matrix44(Matrix44 *left, Matrix44 *right, Matrix44 *result)
{	
	jag_dsp_wait();
	memcpy(&dsp_matrix_operand_1, left, sizeof(Matrix44));
	memcpy(&dsp_matrix_operand_2, right, sizeof(Matrix44));
	
	//DSP_START(dsp_matrix_zero_set); //reset the result matrix
	//jag_dsp_wait();
	for(int row=0; row<4; row++)
	{
		for(int col=0; col<4; col++)
		{
			dsp_matrix_result.data[row][col] = 0;	
		}
	}
	
	/* TODO: DSP */
	uint8_t rightRow, row, col;
	
	for(rightRow=0; rightRow<4; rightRow++)
	{
		for(row=0; row<4; row++)
		{
			for(col=0; col<4; col++)
			{
				dsp_matrix_result.data[row][rightRow] += FIXED_MUL(dsp_matrix_operand_1.data[row][col], dsp_matrix_operand_2.data[col][rightRow]);
			}
		}
	}
	
	memcpy(result, &dsp_matrix_result, sizeof(Matrix44));
}

const FIXED_32 ONE_DEGREE = (uint32_t)1143; //1 degree in radians == ~0.0174533 == ~1143/65535
inline FIXED_32 degreesToRadians( FIXED_32 degrees )
{
	return FIXED_MUL(degrees, ONE_DEGREE);
}

void Matrix44_Translation(Vector3FX translation, Matrix44 *result)
{
	jag_gpu_wait();
	
	Matrix44_Identity(result);
	
	result->data[0][3] = translation.x;
	result->data[1][3] = translation.y;
	result->data[2][3] = translation.z;
}

void Matrix44_Z_Rotation(Vector3FX rotation, Matrix44 *result)
{
	uint16_t zDeg = (rotation.z >> 16) % 360;
	
	Matrix44_Identity(result);
	
	result->data[0][0] = FIXED_COSINE_TABLE[zDeg];
	result->data[0][1] = FIXED_SINE_TABLE[zDeg];
	result->data[1][0] = -(FIXED_SINE_TABLE[zDeg]);
	result->data[1][1] = FIXED_COSINE_TABLE[zDeg];
}
	
	
void Matrix44_Rotation(Vector3FX rotation, Matrix44 *result)
{
	FIXED_32 xDeg, yDeg, zDeg;
	xDeg = (rotation.x >> 16) % 360;
	yDeg = (rotation.y >> 16) % 360;
	zDeg = (rotation.z >> 16) % 360;
	
	Matrix44_Identity(result);
	
	/* TODO: DSP */
	result->data[0][0] = FIXED_MUL(FIXED_COSINE_TABLE[yDeg], FIXED_COSINE_TABLE[zDeg]);
	result->data[0][1] = (-(FIXED_MUL(FIXED_COSINE_TABLE[xDeg], FIXED_SINE_TABLE[zDeg]))) + (FIXED_MUL(FIXED_MUL(FIXED_SINE_TABLE[xDeg], FIXED_SINE_TABLE[yDeg]), FIXED_COSINE_TABLE[zDeg]));
	result->data[0][2] = FIXED_MUL(FIXED_SINE_TABLE[xDeg], FIXED_SINE_TABLE[zDeg]) + (FIXED_MUL(FIXED_MUL(FIXED_COSINE_TABLE[xDeg], FIXED_SINE_TABLE[yDeg]), FIXED_COSINE_TABLE[zDeg]));
		
	result->data[1][0] = FIXED_MUL(FIXED_COSINE_TABLE[yDeg], FIXED_SINE_TABLE[zDeg]);
	result->data[1][1] = FIXED_MUL(FIXED_COSINE_TABLE[yDeg], FIXED_COSINE_TABLE[zDeg]) + (FIXED_MUL(FIXED_MUL(FIXED_SINE_TABLE[xDeg], FIXED_SINE_TABLE[yDeg]), FIXED_SINE_TABLE[zDeg]));
	result->data[1][2] = (-(FIXED_MUL(FIXED_SINE_TABLE[xDeg], FIXED_COSINE_TABLE[zDeg]))) + (FIXED_MUL(FIXED_MUL(FIXED_COSINE_TABLE[xDeg], FIXED_SINE_TABLE[yDeg]), FIXED_SINE_TABLE[zDeg]));
	
	result->data[2][0] = -(FIXED_SINE_TABLE[yDeg]);
	result->data[2][1] = FIXED_MUL(FIXED_SINE_TABLE[xDeg],   FIXED_COSINE_TABLE[yDeg]);
	result->data[2][2] = FIXED_MUL(FIXED_COSINE_TABLE[xDeg], FIXED_COSINE_TABLE[yDeg]);
	
	/*
	result->data[0][0] = cos(yRad) * cos(zRad);
	result->data[0][1] = -(cos(xRad) * sin(zRad)) + sin(xRad)*sin(yRad)*cos(zRad);
	result->data[0][2] = (sin(xRad)*sin(zRad)) + cos(xRad)*sin(yRad)*cos(zRad);
	
	result->data[1][0] = cos(yRad)*sin(zRad);
	result->data[1][1] = cos(xRad)*cos(zRad) + sin(xRad)*sin(yRad)*sin(zRad);
	result->data[1][2] = -(sin(xRad)*cos(zRad)) + cos(xRad)*sin(yRad)*sin(zRad);
	
	result->data[2][0] = -sin(yRad);
	result->data[2][1] = sin(xRad) * cos(yRad);
	result->data[2][2] = cos(xRad) * cos(yRad);
	*/
}

void Matrix44_VectorProduct(Matrix44 *matrix, Vector3FX *vector, Vector3FX *destination)
{
	//w = 0 for rotate in space
	//w = 1 for move in space
	
	//const float w = 1;

	destination->x = FIXED_MUL(matrix->data[0][0], vector->x) + FIXED_MUL(matrix->data[0][1], vector->y) + FIXED_MUL(matrix->data[0][2], vector->z) + matrix->data[0][3]; //* w
	destination->y = FIXED_MUL(matrix->data[1][0], vector->x) + FIXED_MUL(matrix->data[1][1], vector->y) + FIXED_MUL(matrix->data[1][2], vector->z) + matrix->data[1][3]; //* w
	destination->z = FIXED_MUL(matrix->data[2][0], vector->x) + FIXED_MUL(matrix->data[2][1], vector->y) + FIXED_MUL(matrix->data[2][2], vector->z) + matrix->data[2][3]; //* w
}
