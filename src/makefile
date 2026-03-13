#- VIC-20 Unit Tests - Copyright 2026 Fabio Carignano ------------------------

ifdef DEBUG
	CFLAGS += -DDEBUG=$(DEBUG)
endif

# - BUILD --------------------------------------------------------------------
all: ../bin/starwanderer.prg

# compile code
../obj/input.o: input.s input.inc
	ca65 -t vic20 $(CFLAGS) -o ../obj/input.o input.s
../obj/physics.o: physics.s physics.inc
	ca65 -t vic20 $(CFLAGS) -o ../obj/physics.o physics.s
../obj/xorshift.o: xorshift.s xorshift.inc
	ca65 -t vic20 $(CFLAGS) -o ../obj/xorshift.o xorshift.s
../obj/starwanderer.o: starwanderer.s input.inc physics.inc
	ca65 -t vic20 $(CFLAGS) -o ../obj/starwanderer.o starwanderer.s

# compile unit tests

../obj/physics_ut.o: physics.inc physics.s
	ca65 -t vic20 -DUNIT_TESTS=1 $(CFLAGS) -o ../obj/physics_ut.o physics.s
../bin/testphysics.prg: pet-tests.cfg ../obj/physics_ut.o testphysics.c
	cl65 -t pet -C pet-tests.cfg $(CFLAGS) -o ../bin/testphysics.prg ../obj/physics_ut.o testphysics.c
	-del ..\obj\physics.ok 2> nul

../obj/xorshift_ut.o: xorshift.inc xorshift.s
	ca65 -t vic20 -DUNIT_TESTS=1 $(CFLAGS) -o ../obj/xorshift_ut.o xorshift.s
../bin/testxorshift.prg: pet-tests.cfg ../obj/xorshift_ut.o testxorshift.c
	cl65 -t pet -C pet-tests.cfg $(CFLAGS) -o ../bin/testxorshift.prg ../obj/xorshift_ut.o testxorshift.c
	-del ..\obj\xorshift.ok 2> nul

# run tests
../obj/xorshift.ok: ../bin/testxorshift.prg
	cd .. && cmd /c start xpet -silent -default +drive8truedrive -busdevice8 -warp -autostartprgmode 1 bin\testxorshift.prg
	timeout /t 5 /nobreak
	taskkill /im xpet.exe /f
../obj/physics.ok: ../bin/testphysics.prg
	cd .. && cmd /c start xpet -silent -default +drive8truedrive -busdevice8 -warp -autostartprgmode 1 bin\testphysics.prg
	timeout /t 5 /nobreak
	taskkill /im xpet.exe /f

# link program
../bin/starwanderer.prg: ../obj/physics.ok ../obj/xorshift.ok starwanderer.cfg ../obj/starwanderer.o ../obj/input.o ../obj/physics.o ../obj/xorshift.o
	ld65 -C starwanderer.cfg -o ../bin/starwanderer.prg ../obj/starwanderer.o ../obj/input.o ../obj/physics.o ../obj/xorshift.o

# - CLEAN --------------------------------------------------------------------
clean:
	-del ..\obj\*.o 2> nul
	-del ..\obj\*.ok 2> nul
	-del ..\obj\*.seq 2> nul
	-del ..\bin\*.prg 2> nul

#-----------------------------------------------------------------------------
