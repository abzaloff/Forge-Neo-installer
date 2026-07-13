# Forge Neo Windows Installer

A simple Windows batch installer for Forge Neo.

The goal of this installer is to make the setup process usable for people who do not want to install Git, UV, Python environments, or Visual Studio Build Tools manually.

## What It Does

`install-forge-neo.bat` automatically:

- checks for `winget`
- uses direct downloads as a fallback when `winget` is missing
- installs Git if it is missing
- installs UV if it is missing
- checks for Visual Studio C++ Build Tools
- installs Visual Studio 2022 Build Tools if the C++ toolchain is missing
- clones Forge Neo from the `neo` branch of `sd-webui-forge-classic`
- creates a Python 3.13 virtual environment with UV
- creates `webui-user.bat` with the recommended Forge Neo launch arguments
- asks whether to enable Sage Attention 2
- asks whether to enable Flash Attention
- starts Forge Neo after installation

The Forge Neo repository is installed into `sd-webui-forge-neo`.

## Requirements

- Windows 10 or Windows 11
- Internet connection

`winget` is used when available because it is the cleanest installation path on modern Windows. If `winget` is missing, the installer offers two choices: install App Installer from Microsoft Store and run the installer again, or continue without `winget` using direct downloads from official sources.

## How To Install

1. Download this repository.
2. Put `install-forge-neo.bat` into the folder where you want Forge Neo to be installed.
3. Double-click `install-forge-neo.bat`.
4. Accept any Windows administrator prompts if Build Tools or other dependencies need to be installed.
5. Answer the Sage Attention and Flash Attention questions.
6. Wait for Forge Neo to start.

After installation, the folder will contain the Forge Neo directory and several helper batch files.

## Helper Batch Files

The installer creates these files next to `install-forge-neo.bat`, not inside the Forge Neo folder.

### `run-forge-neo.bat`

Starts Forge Neo.

It enters `sd-webui-forge-neo` and runs `webui-user.bat`.

Use this file for normal startup after the first installation.

### `update.bat`

Updates Forge Neo.

It enters `sd-webui-forge-neo` and runs `git pull`.

Use this when you want to update the installed Forge Neo files from GitHub.

### `install_dependency.bat`

Installs extra Python packages into the Forge Neo virtual environment using UV.

It activates `sd-webui-forge-neo\venv`.

Then it asks for a package name and runs `uv pip install PACKAGE_NAME`.

Type `exit` to close the installer.

### `venv-reinstall.bat`

Deletes and recreates the Forge Neo virtual environment.

Before doing anything, it asks `Do you really want to reinstall the venv? Y/N`.

If confirmed, it removes `sd-webui-forge-neo\venv`.

Then it creates a fresh environment with `uv venv venv --python 3.13 --seed`.

Use this when dependencies are broken, PyTorch needs a clean reinstall, or the environment was modified incorrectly.

## Visual Studio Build Tools

Some Python packages, such as `insightface`, may need Microsoft C++ Build Tools to compile native extensions.

The installer checks for Visual Studio 2022 C++ Build Tools. If they are missing, it installs `Microsoft.VisualStudio.2022.BuildTools` with the minimal `Microsoft.VisualStudio.Workload.VCTools` workload.

This step can take a long time and may require administrator approval. If Windows asks for a restart, restart the computer and run `install-forge-neo.bat` again.

## Notes

- The generated helper files expect the Forge Neo folder to be named `sd-webui-forge-neo`.
- If `sd-webui-forge-neo` already exists but is not a Git repository, the installer stops to avoid overwriting user files.
- If Forge Neo or another terminal is using the virtual environment, `venv-reinstall.bat` may fail to remove it. Close Forge Neo and try again.

## Troubleshooting

### `winget` is missing

The installer shows the App Installer link and asks whether to continue without `winget`. Choose `Y` to use direct downloads, or choose `N` to stop, install **App Installer** from Microsoft Store, and run `install-forge-neo.bat` again.

### Git or UV was installed but still not found

Close the terminal or File Explorer window and run the batch file again. In some cases Windows needs a fresh session to update PATH.

### Visual Studio Build Tools installation failed

Install **Visual Studio 2022 Build Tools** manually and select **Desktop development with C++**, then run the installer again.

### Forge Neo does not start after reinstalling the venv

Run `run-forge-neo.bat`. Forge Neo may need to reinstall its Python dependencies into the fresh environment on the next startup.
