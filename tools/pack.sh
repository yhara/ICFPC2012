#! /bin/sh

set -xe

cd `dirname $0`/../dist
tar cfz ../icfp-95754150.tgz .
echo wrote icfp-95754150.tgz
