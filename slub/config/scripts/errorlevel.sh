#!/bin/bash

function errorlevel {
    if [ $Debug -eq 1 ]
    then
        if test $Errorlevel -eq 0
        then
            logger -p user.info -t $0 "OK"
        else
            logger -p user.info -t $0  "Fehler!"
        fi
    fi
}
