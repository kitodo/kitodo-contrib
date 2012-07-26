#!/bin/sh

LOG="/var/log/indexer.log"

LOCK="/var/lock/indexer.lock"

if [ ! -e "$LOCK" ]

then

	touch $LOCK

	echo -n "START: " >> $LOG

	date >> $LOG

	php /var/www/process/indexer.php >> $LOG

	echo -n "DONE: " >> $LOG

	date >> $LOG

	echo -e "\n" >> $LOG

	rm $LOCK

fi
