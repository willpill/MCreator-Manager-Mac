#!/bin/zsh

#  fullUpdate.sh
#  mNativeUpdater
#
#  Created by Yinwei Z on 10/24/23.
#

LOG_FILE="$HOME/Downloads/updater_log_$(date +%Y%m%d%H%M%S).log"
exec > >(tee "$LOG_FILE") 2>&1
echo "Starting Update..."

check_error() {
    if [ $? -ne 0 ]; then
    echo "An error occurred. Saved log file to $HOME/Downloads."
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

echo "Detaching previously mounted MCreator volumes..."
echo "$1" | sudo -S hdiutil detach /Volumes/MCreator*/

echo "Downloading $mcrFile..."
curl -L -o "$HOME/Downloads/$mcrFile" "$mcrUrl"
check_error

echo "Mounting the disk image..."
hdiutil attach "$HOME/Downloads/$mcrFile"
check_error

echo "Moving the old version to the Trash..."

# If the application already exists in the Trash
if [ -e ~/.Trash/MCreator.app ]; then
counter=1
# While a file/folder with that name exists in the Trash, increment counter
while [ -e ~/.Trash/MCreator-${counter}.app ]; do
counter=$((counter + 1))
done
echo "$1" | sudo -S mv /Applications/MCreator.app ~/.Trash/MCreator-${counter}.app
else
echo "$1" | sudo -S mv /Applications/MCreator.app ~/.Trash/
fi
# Dont check error bc there might not be an existing MCreator

echo "Copying the new version to Applications folder..."
echo "$1" | sudo -S find /Volumes/MCreator*/ -name "*.app" -exec cp -R {} /Applications/ \\;
check_error

echo "Detaching the mounted volume..."
echo "$1" | sudo -S hdiutil detach /Volumes/MCreator*/
check_error

echo "Deleting the disk image..."
rm "$HOME/Downloads/$mcrFile"
check_error

echo "Opening MCreator.app..."
open /Applications/MCreator.app
check_error
