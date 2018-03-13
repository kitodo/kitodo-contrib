#!/usr/bin/env bash
#
# (c) 2018 Technische Universität Berlin
#
# This software is licensed under GNU General Public License version 3 or later.
#
# For the full copyright and license information,
# please see https://www.gnu.org/licenses/gpl-3.0.html or read
# the LICENSE.txt file that was distributed with this source code.
#

###########################
#
# Supplies a method for logging and admin email if necessary.
#
###########################

LOG_FILE="/path/to/log/file.log"
MAIL_ADDRESS=
MAIL_SUBJECT="Kitodo Production Script Error"

VERBOSITY=6 #Default show info
MAIL_LEVEL=3 #Mail send at this level

error() { log 3 "ERROR: $1"; }
warn() { log 4 "WARN: $1"; }
info() { log 6 "INFO: $1"; }
debug() { log 7 "DEBUG: $1"; }

# $1: Log level
# $2: Log message
log() {
    if [ $VERBOSITY -ge $1 ]; then
        TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
        echo "$TIMESTAMP - $2" >> $LOG_FILE
    fi
    if [[ $MAIL_LEVEL -ge $1  && ! -z $MAIL_ADDRESS ]]; then
        mail -s $MAIL_SUBJECT $MAIL_ADDRESS <<< "$TIMESTAMP - $2"
    fi
}
