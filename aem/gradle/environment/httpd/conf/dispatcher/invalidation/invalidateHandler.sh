#!/bin/bash

printf "%-15s: %s %s\n" $1 $2 $3 >> /usr/local/apache2/logs/dispatcher.log

exit 0
