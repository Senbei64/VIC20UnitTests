@echo off
rem - VIC-20 Unit Tests - Copyright 2026 Fabio Carignano ---------------------

echo ** Run Tests for StarWanderer for VIC-20 5K **
start xpet -default -autostartprgmode 1 bin\testphysics.prg
start xpet -default -autostartprgmode 1 bin\testxorshift.prg

rem --------------------------------------------------------------------------
