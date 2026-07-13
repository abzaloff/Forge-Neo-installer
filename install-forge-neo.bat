@echo off
setlocal EnableExtensions

cd /d "%~dp0"

echo.
echo Forge Neo automatic installer
echo.

set "HAS_WINGET=0"
call :detect_winget
if errorlevel 1 exit /b 1

call :ensure_git
if errorlevel 1 exit /b 1

call :ensure_uv
if errorlevel 1 exit /b 1

call :ensure_build_tools
if errorlevel 1 exit /b 1

if exist "sd-webui-forge-neo\.git" (
    echo Repository already exists: sd-webui-forge-neo
) else (
    if exist "sd-webui-forge-neo" (
        echo ERROR: sd-webui-forge-neo already exists but is not a Git repository.
        echo Remove or rename this folder, then run the installer again.
        pause
        exit /b 1
    )

    git clone https://github.com/Haoming02/sd-webui-forge-classic sd-webui-forge-neo --branch neo
    if errorlevel 1 (
        echo ERROR: Repository clone failed.
        pause
        exit /b 1
    )
)

call :write_helper_bats
if errorlevel 1 exit /b 1

cd sd-webui-forge-neo
if errorlevel 1 (
    echo ERROR: Cannot enter sd-webui-forge-neo.
    pause
    exit /b 1
)

uv venv venv --python 3.13 --seed
if errorlevel 1 (
    echo ERROR: Virtual environment creation failed.
    pause
    exit /b 1
)

set "SAGE_FLAG="
set "FLASH_FLAG="

echo.
choice /C YN /M "Do you want to install Sage Attention 2? Y/N"
if errorlevel 2 goto ask_flash_attention
set "SAGE_FLAG= --sage"

:ask_flash_attention
choice /C YN /M "Do you want to install Flash Attention? Y/N"
if errorlevel 2 goto build_commandline_args
set "FLASH_FLAG= --flash"

:build_commandline_args
set "COMMANDLINE_ARGS=--uv --nunchaku --bnb --cuda-malloc --reserve-vram 2 --tiled-conv2d 512 --theme dark%SAGE_FLAG%%FLASH_FLAG%"

(
    echo @echo off
    echo.
    echo :: set PYTHON=
    echo :: set GIT=
    echo :: set VENV_DIR=
    echo.
    echo set COMMANDLINE_ARGS= %COMMANDLINE_ARGS%
    echo.
    echo :: --xformers --sage --uv
    echo :: --pin-shared-memory --cuda-malloc --cuda-stream
    echo :: --skip-python-version-check --skip-torch-cuda-test --skip-version-check --skip-prepare-environment --skip-install
    echo.
    echo call webui.bat
) > webui-user.bat

if not exist webui-user.bat (
    echo ERROR: Failed to write webui-user.bat.
    pause
    exit /b 1
)

call webui-user.bat
exit /b %errorlevel%

:write_helper_bats
(
    echo @echo off
    echo setlocal EnableExtensions
    echo set "FORGE_DIR=%%~dp0sd-webui-forge-neo"
    echo.
    echo if not exist "%%FORGE_DIR%%\webui-user.bat" ^(
    echo     echo ERROR: webui-user.bat was not found in "%%FORGE_DIR%%".
    echo     pause
    echo     exit /b 1
    echo ^)
    echo.
    echo cd /d "%%FORGE_DIR%%"
    echo call webui-user.bat
    echo exit /b %%errorlevel%%
) > run-forge-neo.bat
if errorlevel 1 goto helper_bat_failed

(
    echo @echo off
    echo setlocal EnableExtensions
    echo set "FORGE_DIR=%%~dp0sd-webui-forge-neo"
    echo.
    echo if not exist "%%FORGE_DIR%%\.git" ^(
    echo     echo ERROR: Forge Neo Git repository was not found in "%%FORGE_DIR%%".
    echo     pause
    echo     exit /b 1
    echo ^)
    echo.
    echo cd /d "%%FORGE_DIR%%"
    echo git pull
    echo set "UPDATE_EXIT=%%errorlevel%%"
    echo pause
    echo exit /b %%UPDATE_EXIT%%
) > update.bat
if errorlevel 1 goto helper_bat_failed

