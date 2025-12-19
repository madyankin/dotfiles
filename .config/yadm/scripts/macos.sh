#!/usr/bin/env bash

# macOS defaults configuration
# See: https://github.com/kevinSuttle/macOS-Defaults

set -e

SCREENSHOTS_DIR="${HOME}/Screenshots"

# --- Sudo keepalive ---
sudo -v
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

# --- Hostname ---
setup_hostname() {
  echo ""
  read -rp "Enter hostname: " HOST_NAME
  [[ -z "$HOST_NAME" ]] && return
  
  sudo scutil --set ComputerName "$HOST_NAME"
  sudo scutil --set HostName "$HOST_NAME"
  sudo scutil --set LocalHostName "$HOST_NAME"
  sudo defaults write /Library/Preferences/SystemConfiguration/com.apple.smb.server NetBIOSName -string "$HOST_NAME"
  echo "✓ Hostname set to $HOST_NAME"
}

# --- Finder ---
configure_finder() {
  echo "→ Configuring Finder..."
  
  # Desktop icons
  defaults write com.apple.finder ShowExternalHardDrivesOnDesktop -bool true
  defaults write com.apple.finder ShowHardDrivesOnDesktop -bool false
  defaults write com.apple.finder ShowMountedServersOnDesktop -bool false
  defaults write com.apple.finder ShowRemovableMediaOnDesktop -bool true
  
  # UI
  defaults write com.apple.finder ShowStatusBar -bool true
  defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"  # Search current folder
  defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false
  defaults write com.apple.finder _FXSortFoldersFirst -bool true
  defaults write com.apple.finder _FXSortFoldersFirstOnDesktop -bool true
  defaults write com.apple.finder FXPreferredViewStyle -string "clmv"  # Column view
  defaults write NSGlobalDomain AppleShowAllExtensions -bool true
  
  # Default location: Home
  defaults write com.apple.finder NewWindowTarget -string "PfLo"
  defaults write com.apple.finder NewWindowTargetPath -string "file://${HOME}"
  
  # Performance
  defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
}

# --- System UI ---
configure_system_ui() {
  echo "→ Configuring System UI..."
  
  # Animations
  defaults write NSGlobalDomain NSAutomaticWindowAnimationsEnabled -bool false
  
  # Dialogs
  defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
  
  # Dock
  defaults write com.apple.dock mineffect -string "scale"
  defaults write com.apple.dock minimize-to-application -bool true
  defaults write com.apple.dock autohide -bool true
  defaults write com.apple.dock show-recents -bool false
  defaults write com.apple.dock persistent-apps -array
  defaults write com.apple.dock persistent-others -array
  defaults write com.apple.dock expose-group-apps -bool true
  killall Dock
  
  # Window dragging with Cmd+Ctrl
  defaults write -g NSWindowShouldDragOnGesture YES
}

# --- Screenshots ---
configure_screenshots() {
  echo "→ Configuring Screenshots..."
  
  mkdir -p "$SCREENSHOTS_DIR"
  defaults write com.apple.screencapture location -string "$SCREENSHOTS_DIR"
  defaults write com.apple.screencapture disable-shadow -bool true
}

# --- Disk Images ---
configure_disk_images() {
  echo "→ Configuring Disk Images..."
  
  defaults write com.apple.frameworks.diskimages skip-verify -bool true
  defaults write com.apple.frameworks.diskimages skip-verify-locked -bool true
  defaults write com.apple.frameworks.diskimages skip-verify-remote -bool true
}

