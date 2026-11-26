@echo off
rem ----------------------------------------------------------------------------------------------
rem  testar-professor.bat - Executa em 1 clique toda a bateria de testes da rubrica do professor.
rem
rem  Uso:
rem    Clique duplo no arquivo (ou execute no terminal):
rem      testar-professor.bat            -> testa a API, CRUD, validacoes, SQL e entrega
rem      testar-professor.bat --reset    -> recria o banco do zero (down -v + up) e roda tudo
rem      testar-professor.bat --no-pause -> nao pausa ao terminar (uso em scripts/CI)
rem ----------------------------------------------------------------------------------------------
setlocal
cd /d "%~dp0"

set "EXTRA_ARG="
set "SEM_PAUSA=0"

:parse_args
if "%~1"=="" goto run
if /i "%~1"=="--reset" set "EXTRA_ARG=%EXTRA_ARG% -ResetBanco"
if /i "%~1"=="--no-pause" set "SEM_PAUSA=1"
shift
goto parse_args

:run
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0testar-professor.ps1" %EXTRA_ARG%
set "CODIGO=%ERRORLEVEL%"

if "%SEM_PAUSA%"=="0" (
    echo.
    pause
)
exit /b %CODIGO%
