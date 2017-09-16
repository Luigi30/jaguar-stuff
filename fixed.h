#ifndef FIXED_H
#define FIXED_H

#include <jaglib.h>
#include <jagcore.h>

#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <stdbool.h>

/*                                                                                                                                          
        The blitter uses unsigned 32-bit fixed-point numbers for subpixel precision. No FPU!
	FIXED_32
	31...16 == integer component
	15...0  == fractional component
*/

typedef uint32_t FIXED_32;
#define FIXED_INT(x)    (uint16_t)( x >> 16 )
#define FIXED_FRAC(x)   (uint16_t)( x & 0xFFFF )

#define INT_TO_FIXED(x) ( (uint32_t)(x << 16) )

FIXED_32 FIXED_ADD(FIXED_32 a, FIXED_32 b);
FIXED_32 FIXED_SUB(FIXED_32 a, FIXED_32 b);
FIXED_32 FIXED_MUL(FIXED_32 a, FIXED_32 b);
FIXED_32 FIXED_DIV(FIXED_32 a, FIXED_32 b);

#endif
