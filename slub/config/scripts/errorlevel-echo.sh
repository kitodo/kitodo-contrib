#!/bin/bash

function errorlevel {
    if [ $Debug -eq 1 ]
    then
        if test $Errorlevel -eq 0
        then
            echo "OK"
        else
            echo  "Fehler!"
        fi
    fi
}
