!#/bin/sh

wmake -h clean kernledr.svp SINGLEFILE=1 VERSION=$(date +%Y%m%d) GIT_REV=$(git rev-parse --short HEAD)

