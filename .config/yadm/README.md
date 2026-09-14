## Fresh macOS installation

0. Copy `~/Parallels` and `~/Projects` to the external drive. `mc` is a good option for this.
1. Format the drive and install macOS
1. Remove everything from the Dock.
2. Install Homebrew from https://brew.sh.
3. `brew install yadm`.
4. Generate a new SSH key and save the passphrase to the keychain. https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent.
5. Add the key to GitHub. Remove the old one. https://github.com/settings/ssh/new: `cat ~/.ssh/id_ed25519.pub | pbcopy`.
6. `yadm clone git@github.com:madyankin/dotfiles.git`.
7. Run  `~/.config/yadm/bootstrap`.
8. Remove everything from Finder's sidebar. Pin the PARA and Family Docs directories from Documents.
9. Add Guitar and Downloads dirs to the Dock
10. Copy `~/Parallels` and `~/Projects` back from the external drive
11. Set up Arq backups: Desktop, Documents, Projects, Parallels, Obsidian, external drives (skip when unmounted). Download the supported Arq version from the Arq account
