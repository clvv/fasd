#!/bin/zsh

fasd -f notARealFile.txt
failed=$?
fasd -f .vimrc
success=$?
fasd -d ~
success_cd=$?

if [[ $failed == 1 ]]; then
    if [[ $success == 0 ]]; then
        if [[ $success_cd == 0 ]]; then
            echo Tests passed!
        else
            echo Error: ~ should have been found!
        fi
    else
        echo Error: .vimrc should have been found!
    fi
else
    echo Error: notARealFile.txt should not have been found!
fi

