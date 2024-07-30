#!/bin/sh

# Helper build-script to inject current Git revision into the build process
# and build the kernel

if [ $1 = "singlefile" ]; then
	FLAGS="SINGLEFILE=1"
fi

wmake -h clean all $FLAGS GIT_REV=$(git rev-parse --short HEAD)
