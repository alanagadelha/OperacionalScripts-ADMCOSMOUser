#!/bin/bash -x

# Este script mata o cosmo em cada um dos nos

for iru in `seq 0 1`
do
for no in `seq 0 17`
do
ssh r1i${iru}n${no} 'killall cosmo'
done
done

for arq in `ps -ef | grep renamec | awk ' { print $2 } '` ; do kill -9 $arq ; done
