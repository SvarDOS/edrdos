#!/bin/sh

# Helper build-script to inject current Git revision into the build process
# and build the kernel


if ! command -v git >/dev/null 2>&1; then
	echo "error: git not found";
	exit 1
fi

if [ "$1" = "singlefile" ]; then
	FLAGS="SINGLEFILE=1"
elif [ "$1" = "dualfile" ]; then
	FLAGS="SINGLEFILE=0"
else
	FLAGS="SINGLEFILE=1"
fi

wmake -h clean all $FLAGS VERSION=$(date +%Y%m%d) GIT_REV=$(git rev-parse --short HEAD)
