#!/bin/zsh

#  downloadOnly.sh
#  mNativeUpdater
#
#  Created by Yinwei Z on 10/24/23.
#

LOG_FILE="$HOME/Downloads/updater_log_$(date +%Y%m%d%H%M%S).log"
exec > >(tee "$LOG_FILE") 2>&1

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

echo "Done"
