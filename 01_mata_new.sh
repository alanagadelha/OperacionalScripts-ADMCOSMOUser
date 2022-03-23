#!/bin/bash -x

# Este script mata o cosmo em cada um dos nos

cd /data1/cosmo_rerun/scripts/

kill -9 $(ps -ef | grep rerun | grep -v rerun2 | grep -v mata |  awk '{ print $2 }')

kill -9 $(ps -ef | grep cosmo | awk ' { if ($3 == 1) print $2 }')

/opt/c3/bin/cexec -f nos_cosmo.txt killall cosmo
/opt/c3/bin/cexec -f nos_cosmo.txt killall icon2cosmo

/opt/c3/bin/cexec -f nos_cosmo.txt kill -9 $(ps -ef | grep cosmo | awk '{ print $2 }')


HH=`cat /data1/cosmo_rerun2/metarea5/cosmo/HH.txt`
datacorr=`cat /data1/cosmo_rerun2/datas/datacorrente${HH}`

/data1/cosmo_rerun2/scripts/verif.sh ${cur_date} ${HH} &
