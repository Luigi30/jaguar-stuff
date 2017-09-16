#include "blit.h"

void BLIT_rectangle_solid(uint8_t *buffer, uint16_t width, uint16_t height, uint16_t color_index)
{
	MMIO32(A1_BASE)		= (long)buffer;
	MMIO32(A1_PIXEL)	= BLIT_XY(0, 0);
	MMIO32(A1_FPIXEL)	= 0;
	MMIO32(A1_INC)		= BLIT_XY(1, 0);
	MMIO32(A1_FINC)		= 0;
	MMIO32(A1_FLAGS)	= PITCH1 | PIXEL8 | WID320 | XADDPIX | YADD0;
	MMIO32(A1_STEP)		= BLIT_XY(CONSOLE_BMP_WIDTH-width, 0);
	MMIO32(B_PATD)		= color_index;
	MMIO32(B_COUNT)		= BLIT_XY(width, height);
	MMIO32(B_CMD)		= PATDSEL | UPDA1 | LFU_S;
}

void BLIT_line(uint8_t *buffer, uint16_t x1, uint16_t y1, uint16_t x2, uint16_t y2, uint16_t color_index)
{	
	if(x1 > x2) //Swap the coordinates so we always go left to right.
	{
		SWAP(uint16_t, x1, x2);
		SWAP(uint16_t, y1, y2);
	}

	uint16_t x_distance = abs(x2-x1);
	uint16_t y_distance = abs(y2-y1);
	bool y_negative;
	
	if((y2 - y1) < 0) {
		y_negative = true;
	} else {
		y_negative = false;
	}
	
	FIXED_32 slope = FIXED_DIV(INT_TO_FIXED(x_distance), INT_TO_FIXED(y_distance));
	
	MMIO32(A1_BASE)		= (long)buffer;
	MMIO32(A1_PIXEL)	= BLIT_XY(x1, y1);
	MMIO32(A1_FPIXEL)	= 0;
	MMIO32(A1_INC)		= BLIT_XY(FIXED_INT(slope), 0);
	MMIO32(A1_FINC)		= BLIT_XY(FIXED_FRAC(slope), 0);
	MMIO32(A1_FLAGS)	= PITCH1 | PIXEL8 | WID320 | XADDINC;
	
	if(y_negative) 
	{
		MMIO32(A1_STEP)	= BLIT_XY(0,-1);
	}
	else
	{
		MMIO32(A1_STEP)	= BLIT_XY(0,1);
	}
	
	MMIO32(B_PATD)		= color_index;
	MMIO32(B_COUNT)		= BLIT_XY(1, y_distance+1);
	MMIO32(B_CMD)		= PATDSEL | UPDA1 | UPDA1F | LFU_S;
}
