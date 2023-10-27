//
//  UpdateScripts.swift
//  mNativeUpdater
//
//  Created by Yinwei Z on 10/25/23.
//

var downloadOnlySH: String = """
#!/bin/zsh

echo "Starting Download Only to ~/Downloads..."

arch=$(uname -m)
if [ "$arch" = "x86_64" ]; then
dmg_arch="64bit"
else
dmg_arch="aarch64"
fi

echo "Fetching the latest release information..."
release=$(curl -s https://api.github.com/repos/MCreator/MCreator/releases/latest)

echo "Locating the download resource for $arch architecture..."
mcrUrl=$(echo "$release" | grep -o "https://[^']*Mac.$dmg_arch.dmg" | head -n 1)
mcrFile=$(basename "$mcrUrl")

echo "Downloading $mcrFile..."
curl -L -o "$HOME/Downloads/$mcrFile" "$mcrUrl"

echo "Finishing Up"
"""


var downloadOnlySHSnap: String = """
#!/bin/zsh

echo "Starting Download Only to ~/Downloads... (SNAPSHOT)"

arch=$(uname -m)
if [ "$arch" = "x86_64" ]; then
dmg_arch="64bit"
else
dmg_arch="aarch64"
fi

echo "Fetching the latest prerelease information..."
releases=$(curl -s https://api.github.com/repos/MCreator/MCreator/releases)
prerelease=$(echo "$releases" | grep -m 1 -o '"prerelease": true')

if [ -z "$prerelease" ]; then
    echo "No prereleases found."
    exit 1
fi

echo "Locating the download resource for $arch architecture..."
mcrUrl=$(echo "$releases" | grep -o "https://[^']*Mac.$dmg_arch.dmg" | head -n 1)
mcrFile=$(basename "$mcrUrl")

echo "Downloading $mcrFile..."
curl -L -o "$HOME/Downloads/$mcrFile" "$mcrUrl"

echo "Finishing Up"

"""


var fullUpdateSH: String = """
#!/bin/zsh
echo "Starting Update..."

check_error() {
    if [ $? -ne 0 ]; then
    echo "An error occurred."
    exit 1
    fi
}

arch=$(uname -m)
if [ "$arch" = "x86_64" ]; then
dmg_arch="64bit"
else
dmg_arch="aarch64"
fi

echo "Fetching the latest release information..."
release=$(curl -s https://api.github.com/repos/MCreator/MCreator/releases/latest)
check_error

echo "Locating the download resource for $arch architecture..."
mcrUrl=$(echo "$release" | grep -o "https://[^']*Mac.$dmg_arch.dmg" | head -n 1)
mcrFile=$(basename "$mcrUrl")

# Detach existing MCreator volumes if they exist
if mount | grep -q "/Volumes/MCreator"; then
    echo "Detaching previously mounted MCreator volumes..."
    echo "$0" | sudo -S hdiutil detach /Volumes/MCreator*/
fi

echo "Downloading $mcrFile..."
curl -L -o "$HOME/Downloads/$mcrFile" "$mcrUrl"
check_error

echo "Mounting the disk image..."
hdiutil attach "$HOME/Downloads/$mcrFile"
check_error

echo "Moving the old version to the Trash..."
if [ -e /Applications/MCreator.app ]; then
    if [ -e ~/.Trash/MCreator.app ]; then
    counter=1
    # While an mcreator exists in the Trash, increment counter
    while [ -e ~/.Trash/MCreator-${counter}.app ]; do
        counter=$((counter + 1))
    done
    echo "$0" | sudo -S mv /Applications/MCreator.app ~/.Trash/MCreator-${counter}.app
    else
    echo "$0" | sudo -S mv /Applications/MCreator.app ~/.Trash/
    fi
else
    echo "No existing app found in Applications. Very stange..."
fi

echo "Copying the new version to Applications folder..."
echo "$0" | sudo -S find /Volumes/MCreator*/ -name "*.app" -exec cp -R {} /Applications/ \\;
check_error

echo "Detaching the mounted volume..."
echo "$0" | sudo -S hdiutil detach /Volumes/MCreator*/
check_error

echo "Deleting the disk image..."
rm "$HOME/Downloads/$mcrFile"
check_error

echo "Opening MCreator.app..."
open /Applications/MCreator.app
check_error
"""


var fullUpdateSHSnap: String = """
#!/bin/zsh
echo "Starting Update... (SNAPSHOT)"

check_error() {
    if [ $? -ne 0 ]; then
    echo "An error occurred."
    exit 1
    fi
}

arch=$(uname -m)
if [ "$arch" = "x86_64" ]; then
dmg_arch="64bit"
else
dmg_arch="aarch64"
fi

echo "Fetching the latest prerelease information..."
releases=$(curl -s https://api.github.com/repos/MCreator/MCreator/releases)
prerelease=$(echo "$releases" | grep -m 1 -o '"prerelease": true')

if [ -z "$prerelease" ]; then
    echo "No prereleases found."
    exit 1
fi

echo "Locating the download resource for $arch architecture..."
mcrUrl=$(echo "$releases" | grep -o "https://[^']*Mac.$dmg_arch.dmg" | head -n 1)
mcrFile=$(basename "$mcrUrl")

# Detach existing MCreator volumes if they exist
if mount | grep -q "/Volumes/MCreator"; then
    echo "Detaching previously mounted MCreator volumes..."
    echo "$0" | sudo -S hdiutil detach /Volumes/MCreator*/
fi

echo "Downloading $mcrFile..."
curl -L -o "$HOME/Downloads/$mcrFile" "$mcrUrl"
check_error

echo "Mounting the disk image..."
hdiutil attach "$HOME/Downloads/$mcrFile"
check_error

echo "Moving the old version to the Trash..."
if [ -e /Applications/MCreator.app ]; then
    if [ -e ~/.Trash/MCreator.app ]; then
    counter=1
    # While an mcreator exists in the Trash, increment counter
    while [ -e ~/.Trash/MCreator-${counter}.app ]; do
        counter=$((counter + 1))
    done
    echo "$0" | sudo -S mv /Applications/MCreator.app ~/.Trash/MCreator-${counter}.app
    else
    echo "$0" | sudo -S mv /Applications/MCreator.app ~/.Trash/
    fi
else
    echo "No existing app found in Applications. Very stange..."
fi

echo "Copying the new version to Applications folder..."
echo "$0" | sudo -S find /Volumes/MCreator*/ -name "*.app" -exec cp -R {} /Applications/ \\;
check_error

echo "Detaching the mounted volume..."
echo "$0" | sudo -S hdiutil detach /Volumes/MCreator*/
check_error

echo "Deleting the disk image..."
rm "$HOME/Downloads/$mcrFile"
check_error

echo "Opening MCreator.app..."
open /Applications/MCreator.app
check_error
"""
