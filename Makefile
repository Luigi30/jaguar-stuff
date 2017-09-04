BINFILE = hello.jag

BINPATH = bin/
OBJPATH = obj/

OBJFILES = $(OBJPATH)hello.o $(OBJPATH)screen.o $(OBJPATH)mobj.o $(OBJPATH)images.o
IMAGES = images/bee-wings1.raw images/bee-wings2.raw

VJAGFOLDER = /cygdrive/e/virtualjaguar/

#Adjust this path to your configuration.
DOCKER = docker run --rm -v c:/jaguar/hello:/usr/src/compile --workdir /usr/src/compile toarnold/jaguarvbcc:0.9f
CC = vc
AS = vasmjagrisc_madmac
JAGINCLUDE = /opt/jagdev/targets/m68k-jaguar/include
CONVERT = tools/converter/converter.exe --target-dir images/ --opt-clut --clut

.PHONY: clean

all: build

build:	$(IMAGES) $(OBJFILES)
	$(DOCKER) $(CC) -v +jaguar -o $(BINPATH)$(BINFILE) $(OBJFILES)

clean:
	-rm obj/*
	-rm bin/*

run:
	#Adjust this path to your configuration.
	$(VJAGFOLDER)virtualjaguar.exe C:\jaguar\hello\bin\hello.jag

$(OBJPATH)%.o: %.c
	$(DOCKER) $(CC) +jaguar -c -c99 -o $@ $?

$(OBJPATH)%.o: %.s
	$(DOCKER) $(AS) $? -I$(JAGINCLUDE) -Fvobj -mgpu -o $@

#Images
images/bee-wings1.raw: images/bee-wings1.png
	$(CONVERT) $?

images/bee-wings2.raw: images/bee-wings2.png
	$(CONVERT) $?
