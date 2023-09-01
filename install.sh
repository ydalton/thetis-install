#!/bin/bash
#
# Copyright (c) 2023 xmvziron
#
# Thetis OpenHPSDR installer for Linux/Wine.
# Do not use this script

export WINEPREFIX=~/.thetis

file="Thetis-v2.10.0.x64.msi"
link="https://github.com/TAPR/OpenHPSDR-Thetis/releases/download/v2.10.0.0/$file"
raw_link="https://raw.githubusercontent.com/TAPR/OpenHPSDR-Thetis/master"

# Running this script as root is definitely a bad idea.
if [ "$EUID" -eq 0 ]; then
    echo "Please do not run this script as root."
    exit 1
fi

# We need to check whether all the commands that we need for the installation.
echo "Checking availability of commands..."
cmds=(wine wineboot winetricks 7z wget)
for cmd in ${cmds[@]}; do
    which $cmd > /dev/null
    if [ $? -eq  1 ]; then
        echo "$cmd not found. You need this command to run this script."
        exit 1
    fi
done
echo "All good! Now proceeding to install..."

if [ -d $WINEPREFIX ]; then
    echo -n "$WINEPREFIX already exists. "
    echo "Please remove it first before running this script."
    exit 1
fi

wineboot

pushd $WINEPREFIX/drive_c/Program\ Files/
pwd
rm -r OpenHPSDR/Thetis
mkdir -p -v OpenHPSDR/Thetis
cd OpenHPSDR/Thetis
echo "Downloading Thetis v2.10.0 from GitHub..."
if [ ! -z $file ]; then
    wget $link
fi
echo "Extracting downloaded file..."
7z x $file

# For some reason, extracting the msi file gives bad file extensions. I mass
# rename the files to fix that issue.
echo "Setting appropriate file extensions..."
for dll in *DLL; do
    mv -v -- "$dll" "${dll%DLL}.dll"
done
for exe in *EXE; do
    mv -v -- "$exe" "${exe%EXE}.exe"
done
for xml in *XML; do
    mv -v -- "$xml" "${xml%XML}.xml"
done
mv -v LibFFTW33.dll libfftw3-3.dll
popd

# Creating the desktop entry. No icon for it though.
mkdir -p -v ~/.local/share/applications
cat <<EOF > ~/.local/share/applications/Thetis.desktop
[Desktop Entry]
Type=Application
Name=Thetis
Comment=Run Thetis
Exec=env WINEPREFIX=$WINEPREFIX wine C:\\\\\\\\Program\\\\ Files\\\\\\\\OpenHPSDR\\\\\\\\Thetis\\\\\\\\Thetis.exe
StartupWMClass=Thetis
Terminal=false
EOF

echo "Installing dependencies..."
winetricks --force dotnet48

echo "Installing skins..."
wget "$raw_link/Project Files/Source/Thetis-Installer/MeterSkinInstaller.exe"
wget "$raw_link/Skins/OpenHPSDR_Skins.exe"
wine MeterSkinInstaller.exe
wine OpenHPSDR_Skins.exe

wine C:\\Program\ Files\\OpenHPSDR\\Thetis\\Thetis.exe

echo "All done! Now launch Thetis from your applications menu."
