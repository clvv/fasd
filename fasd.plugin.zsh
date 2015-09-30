FASD_DIR=/usr/local/bin/fasd
if [ ! -d "$FASD_DIR" ]
then
	#FASD_REPO=</path/to/fasd/>
    echo $FASD_DIR does not exist
    REPOS_DIR="$HOME/.antigen/repos"
    FASD_REPO="$REPOS_DIR/https-COLON--SLASH--SLASH-github.com-SLASH-allcatsarebeautiful-SLASH-fasd.git"
	sudo make install -C $FASD_REPO
    source ~/.zshrc
else
    echo $FASD_DIR already exists
fi
