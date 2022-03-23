#!/bin/bash -xl

#Este script executa o modelo cosmo para as diferentes areas necessarias 
# outra para os prognosticos impares

# Script exec_cosmo.sh
#
#
#*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=


roda() {
curr_date=`cat /home/admcosmo/datas/datacorrente${HH}`

case ${AREA} in
   met)
WORKDIR=/home/admcosmo/cosmo/metarea5
RODADA='OPERACIONAL'
 if [ -z $HSTART ]
 then
 HSTART=00;
 fi

 if [ -z $HSTOP ]
 then
 HSTOP=96;
 fi

    ;;
   ant)
WORKDIR=/home/admcosmo/cosmo/antartica
RODADA='OPERACIONAL'
 if [ -z $HSTART ]
 then
 HSTART=00;
 fi

 if [ -z $HSTOP ]
 then
 HSTOP=96;
 fi
    ;;
   sse)
WORKDIR=/home/admcosmo/cosmo/sse
RODADA='OPERACIONAL'
 if [ -z $HSTART ]
 then
 HSTART=00;
 fi

 if [ -z $HSTOP ]
 then
 HSTOP=48;
 fi
    ;;
esac

curr_date=`cat /home/admcosmo/datas/datacorrente${HH}`
FILE=$WORKDIR/runlog/runlog_${AREA}_${curr_date}${HH}_${RANDOM}

#if [ $AREA == "sse" ] && [ $HH == "12" ];then

#	echo NAO ESTOU RODANDO O COSMOSSE EM 12Z!!!!

#else
	/home/admcosmo/cosmo/scripts/05.1_exec_cosmo.sh ${AREA} $HH $HSTART $HSTOP > $FILE 2>&1

#fi
}


if [ $# -eq 1 ];then

	HH=$1
	AREA=met
	roda
	HSTART=''
	HSTOP=''
	AREA=sse
	sleep 60
	roda
        HSTART=''
        HSTOP=''
        AREA=ant
        roda

elif [ $# -eq 4 ];then

	AREA=$1
	HH=$2
	HSTART=$3
	HSTOP=$4
	roda

else

	echo "Voce deve entrar com 1 ou 4 parametros. Se optar por 1 informe a hora de referencia, se optar por 4 entre com a area modelada (met ou ant), com o horario de referencia (00 ou 12), horario inicial e final"
	exit 12

fi

#/data1/cosmo_rerun/scripts/exec_rerun.sh > /data1/cosmo_rerun/log_rerun/rerun_`date +%Y%m%d%T`.log 2>&1
