#include <jaglib.h>
#include <jagcore.h>

#include <stdlib.h>
#include <stdio.h>
#include <stdbool.h>
#include <string.h>
#include <time.h>

#include "dsp.h"
#include "shared.h"

#include "tetris.h"
#include "matrix.h"
#include "blit.h"
#include "images.h"
#include "mobj.h"

#define FILL_LONG_WITH_BYTE(b) (b<<24 | b<<16 | b<<8 | b)

const uint8_t COLOR_SKYBLUE = 16;

//Line drawing with the CPU and blitter
extern uint16_t Line_X1;
extern uint16_t Line_X2;
extern uint16_t Line_Y1;
extern uint16_t Line_Y2;
extern void CPU_Draw_Line();

//GPU programs
extern uint8_t blank_screen[];
extern uint8_t blank_screen_end[];

extern uint8_t create_scanline_table[];
extern uint8_t create_scanline_table_end[];

void gpu_blit_line(uint32_t x1, uint32_t x2, uint32_t y1, uint32_t y2, uint32_t color);
extern uint8_t blit_line[];
extern uint8_t blit_line_end[];

uint32_t line_x1_value;
uint32_t line_x2_value;
uint32_t line_y1_value;
uint32_t line_y2_value;
uint32_t line_clut_color;

//Filled in by the GPU. Each entry is the pixel offset of the scanline N.
uint32_t scanline_offset_table[200];

MotionObject *mobj_bee;

MotionObject mobj_logo;
MotionObject mobj_buttbot;
