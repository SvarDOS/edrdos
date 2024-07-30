#!/bin/sh

if [ $1 = "singlefile" ]; then
	FLAGS="SINGLEFILE=1"
fi

wmake -h clean all $FLAGS GIT_REV=$(git rev-parse --short HEAD)
