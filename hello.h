#include <jaglib.h>
#include <jagcore.h>

#include <stdlib.h>
#include <stdio.h>
#include <stdbool.h>
#include <string.h>
#include <time.h>

#include "images.h"
#include "mobj.h"

#define SCREEN_WIDTH 320
#define SCREEN_HEIGHT 200

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

void gpu_draw_horizontal_line(uint32_t x1, uint32_t x2, uint32_t y, uint32_t color);
extern uint8_t draw_something[];
extern uint8_t draw_something_end[];

uint32_t line_x1_value;
uint32_t line_x2_value;
uint32_t line_y_value;
uint32_t line_clut_color;

//Filled in by the GPU. Each entry is the pixel offset of the scanline N.
uint32_t scanline_offset_table[200];

MotionObject *mobj_bee;
MotionObject *mobj_bee_2;
MotionObject *mobj_bee_3;
MotionObject *mobj_bee_4;
MotionObject *mobj_bee_5;

MotionObject mobj_logo;