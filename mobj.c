#include "mobj.h"

//Debugging
void MOBJ_Print_Position(MotionObject *mobj) {
	jag_console_set_cursor(0,0);
	printf("X: %4d", mobj->position.x);
	jag_console_set_cursor(0,8);
	printf("Y: %4d", mobj->position.y);
}

MOBJ_Animation_Frame *AnimationFrame_Create(MOBJ_Animation_Frame *_next, uint16_t _framecounter_mod, uint8_t *_pixel_data)
{
	MOBJ_Animation_Frame *frame = calloc(1, sizeof(MOBJ_Animation_Frame));
	
	frame->framecounter_mod = _framecounter_mod;
	frame->pixel_data = _pixel_data;
	frame->next = _next;
	
	return frame;
}

/* Alloc and free */
MotionObject *MOBJ_Alloc() {
	return calloc(1, sizeof(MotionObject));
}

void MOBJ_Free(MotionObject *mobj) {
	if(mobj != NULL) {
		free(mobj);	
	}
}

MotionObject *MOBJ_Bee_Create(uint16_t x, uint16_t y, void *linkObject)
{
	MotionObject *mobj = MOBJ_Alloc();
	
	mobj->graphic = calloc(1,sizeof(op_bmp_object));
	mobj->objType = BITOBJ;
	mobj->position.x = x;
	mobj->position.y = y;
	mobj->pxWidth = 32;
	mobj->pxHeight = 32;
	
	/* Set up the bee's animations */
	mobj->animations = AnimationFrame_Create(NULL, 5, bee_frame1);
	mobj->animations->next = AnimationFrame_Create(mobj->animations, 5, bee_frame2); //loop
	mobj->currentAnimation = mobj->animations;
	
	/* Object must be on a 16-byte boundary */
	/* See page 18 of the technical reference for field definitions */
	mobj->graphic->p0.type	= mobj->objType;			/* BITOBJ = bitmap object */
	mobj->graphic->p0.ypos	= mobj->position.y;		/* YPOS = Y position on screen "in half-lines" */
	mobj->graphic->p0.height	= mobj->pxHeight;		/* in pixels */
	mobj->graphic->p0.link	= (uint32_t)linkObject >> 3;	/* link to next object */
	mobj->graphic->p0.data	= (uint32_t)mobj->animations->pixel_data >> 3;	/* ptr to pixel data */
	mobj->graphic->p1.xpos	= mobj->position.x;		/* X position on screen, -2048 to 2047 */
	mobj->graphic->p1.depth	= O_DEPTH4 >> 12;			/* pixel depth of object */
	mobj->graphic->p1.pitch	= 1;						/* 8 * PITCH is added to each fetch */
	mobj->graphic->p1.dwidth	= mobj->pxWidth / 2 / 8;	/* pixel data width in 8-byte phrases */
	mobj->graphic->p1.iwidth	= mobj->pxWidth / 2 / 8;	/* image width in 8-byte phrases, for clipping */
															/* these are divided by 2 because 4bpp = 2 phrases per line */	
	mobj->graphic->p1.release= 1;						/* bus mastering, set to 1 when low-depth */
	mobj->graphic->p1.trans	= 1;						/* makes color 0 transparent */
	mobj->graphic->p1.index	= 0;						/* for a 4bpp object, the offset into the CLUT */
	
	return mobj;
}