(
    echo @echo off
    echo setlocal EnableExtensions
    echo title Forge Neo Dependency Installer
    echo set "FORGE_DIR=%%~dp0sd-webui-forge-neo"
    echo.
    echo if not exist "%%FORGE_DIR%%\venv\Scripts\activate.bat" ^(
    echo     echo ERROR: Forge Neo venv was not found in "%%FORGE_DIR%%".
    echo     pause
    echo     exit /b 1
    echo ^)
    echo.
    echo cd /d "%%FORGE_DIR%%"
    echo call venv\Scripts\activate.bat
    echo.
    echo where uv ^>nul 2^>nul
    echo if errorlevel 1 ^(
    echo     echo ERROR: UV was not found in PATH.
    echo     pause
    echo     exit /b 1
    echo ^)
    echo.
    echo :menu
    echo cls
    echo echo ==========================================
    echo echo      Forge Neo Dependency Installer
    echo echo ==========================================
    echo echo.
    echo set /p PACKAGE=Enter package name ^(or exit^):
    echo.
    echo if /i "%%PACKAGE%%"=="exit" goto end
    echo if "%%PACKAGE%%"=="" goto menu
    echo.
    echo echo.
    echo echo Installing %%PACKAGE%%...
    echo uv pip install %%PACKAGE%%
    echo.
    echo echo.
    echo pause
    echo goto menu
    echo.
    echo :end
    echo exit /b 0
) > install_dependency.bat
if errorlevel 1 goto helper_bat_failed

(
    echo @echo off
    echo setlocal EnableExtensions
    echo title Forge Neo Venv Reinstaller
    echo set "FORGE_DIR=%%~dp0sd-webui-forge-neo"
    echo.
    echo if not exist "%%FORGE_DIR%%" ^(
    echo     echo ERROR: Forge Neo folder was not found in "%%FORGE_DIR%%".
    echo     pause
    echo     exit /b 1
    echo ^)
    echo.
    echo echo This will delete and recreate the Forge Neo venv folder.
    echo choice /C YN /M "Do you really want to reinstall the venv? Y/N"
    echo if errorlevel 2 exit /b 0
    echo.
    echo where uv ^>nul 2^>nul
    echo if errorlevel 1 ^(
    echo     echo ERROR: UV was not found in PATH.
    echo     pause
    echo     exit /b 1
    echo ^)
    echo.
    echo cd /d "%%FORGE_DIR%%"
    echo if exist "venv" ^(
    echo     echo Removing existing venv...
    echo     rmdir /s /q "venv"
    echo     if exist "venv" ^(
    echo         echo ERROR: Failed to remove venv. Close Forge Neo and any terminal using it, then try again.
    echo         pause
    echo         exit /b 1
    echo     ^)
    echo ^)
    echo.
    echo echo Creating new venv...
    echo uv venv venv --python 3.13 --seed
    echo if errorlevel 1 ^(
    echo     echo ERROR: Virtual environment creation failed.
    echo     pause
    echo     exit /b 1
    echo ^)
    echo.
    echo echo Venv reinstalled successfully.
    echo pause
    echo exit /b 0
) > venv-reinstall.bat
if errorlevel 1 goto helper_bat_failed

echo Helper bat files written:
echo   run-forge-neo.bat
echo   update.bat
echo   install_dependency.bat
echo   venv-reinstall.bat
exit /b 0

:helper_bat_failed
echo ERROR: Failed to write helper bat files.
pause
exit /b 1

:detect_winget
where winget >nul 2>nul
if not errorlevel 1 (
    set "HAS_WINGET=1"
    echo winget found.
    exit /b 0
)

echo winget was not found.
echo.
echo You can install App Installer from Microsoft Store and then run this installer again:
echo https://apps.microsoft.com/detail/9nblggh4nns1
echo.
choice /C YN /M "Continue installation without winget? Y/N"
if errorlevel 2 (
    echo Installation cancelled.
    pause
    exit /b 1
)

echo Continuing without winget. The installer will use direct downloads as a fallback.
exit /b 0

:ensure_git
where git >nul 2>nul
if not errorlevel 1 (
    echo Git found.
    exit /b 0
)

if "%HAS_WINGET%"=="1" goto install_git_with_winget
goto install_git_direct

:install_git_with_winget
echo Git not found. Installing Git with winget...
winget install --id Git.Git -e --source winget --accept-package-agreements --accept-source-agreements
if errorlevel 1 (
    echo ERROR: Git installation failed.
    pause
    exit /b 1
)
goto verify_git

