:::::::::::::::::::::::::::::::::::::
:: GETMAT ver. beta by gdl-is      ::
:: https://github.com/gdl-is       ::
:: e-mail: gdl.sytes.net@gmail.com ::
:::::::::::::::::::::::::::::::::::::
:
@echo off
setlocal enabledelayedexpansion
:
::::::::::::::::::::::::::
:: prototipo di lancio  ::
:: CORSO <%1> <%2> <%3> ::
::::::::::::::::::::::::::
:
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Significato dei parametri                             ::
:: <%1> -> Identificativo del Corso (AM1_26, PCM_25,...) ::
::         Immettendo ? si ottiene l'elenco dei corsi    ::
:: <%2> -> Numero della prima lezione da prelevare       ::
:: <%3> -> Numero dell'ultima lezione da prelevare       ::
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:
:::::::::::::::::::::::::
:: Controllo CURL  ::
:::::::::::::::::::::::::
:
where curl >nul 2>nul
if %errorlevel% neq 0 (
   echo [ERRORE] curl non trovato.
   echo Assicurati che sia installato o presente nel PATH.
   goto :end
)
:
:::::::::::::::::::::::
:: Controllo FFMPEG  ::
:::::::::::::::::::::::
:
rem Controllo FFMPEG
where ffmpeg >nul 2>nul
if %errorlevel% neq 0 (
   echo [ERRORE] ffmpeg non trovato.
   echo Consulta la guida all'installazione per procedere.
   goto :end
)
:
:::::::::::::::::::::::::
:: Gestione parametri  ::
:::::::::::::::::::::::::
:
: Parametro 1
if "%1"=="?" (
   goto :corsi
)
if "%1"=="" (
   goto :err
) else (
   set "corso=%1"
)
for /f "tokens=2,3,4,5 delims=*" %%a in ('findstr /B /I /C:"%corso%*" "%~dp0corsi.txt"') do (
   set "titolo=%%a"
   set "url_base=%%b"
   set "lezione=%%c"
   set /a "len=%%d"
)
if "!url_base!"=="" (
   goto :err
)
:
: Parametro 2
if "%2"=="" (
   goto :err
)
set /a inizio=%2
:
: Parametro 3
if "%3"=="" (
   set /a fine=%inizio%
) else (
   set /a fine=%3
)
:
: Elaborazione
echo Corso di %titolo%
for /L %%i in (%inizio%,1,%fine%) do (
   set "num=00%%i"
   set "lez=%lezione%!num:~-%len%!"
   set "lez_avi=!lez!.avi"
   set "lez_mp4=!lez!.mp4"

   set /a salta=0
   if not exist "!lez_avi!" (
      if exist "!lez_mp4!" (
         set /a salta=1
      )
   )
   if !salta!==1 (
      echo La lezione !lez! e' gia' presente, salto.
   ) else (
      echo Download di !lez!...
      curl -s -f -o "!lez_avi!" "%url_base%!lez_avi!"
      if errorlevel 1 (
         echo Errore download !lez!
      ) else (
         echo Conversione !lez!...
         ffmpeg.exe -y -hide_banner -loglevel error -stats -avoid_negative_ts make_zero -fflags +genpts+discardcorrupt -i "!lez_avi!" -tune stillimage -c:v libx264 -pix_fmt yuv420p -profile:v main -level 3.1 -crf 20 -preset medium -vf "fps=30,format=yuv420p" -c:a aac -b:a 192k -movflags +faststart "!lez_mp4!"
         if exist "!lez_avi!" del "!lez_avi!"
      )
   )
)
echo Fine del lavoro.
goto :end

:corsi
echo Codici dei corsi disponibili
echo ============================
for /f "tokens=1,2 delims=*" %%a in (corsi.txt) do (
   set "corso=%%a"
   set "titolo=%%b"
   echo !corso!: !titolo!
)

goto :end

:err
echo Parametri errati
goto :end

:end
