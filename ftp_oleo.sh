#!/bin/bash
set -x
# Este script sera executado apos a rodada operacional do COSMO

if [ $# -ne 1 ]
then
echo " Entre com a area e o horario de referencia HH"
exit 12
fi

HH=$2
WORKDIR=/home/admcosmo/cosmo/metarea5/data/oleo${HH}

cd ${WORKDIR}

#if ! [ $AREA == "inmet" ];then

#	rm -f ${WORKDIR}/data/icondata/data${HH}/ICONf*

#else
#	rm -f ${WORKDIR}/data/prevdata${HH}/lf*

#fi

lftp --user guest --pass "M@r!nh@" dpas06 << endftp1

date

mkdir ${date}

lcd /home/admcosmo/cosmo/metarea5/data/oleo${HH}
mput lf*.nc
bye
endftp1


