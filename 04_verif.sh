#!/bin/bash
set -x
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

	if [ -z $HSTART ]
	then
 	HSTART=00;
 	fi

 	if [ -z $HSTOP ]
 	then
 	HSTOP=48;
 	fi
;;
  ant)
WORKDIR=/home/admcosmo/cosmo/antartica

 	if [ -z $HSTART ]
 	then
 	HSTART=00;
 	fi

 	if [ -z $HSTOP ]
 	then
 	HSTOP=96;
 	fi
;;
esac

if [ ${AREA} == sse ];then
FILE=$WORKDIR/verif_log/verif_${AREA}_${curr_date}${HH}_${RANDOM}
/home/admcosmo/cosmo/scripts/04.1_nos_icon.sh ${AREA}
/home/admcosmo/cosmo/scripts/04.3_verif_icondata_with_sse.sh $AREA $HH $HSTART $HSTOP | tee /home/admcosmo/cosmo/sse/verif_log/verif_${AREA}_${curr_date}${HH}

else
FILE=$WORKDIR/verif_log/verif_${AREA}_${curr_date}${HH}_${RANDOM}
/home/admcosmo/cosmo/scripts/04.1_nos_icon.sh ${AREA}
/home/admcosmo/cosmo/scripts/04.2_verif_icondata.sh $AREA $HH $HSTART $HSTOP pares >  $FILE 2>&1 &

FILE=$WORKDIR/verif_log/verif_${AREA}_${curr_date}${HH}_${RANDOM}
/home/admcosmo/cosmo/scripts/04.2_verif_icondata.sh $AREA $HH $HSTART $HSTOP impares > $FILE 2>&1
fi
}

if [ $# -eq 1 ]; then

HH=$1

AREA=met
	roda
AREA=sse
                #############################################################################
                #                                                                           #
                # Verifica o termino da rodada do COSMO MET antes de disparar o COSMO 2.2KM #
                #									    #
                #############################################################################
sleep 60
                RFILE=/home/admcosmo/cosmo/metarea5/data/prevdata${HH}/lfff03000000
                nmax=240
                n=0

                flag=1

                while [ $flag -eq 1 ];do

                        if [ -e ${RFILE} ]; then
				
                                echo " Encontrei o arquivo ${RFILE} que eh o ultimo horario do COSMO MET. Vou disparar o COSMO 2.2km"
                                flag=0
				roda
			else

                                n=`expr $n + 1`
                                sleep 60

                        fi

                        if [ $n -ge $nmax ];then

                                echo " Aguardei o arquivo ${RFILE} do COSMO por $nmax minutos. Vou abortar o lancamento do COSMO 2.2km."
                                echo " Houston, we have a problem!!!"
                                flag=0
				/home/admcosmo/cosmo/scripts/01_mata_new.sh

                        fi

                done
AREA=ant
	roda
fi

if [ $# -eq 4 ]
then
	AREA=$1
	HH=$2
	HSTART=$3
	HSTOP=$4
	roda
else
     echo "Voce deve entrar com 1 ou 4 parametros. Se optar por 1 informe a hora de referencia, se optar por 4 entre com a area modelada (met, ant ou sse), com o horario de referencia (00 ou 12), horario inicial e final"
     exit 12
fi
