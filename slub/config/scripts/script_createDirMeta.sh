#!/bin/bash

# Enable logging
Debug=1

# Include error level handling
source `dirname $0`/errorlevel.sh

# Fetch directory name from command-line argument
Directory="$1"

# Exit with error if no parameter has been given
if [ -n $1 ]; then
    logger -p user.info "$0: No directory given."
    exit 1
fi



# Assemble options 
Verbose=
Filemode="-m 0775"

if [ ${Debug} -eq 1 ]; then
    Verbose="-v"
fi

# Call mkdir and capture output
Out=`/bin/mkdir ${Verbose} ${Filemode} "${Directory}" 2>&1`

# Get last command error level
Errorlevel=$?

# Log mkdir output if Debug is enabled
if [ ${Debug} -eq 1 ] && [ -n "${Out}" ] ; then
    logger -p user.info ${Out}
fi

# Call errorlevel function (signal error to syslog)
errorlevel
