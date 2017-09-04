#include "hello.h"

extern uint16_t bee_pal[16];

uint16_t jag_custom_interrupt_handler()
{
	if (*INT1&C_VIDENA)
	{
		/* The height field needs to be reset each frame for each mobj. Thanks Atari. */
		MotionObject *head = motionObjects;
		MotionObject *node = head;
		
		while(node != NULL) {
			node->graphic->p0.height = node->pxHeight;			
			node = node->next;
		}
	}
	return 0;
}

int main() {
	//Clear screen
	jag_memset32(jag_vidmem, 1, (320*200)/4, 0);
	
	for(int i=0;i<16;i++){
		jag_set_indexed_color(i, bee_pal[i]);
	}

	/* STOP object ends the object list */
	op_stop_object *stopobj=calloc(1,sizeof(op_stop_object));
	stopobj->type = STOPOBJ;
	stopobj->int_flag = 1;
	
	/* Set up the bee */
	mobj_bee.graphic = calloc(1,sizeof(op_bmp_object));
	mobj_bee.objType = BITOBJ;
	mobj_bee.position.x = 88;
	mobj_bee.position.y = 100;
	mobj_bee.pxWidth = 32;
	mobj_bee.pxHeight = 32;
	
	/* Set up the bee's animations */
	mobj_bee.animations = AnimationFrame_Create(NULL, 5, bee_frame1);
	mobj_bee.animations->next = AnimationFrame_Create(mobj_bee.animations, 5, bee_frame2); //loop
	mobj_bee.currentAnimation = mobj_bee.animations;
	
	/* Object must be on a 16-byte boundary */
	/* See page 18 of the technical reference for field definitions */
	mobj_bee.graphic->p0.type 	= mobj_bee.objType;			/* BITOBJ = bitmap object */
	mobj_bee.graphic->p0.ypos 	= mobj_bee.position.y;		/* YPOS = Y position on screen "in half-lines" */
	mobj_bee.graphic->p0.height = mobj_bee.pxHeight;		/* in pixels */
	mobj_bee.graphic->p0.link 	= (uint32_t)stopobj >> 3;	/* link to next object, in this case a STOP */
	mobj_bee.graphic->p0.data 	= (uint32_t)mobj_bee.animations->pixel_data >> 3;	/* ptr to pixel data */
	mobj_bee.graphic->p1.xpos 	= mobj_bee.position.x;		/* X position on screen, -2048 to 2047 */
	mobj_bee.graphic->p1.depth 	= O_DEPTH4 >> 12;			/* pixel depth of object */
	mobj_bee.graphic->p1.pitch 	= 1;						/* 8 * PITCH is added to each fetch */
	mobj_bee.graphic->p1.dwidth = mobj_bee.pxWidth / 2 / 8;	/* pixel data width in 8-byte phrases */
	mobj_bee.graphic->p1.iwidth = mobj_bee.pxWidth / 2 / 8;	/* image width in 8-byte phrases, for clipping */
															/* these are divided by 2 because 4bpp = 2 phrases per line */	
	mobj_bee.graphic->p1.release= 1;						/* bus mastering, set to 1 when low-depth */
	mobj_bee.graphic->p1.trans	= 1;						/* makes color 0 transparent */
	mobj_bee.graphic->p1.index	= 0;						/* for a 4bpp object, the offset into the CLUT */

	motionObjects = &mobj_bee; //Make this the head
	jag_append_olp(motionObjects->graphic); //Hmm, now we have two lists. This isn't ideal.

	printf("jag_gpu_load: create_scanline_table\n");	
	jag_gpu_load(G_RAM, create_scanline_table, create_scanline_table_end-create_scanline_table);
	printf("jag_gpu_go\n");
	jag_gpu_go((uint32_t *)G_RAM, 0);
	printf("jag_gpu_wait\n");
	jag_gpu_wait();
	printf("gpu stopped\n");

	uint32_t stick0, stick0_lastread;
	
	uint16_t framecounter = 0;
	bool bee_animate_wings = false;
	
	while(true) {		
		jag_wait_vbl();
		framecounter = (framecounter + 1) % 60;
		
		/* update the bee position */
		mobj_bee.graphic->p0.ypos = mobj_bee.position.y;
		mobj_bee.graphic->p1.xpos = mobj_bee.position.x;
		
		//Animate the bee mobj */
		if((framecounter % mobj_bee.currentAnimation->framecounter_mod) == 0)
		{
			mobj_bee.currentAnimation = mobj_bee.currentAnimation->next;
		}
		
		mobj_bee.graphic->p0.data = (uint32_t)mobj_bee.currentAnimation->pixel_data >> 3;
		
		/* Triggers once per frame these are pressed */
		if(stick0_lastread & STICK_UP) {
			mobj_bee.position.y -= 2;
		}
		if(stick0_lastread & STICK_DOWN) {
			mobj_bee.position.y += 2;
		}
		if(stick0_lastread & STICK_LEFT) {
			if(mobj_bee.graphic->p1.reflect == 1){
				mobj_bee.position.x -= 16;
			}		
			mobj_bee.graphic->p1.reflect = 0;			
			mobj_bee.position.x--;
		}
		if(stick0_lastread & STICK_RIGHT) {
			if(mobj_bee.graphic->p1.reflect == 0) {
				mobj_bee.position.x += 16;
			}
			mobj_bee.graphic->p1.reflect = 1;
			mobj_bee.position.x++;
		}
		
		stick0 = jag_read_stick0(STICK_READ_ALL);
		/* Debounced - only triggers once per press */
		switch(stick0 ^ stick0_lastread)
		{
			case STICK_UP:
				//if(~stick0_lastread & STICK_UP) printf("Up\n");
				break;
			case STICK_DOWN:
				//if(~stick0_lastread & STICK_DOWN) printf("Down\n");
				break;
			case STICK_LEFT:
				//if(~stick0_lastread & STICK_LEFT) printf("Left\n");
				break;
			case STICK_RIGHT:
				//if(~stick0_lastread & STICK_RIGHT) printf("Right\n");
				break;
			case STICK_A:
				//if(~stick0_lastread & STICK_A) printf("A\n");
				break;
			case STICK_B:
				//if(~stick0_lastread & STICK_B) printf("B\n");
				break;
			case STICK_C:
				//if(~stick0_lastread & STICK_C) printf("C\n");
				break;
		}
		
		stick0_lastread = stick0;
		
		MOBJ_Print_Position(mobj_bee.position);
	}
}
