!#/bin/sh

wmake -h clean kernel.svp SINGLEFILE=1 VERSION=$(date +%Y%m%d) GIT_REV=$(git rev-parse --short HEAD)

