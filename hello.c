/* Note: All malloc() objects or anything on the heap is phrase-aligned.
   Objects on the stack are word-aligned. */

#include "hello.h"

#include "fixed.h"

#define VECTOR3FX_CREATE(a,b,c) (Vector3FX){ .x = INT_TO_FIXED(a), .y = INT_TO_FIXED(b), .z = INT_TO_FIXED(c) };

typedef struct shape_t {
  Vector3FX translation, rotation, scale;
  Vector3FX *vertexes;
} Shape;

extern uint16_t bee_pal[16];

op_stop_object *make_stopobj() {	
  op_stop_object *stopobj = calloc(1,sizeof(op_stop_object));
  stopobj->type = STOPOBJ;
  stopobj->int_flag = 1;
  return stopobj;
}

bool vbl_flag = false;

uint16_t jag_custom_interrupt_handler()
{
  if (*INT1&C_VIDENA)
    {      
      //The height field needs to be reset each frame for each mobj. Thanks Atari.
      mobj_bee->graphic->p0.height = 32;
      mobj_buttbot.graphic->p0.height = 32;
      mobj_background.graphic->p0.height = 200;
      mobj_font.graphic->p0.height = 128;

      mobj_bee->graphic->p0.data   = (uint32_t)mobj_bee->currentAnimation->pixel_data >> 3;	  
      mobj_buttbot.graphic->p0.data = (uint32_t)mobj_buttbot.currentAnimation->pixel_data >> 3;
      mobj_background.graphic->p0.data = (uint32_t)front_buffer >> 3;
      mobj_font.graphic->p0.data = (uint32_t)atarifont >> 3;

      MMIO16(INT2) = 0;
      return C_VIDCLR;
    }
  return 0;
}

/* Font blitting */
void BLIT_8x8_font_glyph(uint8_t *destination, uint8_t x, uint8_t y, uint8_t *source, uint8_t c)
{
  //Blit a glyph from an 8x8 font sheet.
  //A sheet is 128x128px = 16x16 glyphs.

  MMIO32(A1_BASE)   = (long)destination;
  MMIO32(A1_PIXEL)  = BLIT_XY(x, y);
  MMIO32(A1_FPIXEL) = 0;
  MMIO32(A1_INC)    = BLIT_XY(1, 0);
  MMIO32(A1_FINC)   = 0;
  MMIO32(A1_FLAGS)  = PITCH1 | PIXEL1 | WID320 | XADDPIX | YADD0;
  MMIO32(A1_STEP)   = BLIT_XY(128-8, 0);

  MMIO32(A2_BASE)   = (long)source;
  MMIO32(A2_PIXEL)  = BLIT_XY(0, 0);
  MMIO32(A2_STEP)   = BLIT_XY(0, 1);
  MMIO32(A2_FLAGS)  = PITCH1 | PIXEL1 | WID320 | XADDPIX | YADD0;
  
  MMIO32(B_COUNT)   = BLIT_XY(8, 8);
  MMIO32(B_CMD)     = SRCEN | UPDA1 | LFU_REPLACE;
}

void gpu_create_scanline_table()
{	
  jag_gpu_load(G_RAM, create_scanline_table, create_scanline_table_end-create_scanline_table);
  jag_gpu_go((uint32_t *)G_RAM, 0);
}

void clear_video_buffer(uint8_t *buffer){
  BLIT_rectangle_solid(buffer, 0, 0, 320, 200, 0);
}

void gpu_blit_line(uint32_t x1, uint32_t y1, uint32_t x2, uint32_t y2, uint32_t color)
{
  jag_gpu_wait(); //wait for any operations in progress to finish
  
  line_x1_value = x1;
  line_x2_value = x2;
  line_y1_value = y1;
  line_y2_value = y2;
  line_clut_color = color;

  jag_wait_blitter_ready();
  jag_gpu_load(G_RAM, blit_line, blit_line_end-blit_line);
  jag_gpu_go((uint32_t *)G_RAM, 0);
}

