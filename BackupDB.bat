@echo off
setlocal DisableDelayedExpansion

for /F "tokens=1,2 delims=#" %%a in ('"prompt #$H#$E# & echo on & for %%b in (1) do rem"') do (
  set "ESC=%%b"
)

set "C_RESET=%ESC%[0m"
set "C_CYAN=%ESC%[36m"
set "C_GREEN=%ESC%[92m"
set "C_RED=%ESC%[91m"
set "C_YELLOW=%ESC%[93m"
set "C_GREY=%ESC%[90m"
set "C_WHITE=%ESC%[97m"

title LUMINUS SERVER - BACKUP UTILITY

:: ==========================================
:: CONFIGURATION
:: ==========================================
set "MYSQL_PATH=C:\Program Files\MariaDB 12.1\bin\mysqldump.exe"
set "DB_HOST=localhost"
set "DB_USER=root"
set "DB_PASS=070903"
set "DB_NAME=luminus-server"
set "CONFIG_FILE=settings.ini"

if exist "%CONFIG_FILE%" goto :load_config

cls
echo %C_CYAN%============================================================%C_RESET%
echo %C_GREEN%   INITIAL CONFIGURATION%C_RESET%
echo %C_CYAN%============================================================%C_RESET%
echo.
echo %C_WHITE%Please specify the destination directory for your backups.%C_RESET%
echo %C_GREY%Examples:%C_RESET%
echo  %C_GREY%- Relative: .\backupdb%C_RESET%
echo  %C_GREY%- Absolute: C:\Users\yhiro\Documents\LuminuServer\database\backupdb%C_RESET%
echo.

setlocal EnableDelayedExpansion
set /p "input_dir=%C_YELLOW%> Directory path [Default: .\backupdb]: %C_RESET%"
if "!input_dir!"=="" set "input_dir=.\backupdb"
(echo BACKUP_DIR=!input_dir!) > "%CONFIG_FILE%"
endlocal

echo.
echo %C_GREEN%[OK] Configuration saved successfully.%C_RESET%
timeout /t 2 >nul

:load_config
for /f "usebackq tokens=1* delims==" %%a in ("%CONFIG_FILE%") do (
    set "%%a=%%b"
)

if "%BACKUP_DIR%"=="" set "BACKUP_DIR=.\backupdb"

if not exist "%MYSQL_PATH%" (
    cls
    echo %C_RED%============================================================%C_RESET%
    echo %C_RED%   CRITICAL ERROR: EXECUTABLE NOT FOUND%C_RESET%
    echo %C_RED%============================================================%C_RESET%
    echo.
    echo %C_WHITE%File not found at:%C_RESET%
    echo %C_GREY%"%MYSQL_PATH%"%C_RESET%
    echo.
    echo %C_WHITE%Please edit the script and correct the MYSQL_PATH variable.%C_RESET%
    pause
    exit
)

if not exist "%BACKUP_DIR%" mkdir "%BACKUP_DIR%"

set hour=%time:~0,2%
if "%hour:~0,1%" == " " set hour=0%hour:~1,1%
set min=%time:~3,2%
if "%min:~0,1%" == " " set min=0%min:~1,1%
set secs=%time:~6,2%
if "%secs:~0,1%" == " " set secs=0%secs:~1,1%

for /f "tokens=1-4 delims=/-. " %%i in ('date /t') do (call :set_date %%i %%j %%k %%l)
goto :menu

:set_date
if "%1:~0,1%" gtr "9" shift
for /f "skip=1 tokens=2-4 delims=(-)" %%m in ('echo,^|date') do (set %%m=%1&set %%n=%2&set %%o=%3)
goto :eof

:menu
set datetimef=%dd%_%mm%_%yy% %hour%_%min%
cls
echo.
echo %C_CYAN%   LUMINUS SERVER BACKUP UTILITY v2.3%C_RESET%
echo.
echo %C_GREY%   Target Database: %C_WHITE%%DB_NAME%%C_RESET%
echo %C_GREY%   Save Location:   %C_WHITE%%BACKUP_DIR%%C_RESET%
echo.
echo %C_CYAN%============================================================%C_RESET%
echo.
echo    %C_WHITE%[1] FULL BACKUP%C_RESET%
echo    %C_WHITE%[2] STRUCTURE ONLY%C_RESET% %C_GREY%
echo.
echo %C_CYAN%============================================================%C_RESET%
echo.
set /p option="%C_YELLOW%> Select an option: %C_RESET%"

if "%option%"=="1" goto :backup_full
if "%option%"=="2" goto :backup_struct
goto :menu

:backup_full
echo.
echo %C_CYAN%[INFO]%C_WHITE% Generating FULL backup...%C_RESET%
"%MYSQL_PATH%" -h%DB_HOST% -u%DB_USER% -p%DB_PASS% --opt --databases --add-drop-database --result-file="%BACKUP_DIR%\temp_full.sql" %DB_NAME%

if not exist "%BACKUP_DIR%\temp_full.sql" (
    echo.
    echo %C_RED%[ERROR] Unable to generate the dump file.%C_RESET%
    echo %C_WHITE%Please check directory permissions and path accessibility.%C_RESET%
    echo %C_GREY%Target: "%BACKUP_DIR%\temp_full.sql"%C_RESET%
    pause
    exit
)

echo %C_CYAN%[INFO]%C_WHITE% Formatting SQL file...%C_RESET%
powershell -Command "(Get-Content '%BACKUP_DIR%\temp_full.sql') -replace '/\*![0-9]+ (.*?)\*/', '$1' | Set-Content '%BACKUP_DIR%\BACKUP_FULL_%datetimef%.sql'"

if exist "%BACKUP_DIR%\temp_full.sql" del "%BACKUP_DIR%\temp_full.sql"
echo %C_GREEN%[OK] Full backup saved successfully.%C_RESET%
echo %C_GREY%File: %BACKUP_DIR%\BACKUP_FULL_%datetimef%.sql%C_RESET%
goto :end

:backup_struct
echo.
echo %C_CYAN%[INFO]%C_WHITE% Generating STRUCTURE backup...%C_RESET%
"%MYSQL_PATH%" -h%DB_HOST% -u%DB_USER% -p%DB_PASS% --opt --no-data --databases --add-drop-database --result-file="%BACKUP_DIR%\temp_struct.sql" %DB_NAME%

if not exist "%BACKUP_DIR%\temp_struct.sql" (
    echo.
    echo %C_RED%[ERROR] Unable to generate the dump file.%C_RESET%
    echo %C_WHITE%Please check directory permissions and path accessibility.%C_RESET%
    echo %C_GREY%Target: "%BACKUP_DIR%\temp_struct.sql"%C_RESET%
    pause
    exit
)

echo %C_CYAN%[INFO]%C_WHITE% Sanitising AutoIncrement and version comments...%C_RESET%
powershell -Command "$c = Get-Content '%BACKUP_DIR%\temp_struct.sql'; $c = $c -replace 'AUTO_INCREMENT=[0-9]+', ''; $c = $c -replace '/\*![0-9]+ (.*?)\*/', '$1'; $c | Set-Content '%BACKUP_DIR%\BACKUP_STRUCT_%datetimef%.sql'"

del "%BACKUP_DIR%\temp_struct.sql"
echo %C_GREEN%[OK] Structure backup saved successfully.%C_RESET%
echo %C_GREY%File: %BACKUP_DIR%\BACKUP_STRUCT_%datetimef%.sql%C_RESET%
goto :end

:end
echo.
echo %C_CYAN%============================================================%C_RESET%
echo %C_GREEN%Process completed.%C_RESET%
pause >nul
exit