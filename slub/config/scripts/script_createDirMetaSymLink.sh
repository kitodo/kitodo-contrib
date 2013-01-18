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
PartitionNumber=`expr $ProcessId / 10000`
PartitionDirectory=${BaseDirectory}/partitions/${PartitionNumber}/${ProcessId}

# Determine Symlink
Symlink=${BaseDirectory}/${ProcessId}
SymlinkTarget=./partitions/${PartitionNumber}/${ProcessId}

# Skip symlink creation if there is a directory with the same name already
if [ ! -d ${Symlink} ] ; then

# Create partition directory
	if [ ! -d ${PartitionDirectory} ]; then

	    Mkdir="/bin/mkdir -p ${Verbose} ${Filemode} ${PartitionDirectory}"

	    # Call mkdir, log command and capture output
	    if [ $Debug -eq 1 ]; then
		logger -p user.info -t $0 "${Mkdir}"
	    fi
	    Out=`${Mkdir} 2>&1`

	    # Get last command error level
	    Errorlevel=$?

	    # Log mkdir output if Debug is enabled
	    if [ ${Debug} -eq 1 ] && [ -n "${Out}" ] ; then
		logger -p user.info -t $0 "${Out}"
	    fi

	    # Call errorlevel function (signal error to syslog)
	    errorlevel

	fi

# Create symlink to partition directory
	if [ ! -L ${Symlink} ]; then

	    Ln="/bin/ln ${Verbose} -s ${SymlinkTarget} ${Symlink}"

	    # Call ln, log command and capture output
	    if [ $Debug -eq 1 ]; then
		logger -p user.info -t $0 "${Ln}"
	    fi
	    Out=`${Ln} 2>&1`

	    # Get last command error level
	    Errorlevel=$?

	    # Log ln output if Debug is enabled
	    if [ ${Debug} -eq 1 ] && [ -n "${Out}" ] ; then
		logger -p user.info -t $0 "${Out}"
	    fi

	    # Call errorlevel function (signal error to syslog)
	    errorlevel

	fi
fi

# Create final directory through symlink (or existing base directory)
if [ ! -d ${Directory} ]; then

    Mkdir="/bin/mkdir -p ${Verbose} ${Filemode} ${Directory}"

    # Call mkdir, log command and capture output
    if [ $Debug -eq 1 ]; then
        logger -p user.info -t $0 "${Mkdir}"
    fi
    Out=`${Mkdir} 2>&1`

    # Get last command error level
    Errorlevel=$?

    # Log mkdir output if Debug is enabled
    if [ ${Debug} -eq 1 ] && [ -n "${Out}" ] ; then
        logger -p user.info -t $0 "${Out}"
    fi

    # Call errorlevel function (signal error to syslog)
    errorlevel

fi
