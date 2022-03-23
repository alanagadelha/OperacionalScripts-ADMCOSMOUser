#!/bin/bash -x

############################################################
#
# Script para comprimir os dados GRIB de saida do COSMO ANT
# para que sejam transferidos para a area de backup definitivo.
# Foi criado pela 1T(RM2-T)Ten Priscila Luz em 07NOV2018 
############################################################

AREA1=$1
HH=$2

if [ $# -ne 2 ];then

	echo " Entre com o area e horario de referencia 00 ou 12 "
	exit

fi

WORKDIR=/home/admcosmo/cosmo/${AREA1}
#A area precisa ser antartica (nome do dir que esta no /cosmo/
dflag=${WORKDIR}/data/ready${HH}
dtrab=${WORKDIR}/data/backup${HH}
DADOSORIPREF="cosmo_ant_${HH}"
datamaq=`cat /home/admcosmo/datas/datacorrente${HH} `
#datamaq=20201016
SUFIX=".tar.bz2"

cd ${dtrab}

if [ -s ${dtrab}/${DADOSORIPREF}_${datamaq}000 ];then

	echo ""
	echo " Encontrei o arquivo ${dtrab}/${DADOSORIPREF}_${datamaq}000"
	echo " Vou iniciar o backup do COSMO ${AREA1} para ${HH}."
	echo ""
        datarq=`/home/admcosmo/cosmo/bin/wgrib -v ${DADOSORIPREF}_${datamaq}000 | cut -d":" -f3 | cut -d"=" -f2 | head -1 | cut -c1-8`
        echo " Carreguei a data do arquivo $datarq "

	if [ ${datamaq} -eq ${datarq} ];then

                # HORA inicial
                HSTART=000

                # Calcula o horario final

                echo " Calculando o horario final."

                nhora=`ls -ltr ${DADOSORIPREF}_${datamaq}??? | wc -l`
                ult_hora=`echo "( ${nhora} * 3 - 3 )" | bc`
                HSTOP=${ult_hora}

		DIG=0

                if [ ${HSTOP} -lt 10 ];then
	                HSTOP=0$DIG$HSTOP
                elif [ $HSTOP -lt 100 ];then
	                HSTOP=$DIG$HSTOP
                else
	                HSTOP=$HSTOP
                fi

                echo " O horario final eh ${HSTOP}."

                # define os horarios que serao trabalhados
                # de acordo com o intervalo INT.

		INT=3

                for HREF in `seq $HSTART $INT $HSTOP`
                do

			if [ $HREF -lt 10 ];then
                        	HORA=0$DIG$HREF
                        elif [ $HREF -lt 100 ];then
                        	HORA=$DIG$HREF
                        else
                        	HORA=$HREF
                        fi

                        str="${str} ${HORA}"

                        if [ -f ${dtrab}/${DADOSORIPREF}_${datamaq}${HORA} ];then

                                if [ ${HORA} == 000 ];then

                                        echo
                                        echo ${DADOSORIPREF}_${datamaq}${HORA}  >> ${dtrab}/horarios_${HH}_${datamaq}
                                        echo ${DADOSORIPREF}_${datamaq}${HORA}c >> ${dtrab}/horarios_${HH}_${datamaq}
                                        echo ${DADOSORIPREF}_${datamaq}${HORA}p >> ${dtrab}/horarios_${HH}_${datamaq}
                                        echo ${DADOSORIPREF}_${datamaq}${HORA}z >> ${dtrab}/horarios_${HH}_${datamaq}

                                else

                                        echo
                                        echo ${DADOSORIPREF}_${datamaq}${HORA}  >> ${dtrab}/horarios_${HH}_${datamaq}
                                        echo ${DADOSORIPREF}_${datamaq}${HORA}p >> ${dtrab}/horarios_${HH}_${datamaq}
                                        echo ${DADOSORIPREF}_${datamaq}${HORA}z >> ${dtrab}/horarios_${HH}_${datamaq}

                                fi

                        else

                                echo
                                echo " Nao encontrei o arquivo ${dtrab}/${DADOSORIPREF}_${datamaq}${HORA}"

                        fi
		done

        	arquivos=`cat ${dtrab}/horarios_${HH}_${datamaq} | tr ' ' '\012' | sort | uniq | tr '\012' ' '`
		echo $arquivos | wc -w

                echo
                echo " Targeando arquivos."

                tar cjvf ${dtrab}/cosmoant_10km_${HH}_${datamaq}${SUFIX} ${arquivos}
		#cp ${dtrab}/cosmoant_10km_${HH}_${datamaq}${SUFIX} /data2/backup_cosmo/antartica/dados${HH}
		#mv ${dtrab}/horarios_${HH}_${datamaq} /data2/backup_cosmo/antartica/dados${HH}
		#cp ${dtrab}/cosmoant_10km_${HH}_${datamaq}${SUFIX} /mnt/nfs/dpns33/data1/backup/backup_cosmo/antartica/dados${HH}
		rsync -av --ignore-existing ${dtrab}/cosmoant_10km_${HH}_${datamaq}${SUFIX} /mnt/nfs/dpns33/data1/backup/backup_cosmo/antartica/dados${HH}/
		mv ${dtrab}/horarios_${HH}_${datamaq} /mnt/nfs/dpns33/data1/backup/backup_cosmo/antartica/dados${HH}
	else

		echo " As datas nao coincidem"
		echo " datamaq eh ${datamaq} e"
		echo " dataarq eh ${datarq}."
	fi

else

	echo " Nao encontrei o arquivo ${dtrab}/${DADOSORIPREF}_${datamaq}000."
	
fi
