#!/bin/sh

LOG="/var/log/processing.log"

LOCK="/var/lock/processing.lock"

if [ ! -e "$LOCK" ]

then

	touch $LOCK

	echo -n "START: " >> $LOG

	date >> $LOG

	php /var/www/process/processing.php >> $LOG

	echo -n "DONE: " >> $LOG

	date >> $LOG

	echo -e "\n" >> $LOG

	rm $LOCK

fi
