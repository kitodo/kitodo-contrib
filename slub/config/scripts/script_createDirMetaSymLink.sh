#!/bin/bash

# Enable logging
Debug=1

# Assemble options 
Verbose=
Filemode="-m 0775"

if [ ${Debug} -eq 1 ]; then
    Verbose="-v"
fi

# Include error level handling
source `dirname $0`/errorlevel.sh

# Exit with error if no parameter has been given
if [ -z "$1" ]; then
    logger -p user.info -t $0 "No directory given."
    exit 1
fi

# Fetch directory name from command-line argument and remove trailing slash
Directory=${1%/}

# Extract first number sequence as Goobi process ID
ProcessId=`expr match "$Directory" '[a-zA-Z0-9\/]*\/\([0-9]\+\)'`

# Base directory is Directory path up to Goobi process ID
BaseDirectory=${Directory%/$ProcessId*}

# Determine storage partition
PartitionDirectory=${BaseDirectory}"/partitions/"`expr $ProcessId / 10000`"/"${ProcessId}

# Determine Symlink
Symlink=${BaseDirectory}/${ProcessId}


# Create partition directory
if [ ! -d ${PartitionDirectory} ]; then

    Mkdir="/bin/mkdir -p ${Verbose} ${Filemode} ${PartitionDirectory}"

    # Call mkdir, log command and capture output
    if [ $Debug -eq 1 ]; then
        logger -p user.info -t $0 "${Mkdir}"
    fi
    Out=`${Mkdir} 2>&1`

    # Log mkdir output if Debug is enabled
    if [ ${Debug} -eq 1 ] && [ -n "${Out}" ] ; then
        logger -p user.info -t $0 "${Out}"
    fi

    # Get last command error level
    Errorlevel=$?

    # Call errorlevel function (signal error to syslog)
    errorlevel

fi

# Create symlink to partition directory
if [ ! -L ${Symlink} ]; then

    Ln="/bin/ln ${Verbose} -s ${PartitionDirectory} ${Symlink}"

    # Call ln, log command and capture output
    if [ $Debug -eq 1 ]; then
        logger -p user.info -t $0 "${Ln}"
    fi
    Out=`${Ln} 2>&1`

    # Log ln output if Debug is enabled
    if [ ${Debug} -eq 1 ] && [ -n "${Out}" ] ; then
        logger -p user.info -t $0 "${Out}"
    fi

    # Get last command error level
    Errorlevel=$?

    # Call errorlevel function (signal error to syslog)
    errorlevel

fi


# Create final directory through symlink
if [ ! -d ${Directory} ]; then

    Mkdir="/bin/mkdir -p ${Verbose} ${Filemode} ${Directory}"

    # Call mkdir, log command and capture output
    if [ $Debug -eq 1 ]; then
        logger -p user.info -t $0 "${Mkdir}"
    fi
    Out=`${Mkdir} 2>&1`

    # Log mkdir output if Debug is enabled
    if [ ${Debug} -eq 1 ] && [ -n "${Out}" ] ; then
        logger -p user.info -t $0 "${Out}"
    fi

    # Get last command error level
    Errorlevel=$?

    # Call errorlevel function (signal error to syslog)
    errorlevel

fi
