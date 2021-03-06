BINFILE = hello.jag

BINPATH = bin/
OBJPATH = obj/

OBJFILES = $(OBJPATH)hello.o $(OBJPATH)tetris.o $(OBJPATH)matrix.o $(OBJPATH)fixed.o $(OBJPATH)dsp_matrix.o $(OBJPATH)blit.o $(OBJPATH)screen.o $(OBJPATH)cube.o $(OBJPATH)mobj.o $(OBJPATH)images.o $(OBJPATH)dsp.o
IMAGES = images/atarifont.s images/atarifont8x8.s

VJAGFOLDER = /cygdrive/e/virtualjaguar/

#Adjust this path to your configuration.
DOCKER = docker run --rm -v c:/jaguar/hello:/usr/src/compile --workdir /usr/src/compile toarnold/jaguarvbcc:0.9f
CC = vc
AS = vasmjagrisc_madmac
JAGINCLUDE = /opt/jagdev/targets/m68k-jaguar/include
CONVERT = tools/converter/converter.exe --target-dir images/ 

.PHONY: clean

all: build

build:	$(IMAGES) $(OBJFILES)
	$(DOCKER) $(CC) -v -O0 +jaguar.cfg -lm -o $(BINPATH)$(BINFILE) $(OBJFILES)

clean:
	-rm obj/*
	-rm bin/*

run:
	#Adjust this path to your configuration.
	$(VJAGFOLDER)virtualjaguar.exe --alpine C:\jaguar\hello\bin\hello.jag

$(OBJPATH)%.o: %.c
	$(DOCKER) $(CC) +jaguar.cfg -c -c99 -o $@ $?

$(OBJPATH)%.o: %.asm
	$(DOCKER) $(CC) +jaguar.cfg -c -c99 -o $@ $?

$(OBJPATH)%.o: %.tom.s
	$(DOCKER) $(AS) $? -I$(JAGINCLUDE) -Fvobj -mgpu -o $@
	
$(OBJPATH)%.o: %.jerry.s
	$(DOCKER) $(AS) $? -I$(JAGINCLUDE) -Fvobj -mdsp -o $@

#Images
images/atarifont.s: images/atarifont.gif
	$(CONVERT) --opt-clut --clut $? 
	
images/atarifont8x8.s: images/atarifont8x8.bmp
	$(CONVERT) --opt-clut --clut $? 

images/bee-wings1.s: images/bee-wings1.png
	$(CONVERT) --opt-clut --clut $?

images/bee-wings2.s: images/bee-wings2.png
	$(CONVERT) --opt-clut --clut $?

images/beelogo.s: images/beelogo.png
	$(CONVERT) -rgb $? 

images/graphic.s: images/graphic.png
	$(CONVERT) --opt-clut --clut $? 

images/buttbot.s: images/buttbot.png
	$(CONVERT) --opt-clut --clut $? 
	
images/butttext.s: images/butttext.bmp
	$(CONVERT) --opt-clut --clut $? 
