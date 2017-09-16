#ifndef BLIT_H
#define BLIT_H

#include <jaglib.h>
#include <jagcore.h>

#include <stdlib.h>
#include <stdio.h>
#include <stdbool.h>
#include <string.h>
#include <time.h>

#include "fixed.h"

#define BLIT_XY(x,y) ( (vuint32_t)( (y << 16) | x ) )
#define MMIO32(x)   (*(vuint32_t *)(x))

#define SWAP(T, a, b) do { T tmp = a; a = b; b = tmp; } while (0)

void BLIT_rectangle_solid(uint8_t *buffer, uint16_t width, uint16_t height, uint16_t color_index);
void BLIT_line(uint8_t *buffer, uint16_t x1, uint16_t y1, uint16_t x2, uint16_t y2, uint16_t color_index);

#endif
