FASD=/usr/local/bin/fasd
if [ ! -s "$FASD" ]
then
	#FASD_REPO=</path/to/fasd/>
    echo $FASD does not exist
    REPOS_DIR="$HOME/.antigen/repos"
    FASD_REPO="$REPOS_DIR/https-COLON--SLASH--SLASH-github.com-SLASH-allcatsarebeautiful-SLASH-fasd.git"
	sudo make install -C $FASD_REPO
    source ~/.zshrc
else
    echo fasd is already installed! 
fi
