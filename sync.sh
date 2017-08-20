alias dotfile='/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'
echo ".dotfiles >> .gitignore"

DOT_FILE_REPO=""
git clone --bare $DOT_FILE_REPO $HOME/.dotfiles
dotfiles checkout
source .bashrc
mkdir .config/i3/logs