:install_git_direct
echo Git not found. Downloading Git for Windows installer...
set "GIT_INSTALLER=%TEMP%\forge-neo-git-installer.exe"
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; [Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12; $release=Invoke-RestMethod -Uri 'https://api.github.com/repos/git-for-windows/git/releases/latest' -Headers @{'User-Agent'='ForgeNeoInstaller'}; $asset=$release.assets | Where-Object { $_.name -match '^Git-[0-9].*-64-bit\.exe$' } | Select-Object -First 1; if (-not $asset) { throw 'Git for Windows installer asset was not found.' }; Invoke-WebRequest -Uri $asset.browser_download_url -OutFile '%GIT_INSTALLER%'"
if errorlevel 1 (
    echo ERROR: Git installer download failed.
    pause
    exit /b 1
)

if not exist "%GIT_INSTALLER%" (
    echo ERROR: Git installer was not downloaded.
    pause
    exit /b 1
)

echo Installing Git...
"%GIT_INSTALLER%" /VERYSILENT /NORESTART /NOCANCEL /SP- /CLOSEAPPLICATIONS
if errorlevel 1 (
    echo ERROR: Git installation failed.
    pause
    exit /b 1
)

:verify_git

call :refresh_path
where git >nul 2>nul
if errorlevel 1 (
    if exist "%ProgramFiles%\Git\cmd\git.exe" set "PATH=%ProgramFiles%\Git\cmd;%PATH%"
)
where git >nul 2>nul
if errorlevel 1 (
    if exist "%ProgramFiles(x86)%\Git\cmd\git.exe" set "PATH=%ProgramFiles(x86)%\Git\cmd;%PATH%"
)
where git >nul 2>nul
if errorlevel 1 (
    echo ERROR: Git installation did not complete or git.exe is not available in PATH.
    echo Check your internet connection or install Git manually, then run this installer again.
    pause
    exit /b 1
)

echo Git installed.
exit /b 0

:ensure_uv
where uv >nul 2>nul
if not errorlevel 1 (
    echo UV found.
    exit /b 0
)

if "%HAS_WINGET%"=="1" goto install_uv_with_winget
goto install_uv_direct

:install_uv_with_winget
echo UV not found. Installing UV with winget...
winget install --id astral-sh.uv -e --source winget --accept-package-agreements --accept-source-agreements
if errorlevel 1 (
    echo ERROR: UV installation failed.
    pause
    exit /b 1
)
goto configure_uv_path

:install_uv_direct
echo UV not found. Installing UV from the official installer script...
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; [Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12; Invoke-RestMethod -Uri 'https://astral.sh/uv/install.ps1' | Invoke-Expression"
if errorlevel 1 (
    echo ERROR: UV installation failed.
    pause
    exit /b 1
)

:configure_uv_path

set "UV_BIN=%USERPROFILE%\.local\bin"
call :add_user_path "%UV_BIN%"
call :refresh_path

where uv >nul 2>nul
if errorlevel 1 (
    if exist "%UV_BIN%\uv.exe" set "PATH=%UV_BIN%;%PATH%"
)

where uv >nul 2>nul
if errorlevel 1 (
    echo ERROR: UV installation did not complete or uv.exe is not available in PATH.
    echo Check your internet connection or install UV manually, then run this installer again.
    pause
    exit /b 1
)

echo UV installed.
exit /b 0

:ensure_build_tools
set "VSWHERE=%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe"
if exist "%VSWHERE%" (
    "%VSWHERE%" -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath >nul 2>nul
    if not errorlevel 1 (
        echo Visual Studio C++ Build Tools found.
        exit /b 0
    )
)

if exist "%ProgramFiles%\Microsoft Visual Studio\2022\BuildTools\VC\Tools\MSVC" (
    echo Visual Studio C++ Build Tools found.
    exit /b 0
)
if exist "%ProgramFiles%\Microsoft Visual Studio\2022\Community\VC\Tools\MSVC" (
    echo Visual Studio C++ Build Tools found.
    exit /b 0
)
if exist "%ProgramFiles%\Microsoft Visual Studio\2022\Professional\VC\Tools\MSVC" (
    echo Visual Studio C++ Build Tools found.
    exit /b 0
)
if exist "%ProgramFiles%\Microsoft Visual Studio\2022\Enterprise\VC\Tools\MSVC" (
    echo Visual Studio C++ Build Tools found.
    exit /b 0
)
if exist "%ProgramFiles(x86)%\Microsoft Visual Studio\2022\BuildTools\VC\Tools\MSVC" (
    echo Visual Studio C++ Build Tools found.
    exit /b 0
)

echo Visual Studio C++ Build Tools not found.
if "%HAS_WINGET%"=="1" goto install_build_tools_with_winget
goto install_build_tools_direct

:install_build_tools_with_winget
echo Installing Visual Studio 2022 Build Tools with winget. This can take a long time and may require administrator approval.
winget install --id Microsoft.VisualStudio.2022.BuildTools -e --source winget --accept-package-agreements --accept-source-agreements --override "--wait --passive --add Microsoft.VisualStudio.Workload.VCTools"
set "BUILD_TOOLS_INSTALL_EXIT=%errorlevel%"
if not "%BUILD_TOOLS_INSTALL_EXIT%"=="0" if not "%BUILD_TOOLS_INSTALL_EXIT%"=="3010" (
    echo ERROR: Visual Studio Build Tools installation failed.
    echo Install "Visual Studio 2022 Build Tools" with "Desktop development with C++", then run this installer again.
    pause
    exit /b 1
)
goto verify_build_tools_after_install

:install_build_tools_direct
echo Downloading Visual Studio 2022 Build Tools installer...
set "VS_BUILDTOOLS_INSTALLER=%TEMP%\forge-neo-vs_BuildTools.exe"
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; [Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri 'https://aka.ms/vs/17/release/vs_BuildTools.exe' -OutFile '%VS_BUILDTOOLS_INSTALLER%'"
if errorlevel 1 (
    echo ERROR: Visual Studio Build Tools installer download failed.
    pause
    exit /b 1
)

if not exist "%VS_BUILDTOOLS_INSTALLER%" (
    echo ERROR: Visual Studio Build Tools installer was not downloaded.
    pause
    exit /b 1
)

echo Installing Visual Studio 2022 Build Tools. This can take a long time and may require administrator approval.
"%VS_BUILDTOOLS_INSTALLER%" --wait --passive --add Microsoft.VisualStudio.Workload.VCTools --norestart
set "BUILD_TOOLS_INSTALL_EXIT=%errorlevel%"
if not "%BUILD_TOOLS_INSTALL_EXIT%"=="0" if not "%BUILD_TOOLS_INSTALL_EXIT%"=="3010" (
    echo ERROR: Visual Studio Build Tools installation failed.
    echo Install "Visual Studio 2022 Build Tools" with "Desktop development with C++", then run this installer again.
    pause
    exit /b 1
)

:verify_build_tools_after_install

set "BUILD_TOOLS_FOUND="
if exist "%VSWHERE%" (
    "%VSWHERE%" -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath >nul 2>nul
    if not errorlevel 1 set "BUILD_TOOLS_FOUND=1"
)
if exist "%ProgramFiles%\Microsoft Visual Studio\2022\BuildTools\VC\Tools\MSVC" set "BUILD_TOOLS_FOUND=1"
if exist "%ProgramFiles%\Microsoft Visual Studio\2022\Community\VC\Tools\MSVC" set "BUILD_TOOLS_FOUND=1"
if exist "%ProgramFiles%\Microsoft Visual Studio\2022\Professional\VC\Tools\MSVC" set "BUILD_TOOLS_FOUND=1"
if exist "%ProgramFiles%\Microsoft Visual Studio\2022\Enterprise\VC\Tools\MSVC" set "BUILD_TOOLS_FOUND=1"
if exist "%ProgramFiles(x86)%\Microsoft Visual Studio\2022\BuildTools\VC\Tools\MSVC" set "BUILD_TOOLS_FOUND=1"

if not "%BUILD_TOOLS_FOUND%"=="1" (
    echo ERROR: Visual Studio Build Tools installed, but the C++ toolchain was not detected.
    echo If the installer asks for a reboot, restart Windows and run this installer again.
    pause
    exit /b 1
)

echo Visual Studio C++ Build Tools installed.
exit /b 0

:add_user_path
set "PATH_TO_ADD=%~1"
if "%PATH_TO_ADD%"=="" exit /b 0

powershell -NoProfile -ExecutionPolicy Bypass -Command "$p=[Environment]::GetEnvironmentVariable('Path','User'); if ($null -eq $p) { $p='' }; $n='%PATH_TO_ADD%'; if (-not (($p -split ';') -contains $n)) { [Environment]::SetEnvironmentVariable('Path', (($p.TrimEnd(';') + ';' + $n).TrimStart(';')), 'User') }"
exit /b 0

:refresh_path
for /f "usebackq tokens=*" %%A in (`powershell -NoProfile -Command "[Environment]::GetEnvironmentVariable('Path','Machine') + ';' + [Environment]::GetEnvironmentVariable('Path','User')"`) do set "PATH=%%A"
exit /b 0
