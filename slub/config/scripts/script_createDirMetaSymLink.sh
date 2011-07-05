#!/bin/bash

# Enable logging
Debug=1

# Include error level handling
source `dirname $0`/errorlevel.sh

# Fetch directory name from command-line argument
Symlink="$1"

# Exit with error if no parameter has been given
if [ -z "$1" ]; then
    logger -p user.info -t $0 "No directory given."
    exit 1
fi

# Assemble options 
Verbose=
Filemode="-m 0775"

if [ ${Debug} -eq 1 ]; then
    Verbose="-v"
fi

# Extract first number sequence as Goobi process ID
ProcessId=`expr match "$Symlink" '[a-zA-Z0-9\/]*\/\([0-9]\+\)'`

# Determine storage area
Area="bereich/"`expr $ProcessId / 10000`

# Base directory is Symlink path without Goobi process ID and following parts
BaseDirectory=${Symlink%$ProcessId*}

# Determine target directory
TargetDirectory=${BaseDirectory}${Area}

# Build commands
Mkdir="/bin/mkdir -p ${Verbose} ${Filemode} ${TargetDirectory}"
Ln="/bin/ln -s ${TargetDirectory} ${Symlink}"

# Call mkdir, log command and capture output
if [ $Debug -eq 1 ]; then
    logger -p user.info -t $0 "${Mkdir}"
fi
Out=`${Mkdir} 2>&1`

# Log mkdir output if Debug is enabled
if [ ${Debug} -eq 1 ] && [ -n "${Out}" ] ; then
    logger -p user.info -t $0 ${Out}
fi

# Call ln, log command and capture output
if [ $Debug -eq 1 ]; then
    logger -p user.info -t $0 "${Ln}"
fi
Out=`${Ln} 2>&1`

# Log ln output if Debug is enabled
if [ ${Debug} -eq 1 ] && [ -n "${Out}" ] ; then
    logger -p user.info -t $0 ${Out}
fi

# Get last command error level
Errorlevel=$?

# Call errorlevel function (signal error to syslog)
errorlevel
