#include "hello.h"

extern uint16_t bee_pal[16];

op_stop_object *make_stopobj() {	
	op_stop_object *stopobj = calloc(1,sizeof(op_stop_object));
	stopobj->type = STOPOBJ;
	stopobj->int_flag = 1;
	return stopobj;
}

uint16_t jag_custom_interrupt_handler()
{
	if (*INT1&C_VIDENA)
	{
		/* The height field needs to be reset each frame for each mobj. Thanks Atari. */
		mobj_bee->graphic->p0.height = 32;
		mobj_bee_2->graphic->p0.height = 32;
		mobj_bee_3->graphic->p0.height = 32;
		mobj_bee_4->graphic->p0.height = 32;
		mobj_bee_5->graphic->p0.height = 32;
		
		mobj_logo.graphic->p0.height = 200;
	}
	return 0;
}

void gpu_create_scanline_table()
{
	//printf("gpu_create_scanline_table()\n");	
	jag_gpu_load(G_RAM, create_scanline_table, create_scanline_table_end-create_scanline_table);
	jag_gpu_go((uint32_t *)G_RAM, 0);
}

void gpu_draw_horizontal_line(uint32_t x1, uint32_t x2, uint32_t y, uint32_t color)
{
	//printf("gpu_draw_horizontal_line()\n");
	line_x1_value = x1;
	line_x2_value = x2;
	line_y_value = y;
	line_clut_color = color;
	jag_gpu_load(G_RAM, draw_something, draw_something_end-draw_something);
	jag_gpu_go((uint32_t *)G_RAM, 0);
	jag_gpu_wait();
}

