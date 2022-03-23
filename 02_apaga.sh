#!/bin/bash
set -x
# Este script deve ser executado antes da rodada operacional do GME2COSMO

if [ $# -ne 2 ]
then
echo " Entre com a area e o horario de referencia HH"
exit 12
fi

HH=$2
AREA=$1

case $AREA in
met)
WORKDIR='/home/admcosmo/cosmo/metarea5'
;;
ant)
WORKDIR='/home/admcosmo/cosmo/antartica'
;;
inmet)
WORKDIR='/home/admcosmo/cosmo/inmet28'
;;
sse)
WORKDIR='/home/admcosmo/cosmo/sse'
;;
esac

if ! [ $AREA == "inmet" ];then

	rm -f ${WORKDIR}/data/icondata/data${HH}/ICONf*
        rm -f ${WORKDIR}/data/icondata/data${HH}/i?f*  
        rm -f ${WORKDIR}/data/init_cond${HH}/laf*
	rm -f ${WORKDIR}/data/init_cond${HH}/LM?_*
	rm -f ${WORKDIR}/data/init_cond${HH}/lrff*o
	rm -f ${WORKDIR}/data/init_cond${HH}/lbff*
	rm -f ${WORKDIR}/data/init_cond${HH}_2/laf*
	rm -f ${WORKDIR}/data/init_cond${HH}_2/LM?_*
	rm -f ${WORKDIR}/data/init_cond${HH}_2/lbff*
	rm -f ${WORKDIR}/data/restart${HH}/lrff*o
	rm -f ${WORKDIR}/data/prevdata${HH}/l*
	rm -f ${WORKDIR}/data/prevdata${HH}/cosmo*
	rm -f ${WORKDIR}/data/vento$HH/*

else
	rm -f ${WORKDIR}/data/prevdata${HH}/lf*
	rm -f ${WORKDIR}/data/prevdata${HH}/cosmo_inmet*

fi

if [ $AREA == "met" ];then

	rm -f ${WORKDIR}/data/ceste_$HH/*
	rm -f ${WORKDIR}/data/hycom_$HH/*
	rm -f ${WORKDIR}/data/sarmap$HH/*
        rm -f ${WORKDIR}/data/backup$HH/*
fi

if [ $AREA == "ant" ]; then
        rm -f ${WORKDIR}/data/backup$HH/*
fi
