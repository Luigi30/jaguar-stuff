#include "mobj.h"

void MOBJ_Print_Position(MOBJ_Position pos) {
	jag_console_set_cursor(0,0);
	printf("X: %4d", pos.x);
	jag_console_set_cursor(0,8);
	printf("Y: %4d", pos.y);
}

MOBJ_Animation_Frame *AnimationFrame_Create(MOBJ_Animation_Frame *_next, uint16_t _framecounter_mod, uint8_t *_pixel_data)
{
	MOBJ_Animation_Frame *frame = calloc(1, sizeof(MOBJ_Animation_Frame));
	
	frame->framecounter_mod = _framecounter_mod;
	frame->pixel_data = _pixel_data;
	frame->next = _next;
	
	return frame;
}

MotionObject *motionObjects;