int main() {
	//Kick off these calculations while setting up the CPU
	gpu_create_scanline_table();
	
	//Clear screen
	jag_memset32(jag_vidmem, 1, (320*200)/4, 0);
	
	srand(time(NULL));
	
	for(int i=0;i<16;i++){
		jag_set_indexed_color(i, bee_pal[i]);
	}

	/* STOP object ends the object list */
	op_stop_object *stopobj = make_stopobj();

	
	/* Bee */
	mobj_bee_5 = MOBJ_Bee_Create((16+rand())%320, (64+(rand()%200)), stopobj);
	mobj_bee_4 = MOBJ_Bee_Create((16+rand())%320, (64+(rand()%200)), mobj_bee_5->graphic);
	mobj_bee_3 = MOBJ_Bee_Create((16+rand())%320, (64+(rand()%200)), mobj_bee_4->graphic);
	mobj_bee_2 = MOBJ_Bee_Create((16+rand())%320, (64+(rand()%200)), mobj_bee_3->graphic);
	mobj_bee   = MOBJ_Bee_Create(100, 100, mobj_bee_2->graphic);
	
	/* Logo */
	{
		mobj_logo.graphic = calloc(1,sizeof(op_bmp_object));
		mobj_logo.objType = BITOBJ;
		mobj_logo.position.x = 120;
		mobj_logo.position.y = 0;
		mobj_logo.pxWidth = 200;
		mobj_logo.pxHeight = 200;
		
		mobj_logo.animations = AnimationFrame_Create(NULL, 5, beelogo);
		mobj_logo.animations->next = mobj_logo.animations;
		mobj_logo.currentAnimation = mobj_logo.animations;
		
		mobj_logo.graphic->p0.type	= mobj_logo.objType;			/* BITOBJ = bitmap object */
		mobj_logo.graphic->p0.ypos	= mobj_logo.position.y;		/* YPOS = Y position on screen "in half-lines" */
		mobj_logo.graphic->p0.height= mobj_logo.pxHeight;		/* in pixels */
		mobj_logo.graphic->p0.link	= (uint32_t)mobj_bee->graphic >> 3;	/* link to next object */
		mobj_logo.graphic->p0.data	= (uint32_t)mobj_logo.currentAnimation->pixel_data >> 3;	/* ptr to pixel data */
		mobj_logo.graphic->p1.xpos	= mobj_logo.position.x;		/* X position on screen, -2048 to 2047 */
		mobj_logo.graphic->p1.depth	= O_DEPTH16 >> 12;			/* pixel depth of object */
		mobj_logo.graphic->p1.pitch	= 1;						/* 8 * PITCH is added to each fetch */
		mobj_logo.graphic->p1.dwidth= mobj_logo.pxWidth / 4;	/* pixel data width in 8-byte phrases */
		mobj_logo.graphic->p1.iwidth= mobj_logo.pxWidth / 4;	/* image width in 8-byte phrases, for clipping */
																/* these are divided by 2 because 4bpp = 2 phrases per line */	
		mobj_logo.graphic->p1.release= 0;						/* bus mastering, set to 1 when low-depth */
		mobj_logo.graphic->p1.trans	= 0;						/* makes color 0 transparent */
	}
	
	//Start the list here.
	jag_append_olp(mobj_bee->graphic);
		
	//GPU stuff
	jag_memset32(jag_vidmem, 1, (SCREEN_WIDTH*SCREEN_HEIGHT)/4, FILL_LONG_WITH_BYTE(COLOR_SKYBLUE));
	
	//Color 16: Blue sky
	jag_set_indexed_color(16, toRgb16(0, 0, 127));
	for(int i=0;i<32;i++)
	{
		//Colors 32-63: Green gradient
		jag_set_indexed_color(32+i, toRgb16(0, (8*i - 1), 0));
	}
	
	jag_gpu_wait(); //Make sure the GPU is done before starting to draw the scene.
	for(int i=0;i<32;i++){
		gpu_draw_horizontal_line(0, 319, 168+i, 32+i);
	}
	
	uint32_t stick0, stick0_lastread;
	
	uint16_t framecounter = 0;
	
	while(true) {		
		jag_wait_vbl();
		framecounter = (framecounter + 1) % 60;
		
		/* update the bee position */
		mobj_bee->graphic->p0.ypos = mobj_bee->position.y;
		mobj_bee->graphic->p1.xpos = mobj_bee->position.x;
		
		//Animate the bee mobj */
		if((framecounter % mobj_bee->currentAnimation->framecounter_mod) == 0)
		{
			mobj_bee->currentAnimation = mobj_bee->currentAnimation->next;
			mobj_bee_2->currentAnimation = mobj_bee_2->currentAnimation->next;
			mobj_bee_3->currentAnimation = mobj_bee_3->currentAnimation->next;
			mobj_bee_4->currentAnimation = mobj_bee_4->currentAnimation->next;
			mobj_bee_5->currentAnimation = mobj_bee_5->currentAnimation->next;
		}
		
		mobj_bee->graphic->p0.data 		= (uint32_t)mobj_bee->currentAnimation->pixel_data >> 3;
		mobj_bee_2->graphic->p0.data 	= (uint32_t)mobj_bee_2->currentAnimation->pixel_data >> 3;
		mobj_bee_3->graphic->p0.data 	= (uint32_t)mobj_bee_3->currentAnimation->pixel_data >> 3;
		mobj_bee_4->graphic->p0.data 	= (uint32_t)mobj_bee_4->currentAnimation->pixel_data >> 3;
		mobj_bee_5->graphic->p0.data 	= (uint32_t)mobj_bee_5->currentAnimation->pixel_data >> 3;
		
		mobj_logo.graphic->p0.data	= (uint32_t)mobj_logo.currentAnimation->pixel_data >> 3;
		
		/* Triggers once per frame these are pressed */
		if(stick0_lastread & STICK_UP) {
			mobj_bee->position.y -= 2;
		}
		if(stick0_lastread & STICK_DOWN) {
			mobj_bee->position.y += 2;
		}
		if(stick0_lastread & STICK_LEFT) {
			if(mobj_bee->graphic->p1.reflect == 1){
				mobj_bee->position.x -= 16;
			}		
			mobj_bee->graphic->p1.reflect = 0;			
			mobj_bee->position.x--;
		}
		if(stick0_lastread & STICK_RIGHT) {
			if(mobj_bee->graphic->p1.reflect == 0) {
				mobj_bee->position.x += 16;
			}
			mobj_bee->graphic->p1.reflect = 1;
			mobj_bee->position.x++;
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
		
		MOBJ_Print_Position(mobj_bee->position);
	}
}