# --- Safari ---
configure_safari() {
  echo "→ Configuring Safari..."
  
  defaults write com.apple.Safari HomePage -string "about:blank"
  defaults write com.apple.Safari AutoOpenSafeDownloads -bool false
  defaults write com.apple.Safari ShowFavoritesBar -bool false
  defaults write com.apple.Safari FindOnPageMatchesWordStartsOnly -bool false
  
  # Developer tools
  defaults write com.apple.Safari IncludeDevelopMenu -bool true
  defaults write com.apple.Safari WebKitDeveloperExtrasEnabledPreferenceKey -bool true
  defaults write com.apple.Safari com.apple.Safari.ContentPageGroupIdentifier.WebKit2DeveloperExtrasEnabled -bool true
  defaults write NSGlobalDomain WebKitDeveloperExtras -bool true
  
  # Security & spelling
  defaults write com.apple.Safari WebContinuousSpellCheckingEnabled -bool true
  defaults write com.apple.Safari WebAutomaticSpellingCorrectionEnabled -bool false
  defaults write com.apple.Safari WarnAboutFraudulentWebsites -bool true
  defaults write com.apple.Safari SendDoNotTrackHTTPHeader -bool true
}

# --- Input & Text ---
configure_input() {
  echo "→ Configuring Input..."
  
  # Trackpad: tap to click
  defaults write com.apple.AppleMultitouchTrackpad Clicking -bool true
  defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
  defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
  
  # Mouse: right click as secondary click
  defaults write com.apple.driver.AppleBluetoothMultitouch.mouse MouseButtonMode -string "TwoButton"
  defaults write com.apple.AppleMultitouchMouse MouseButtonMode -string "TwoButton"
  
  # Mouse: swipe between pages with one finger
  defaults write NSGlobalDomain AppleEnableMouseSwipeNavigateWithScrolls -bool true
  defaults write com.apple.driver.AppleBluetoothMultitouch.mouse MouseOneFingerDoubleTapGesture -int 1
  
  # Accessibility: zoom with Ctrl + scroll
  defaults write com.apple.universalaccess closeViewScrollWheelToggle -bool true
  defaults write com.apple.universalaccess HIDScrollZoomModifierMask -int 262144  # Ctrl key
  
  # Disable auto-correct globally
  defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false
  
  # Messages: disable emoji substitution and smart quotes
  defaults write com.apple.messageshelper.MessageController SOInputLineSettings -dict-add "automaticEmojiSubstitutionEnablediMessage" -bool false
  defaults write com.apple.messageshelper.MessageController SOInputLineSettings -dict-add "automaticQuoteSubstitutionEnabled" -bool false
}

# --- Mail ---
configure_mail() {
  echo "→ Configuring Mail..."
  
  # Plain email addresses on copy
  defaults write com.apple.mail AddressesIncludeNameOnPasteboard -bool false
  
  # Font sizes
  defaults write com.apple.mail NSFontSize -int 16
  defaults write com.apple.mail NSFixedPitchFontSize -int 14
}

# --- Terminal & Fonts ---
configure_terminal() {
  echo "→ Configuring Terminal & Fonts..."
  
  defaults write com.apple.terminal StringEncodings -array 4  # UTF-8
  defaults write com.apple.Terminal "Default Window Settings" -string "Basic"
  defaults write com.apple.Terminal "Startup Window Settings" -string "Basic"
  
  # Crispy fonts (no smoothing)
  defaults -currentHost write -g AppleFontSmoothing -int 0
}

# --- TextEdit ---
configure_textedit() {
  echo "→ Configuring TextEdit..."
  
  # Plain text by default
  defaults write com.apple.TextEdit RichText -int 0
  
  # Font size 14 for both plain and rich text
  defaults write com.apple.TextEdit NSFixedPitchFontSize -int 14
  defaults write com.apple.TextEdit NSFontSize -int 14
}

# --- Performance ---
configure_performance() {
  echo "→ Configuring Performance..."
  
  # Disable noatime for SSD
  sudo cp ~/.config/yadm/scripts/assets/com.hdd.noatime.plist /Library/LaunchDaemons/
  sudo chown root:wheel /Library/LaunchDaemons/com.hdd.noatime.plist
}

# --- Run All ---
echo ""
echo "╭─────────────────────────────────────╮"
echo "│       macOS Defaults Setup          │"
echo "╰─────────────────────────────────────╯"

setup_hostname
configure_finder
configure_system_ui
configure_screenshots
configure_disk_images
configure_safari
configure_input
configure_mail
configure_terminal
configure_textedit
configure_performance

echo ""
echo "✓ Done. Restart required for some changes."
