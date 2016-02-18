#!/bin/bash

while pgrep -f /opt/xensource/installer/init > /dev/null;
do
	sleep 2
done

