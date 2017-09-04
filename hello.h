#include <jaglib.h>
#include <jagcore.h>
#include <stdio.h>
#include <stdbool.h>
#include <string.h>

#include "images.h"
#include "mobj.h"

//Images
extern uint8_t blank_screen[];
extern uint8_t blank_screen_end[];

extern uint8_t create_scanline_table[];
extern uint8_t create_scanline_table_end[];

//Filled in by the GPU. Each entry is the pixel offset of the scanline N.
uint16_t scanline_offset_table[200];

MotionObject mobj_bee;