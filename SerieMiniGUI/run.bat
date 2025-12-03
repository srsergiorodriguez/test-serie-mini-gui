@echo off
REM Ensure the current directory is on PATH so our SDL3.dll and MinGW DLLs load first
set PATH=%~dp0;%PATH%
"%~dp0\LuaJIT\luajit.exe" "%~dp0main.lua"