int main() {
  jag_console_hide();
  front_buffer = background_frame_0;
  back_buffer = background_frame_1;
  
  DSP_LOAD_MATRIX_PROGRAM();
  
  //Kick off these calculations while setting up the CPU
  gpu_create_scanline_table();

  //Create the square thingy
  Shape square;
  square.translation = (Vector3FX){ .x = INT_TO_FIXED(160), .y = INT_TO_FIXED(100), .z = INT_TO_FIXED(0) };
  square.rotation    = (Vector3FX){ .x = INT_TO_FIXED(0), .y = INT_TO_FIXED(0), .z = INT_TO_FIXED(45) };
  square.scale       = (Vector3FX){ .x = INT_TO_FIXED(1), .y = INT_TO_FIXED(1), .z = INT_TO_FIXED(1) };

  Vector3FX vertexList[4];
  vertexList[0] = VECTOR3FX_CREATE(-50, -50, 0);
  vertexList[1] = VECTOR3FX_CREATE( 50, -50, 0);
  vertexList[2] = VECTOR3FX_CREATE( 50,  50, 0);
  vertexList[3] = VECTOR3FX_CREATE(-50,  50, 0);
  square.vertexes = vertexList;
  
  //Set up the palette for the bee
  for(int i=0;i<16;i++){
    jag_set_indexed_color(i, bee_pal[i]);
  } 

  for(int i=0;i<9;i++){
    jag_set_indexed_color(128+i, buttbot_pal[i]);
  }

  /* STOP object ends the object list */
  op_stop_object *stopobj = make_stopobj();
  
  /* Font bitmap thingy */
  {
    mobj_font.graphic = calloc(1,sizeof(op_bmp_object));
    mobj_font.objType = BITOBJ;
    mobj_font.position.x = 48;
    mobj_font.position.y = 160;
    mobj_font.pxWidth = 128;
    mobj_font.pxHeight = 128;
    
    mobj_font.animations = NULL;
    
    mobj_font.graphic->p0.type	= mobj_font.objType;	       	/* BITOBJ = bitmap object */
    mobj_font.graphic->p0.ypos	= mobj_font.position.y;      /* YPOS = Y position on screen "in half-lines" */
    mobj_font.graphic->p0.height = mobj_font.pxHeight;	/* in pixels */
    mobj_font.graphic->p0.link	= (uint32_t)stopobj >> 3;	/* link to next object */
    mobj_font.graphic->p0.data	= (uint32_t)atarifont >> 3;	/* ptr to pixel data */
    mobj_font.graphic->p1.xpos	= mobj_font.position.x;      /* X position on screen, -2048 to 2047 */
    mobj_font.graphic->p1.depth	= O_DEPTH1 >> 12;		/* pixel depth of object */
    mobj_font.graphic->p1.pitch	= 1;				/* 8 * PITCH is added to each fetch */
    mobj_font.graphic->p1.dwidth= mobj_font.pxWidth / 32;	/* pixel data width in 8-byte phrases */
    mobj_font.graphic->p1.iwidth= mobj_font.pxWidth / 32;	/* image width in 8-byte phrases, for clipping */
    /* these are divided by 2 because bpp = 2 phrases per line */	
    mobj_font.graphic->p1.release= 0;				/* bus mastering, set to 1 when low-depth */
    mobj_font.graphic->p1.trans  = 1;				/* makes color 0 transparent */
    mobj_font.graphic->p1.index  = 0;
  }

   /* Background */
  {
    mobj_background.graphic = calloc(1,sizeof(op_bmp_object));
    mobj_background.objType = BITOBJ;
    mobj_background.position.x = 19;
    mobj_background.position.y = 80;
    mobj_background.pxWidth = 320;
    mobj_background.pxHeight = 200;
    
    mobj_background.graphic->p0.type	= mobj_background.objType;	/* BITOBJ = bitmap object */
    mobj_background.graphic->p0.ypos	= mobj_background.position.y;   /* YPOS = Y position on screen "in half-lines" */
    mobj_background.graphic->p0.height  = mobj_background.pxHeight;	/* in pixels */
    mobj_background.graphic->p0.link	= (uint32_t)mobj_font.graphic >> 3;	/* link to next object */
    mobj_background.graphic->p0.link	= (uint32_t)stopobj >> 3;	/* link to next object */
    mobj_background.graphic->p0.data	= (uint32_t)front_buffer >> 3;	/* ptr to pixel data */
    
    mobj_background.graphic->p1.xpos	= mobj_background.position.x;      /* X position on screen, -2048 to 2047 */
    mobj_background.graphic->p1.depth	= O_DEPTH8 >> 12;		/* pixel depth of object */
    mobj_background.graphic->p1.pitch	= 1;				/* 8 * PITCH is added to each fetch */
    mobj_background.graphic->p1.dwidth  = mobj_background.pxWidth / 8;	/* pixel data width in 8-byte phrases */
    mobj_background.graphic->p1.iwidth  = mobj_background.pxWidth / 8;	/* image width in 8-byte phrases, for clipping */	
    mobj_background.graphic->p1.release= 0;				/* bus mastering, set to 1 when low-depth */
    mobj_background.graphic->p1.trans  = 1;				/* makes color 0 transparent */
    mobj_background.graphic->p1.index  = 0;
  }

  /* Bee */
  mobj_bee   = MOBJ_Bee_Create(100, 100, mobj_buttbot.graphic);
  
  //Start the list here.
  jag_attach_olp(mobj_background.graphic);
  //jag_append_olp(mobj_bee->graphic);
  //jag_append_olp(stopobj);
  
  //Color bars
  jag_set_indexed_color(16, toRgb16(192, 192, 192));
  jag_set_indexed_color(17, toRgb16(192, 192, 0));
  jag_set_indexed_color(18, toRgb16(0, 192, 192));
  jag_set_indexed_color(19, toRgb16(0, 192, 0));
  jag_set_indexed_color(20, toRgb16(192, 0, 192));
  jag_set_indexed_color(21, toRgb16(192, 0, 0));
  jag_set_indexed_color(22, toRgb16(0, 0, 192));

  jag_set_indexed_color(23, toRgb16(0, 64, 0));
  
  for(int i=0;i<32;i++)
    {
      //Colors 32-63: Green gradient
      jag_set_indexed_color(32+i, toRgb16(0, (8*i - 1), 0));
    }
		
  uint32_t stick0, stick0_lastread;
  uint16_t framecounter = 0;

  for(int row=0;row<4;row++){
    for(int col=0;col<4;col++){
      dsp_matrix_operand_1.data[row][col] = 0x00010000 * (row + col);
      dsp_matrix_operand_2.data[row][col] = 0x00020000 * (row + col);
    }
  }

  uint32_t framenumber = 0;
  uint8_t colorbar_heights[7] = {200,200,200,200,200,200,200};

  int animation_stage = 0;
  int endDelay = 0;

  Matrix44 m, translation;
  
  Matrix44 *xRotation;
  Matrix44 *yRotation;
  Matrix44 *zRotation;
  
  Vector3FX transformedVertexList[4];

  xRotation = calloc(1, sizeof(Matrix44));
  yRotation = calloc(1, sizeof(Matrix44));
  zRotation = calloc(1, sizeof(Matrix44));

  Matrix44_Translation(square.translation, &translation);
  
  while(true) {

    if(front_buffer == background_frame_0)
      {
	front_buffer = background_frame_1;
	back_buffer  = background_frame_0;
      }
    else
      {
	front_buffer = background_frame_0;
	back_buffer  = background_frame_1;
      }
    
    jag_wait_vbl();
    clear_video_buffer(back_buffer);

    /* Buffer is now clear. */
    
    framecounter = (framecounter + 1) % 60;
    framenumber++;
	  
    /* update the bee position */
    mobj_bee->graphic->p0.ypos = mobj_bee->position.y;
    mobj_bee->graphic->p1.xpos = mobj_bee->position.x;
	  
    //Animate the bee mobj */
    if((framecounter % mobj_bee->currentAnimation->framecounter_mod) == 0)
      {
	mobj_bee->currentAnimation = mobj_bee->currentAnimation->next;
      }
	  
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
    
    //Color bar animation.
    /*
    if(colorbar_heights[0] > 0) {
      BLIT_rectangle_solid(jag_vidmem, 10, 0, 40, colorbar_heights[0], 16);
      colorbar_heights[0] -= 1;
    }

    if(animation_stage == 0){
      for(int i=1; i<7; i++)
	{
	  if(colorbar_heights[i] > 0) {
	    BLIT_rectangle_solid(jag_vidmem, (i*40) + 10, 0, 40, colorbar_heights[i], 16+i);
	  }

	  if(colorbar_heights[i-1] < 160 && (colorbar_heights[i] > 0))
	    colorbar_heights[i] -= 1;
	}

      if(colorbar_heights[6] == 0) {
	animation_stage = 1;
      }
    }
    */

    /* Stage 1: The buttbot moves */
    if(animation_stage == 1){

      if(mobj_buttbot.position.x != 140) {
	mobj_buttbot.position.x += 1;

	if((mobj_buttbot.position.x % 20) == 0) {
	  mobj_buttbot.position.y += 2;
	}
	else if((mobj_buttbot.position.x % 20) == 1) {
	  mobj_buttbot.position.y -= 2;
	}
      }
	
      mobj_buttbot.graphic->p0.ypos = mobj_buttbot.position.y;
      mobj_buttbot.graphic->p1.xpos = mobj_buttbot.position.x;
    }

    if(mobj_buttbot.position.x > 80 && mobj_bee->position.y < 360) {
      mobj_bee->position.y += 6;
      mobj_bee->position.x += 2;
    }

    /* 3D */
    square.rotation.x = (square.rotation.x + 0x00010000) % 0x01680000;
    square.rotation.y = (square.rotation.y + 0x00010000) % 0x01680000;
    square.rotation.z = (square.rotation.z + 0x00010000) % 0x01680000;
    
    Matrix44_Z_Rotation(square.rotation, zRotation);
    Matrix44_Y_Rotation(square.rotation, yRotation);
    Matrix44_X_Rotation(square.rotation, xRotation);

    Matrix44_Identity(&m);
    Matrix44_Multiply_Matrix44(&m, &translation, &m);
    Matrix44_Multiply_Matrix44(&m, zRotation, &m);
    Matrix44_Multiply_Matrix44(&m, yRotation, &m);
    Matrix44_Multiply_Matrix44(&m, xRotation, &m);
  
    for(int i=0;i<4;i++){
      Matrix44_VectorProduct(&m, &vertexList[i], &transformedVertexList[i]);
    }

    gpu_blit_line(transformedVertexList[0].x, transformedVertexList[0].y, transformedVertexList[1].x, transformedVertexList[1].y, 16);
    jag_gpu_wait();
    gpu_blit_line(transformedVertexList[1].x, transformedVertexList[1].y, transformedVertexList[2].x, transformedVertexList[2].y, 17);
    jag_gpu_wait();
    gpu_blit_line(transformedVertexList[2].x, transformedVertexList[2].y, transformedVertexList[3].x, transformedVertexList[3].y, 18);
    jag_gpu_wait();
    gpu_blit_line(transformedVertexList[3].x, transformedVertexList[3].y, transformedVertexList[0].x, transformedVertexList[0].y, 19);
    
    //MOBJ_Print_Position(mobj_bee);
  }
}

