#ifndef BLIT_H
#define BLIT_H

#include <jaglib.h>
#include <jagcore.h>

#include <stdlib.h>
#include <stdio.h>
#include <stdbool.h>
#include <string.h>
#include <time.h>

#define BLIT_XY(x,y) ( (vuint32_t)( (y << 16) | x ) )
#define MMIO32(x)   (*(vuint32_t *)(x))

#define SWAP(T, a, b) do { T tmp = a; a = b; b = tmp; } while (0)

/* 
	The blitter uses unsigned 32-bit fixed-point numbers for subpixel precision.
	FIXED_32
		31...16 == integer component
		15...0  == fractional component
*/

typedef uint32_t FIXED_32;
#define FIXED_INT(x)	(uint16_t)( x >> 16 )
#define FIXED_FRAC(x)	(uint16_t)( x & 0xFFFF )

#define INT_TO_FIXED(x)	( (uint32_t)(x << 16) )

FIXED_32 FIXED_ADD(FIXED_32 a, FIXED_32 b);
FIXED_32 FIXED_SUB(FIXED_32 a, FIXED_32 b);
FIXED_32 FIXED_MUL(FIXED_32 a, FIXED_32 b);
FIXED_32 FIXED_DIV(FIXED_32 a, FIXED_32 b);

void BLIT_rectangle_solid(uint8_t *buffer, uint16_t width, uint16_t height, uint16_t color_index);
void BLIT_line(uint8_t *buffer, uint16_t x1, uint16_t y1, uint16_t x2, uint16_t y2, uint16_t color_index);

#endif
