@echo off
setlocal
set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"
set "RSCRIPT_EXE="

echo Starting Tricuspid TEER Living Meta-Analysis update...
for %%I in (Rscript.exe) do set "RSCRIPT_EXE=%%~$PATH:I"
if not defined RSCRIPT_EXE (
  for /d %%D in ("C:\Program Files\R\R-*") do (
    if exist "%%~fD\bin\Rscript.exe" set "RSCRIPT_EXE=%%~fD\bin\Rscript.exe"
    if exist "%%~fD\bin\x64\Rscript.exe" set "RSCRIPT_EXE=%%~fD\bin\x64\Rscript.exe"
  )
)

if not defined RSCRIPT_EXE (
  for /d %%D in ("C:\Program Files\jamovi*") do (
    if exist "%%~fD\Frameworks\R\bin\Rscript.exe" set "RSCRIPT_EXE=%%~fD\Frameworks\R\bin\Rscript.exe"
    if exist "%%~fD\Frameworks\R\bin\x64\Rscript.exe" set "RSCRIPT_EXE=%%~fD\Frameworks\R\bin\x64\Rscript.exe"
  )
)

if defined RSCRIPT_EXE (
    goto run_update
)

if not defined RSCRIPT_EXE (
  echo Rscript was not found on PATH or in common local install locations.
  exit /b 1
)

:run_update
"%RSCRIPT_EXE%" "%SCRIPT_DIR%update_meta_portable.R" "%SCRIPT_DIR%"
if errorlevel 1 (
  echo Update failed.
  exit /b 1
)

echo Update complete.
