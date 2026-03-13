@echo off
rem - VIC-20 Unit Tests - Copyright 2026 Fabio Carignano ---------------------

echo ** Building StarWanderer for VIC-20 5K **
cd src
make DEBUG=1
cd ..
pause

rem --------------------------------------------------------------------------
