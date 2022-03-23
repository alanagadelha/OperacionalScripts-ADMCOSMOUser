#!/bin/bash
#############################################
#
# Script para extracao de dados GRIB, visando
# reduzir trabalho de I/O do HRM. Inicialmente
# o diretorio de origem dos dados sera o da
# rodada operacional do HRM definido como
# $DIRDADOSORI. Esta pronto para remover os 
# dados do SMAP do dia corrente.
#
# Escrito em 21MAR2012
#
# Autor: 1T(T) Alexandre Gadelha
#
#############################################

#############################################
#
# Verifica se foi passado o horario da rodada
#
#############################################

if [ "$#" -ne 4 ]
then
     echo "Entre com a area, o horario da rodada (00 ou 12), o prognostico inicial e final de previsao !"
     exit 12
fi

AREA=$1
HH=$2
HSTART=$3
HSTOP=$4

#############################################
#
# DIRDADOSORI eh o diretorio de origem de onde
# serao extraidos os dados do GRIB
#
# DIRDADOSEXT eh o diretorio de destino para
# onde serao salvos os dados extraidos.
#
#############################################

case $AREA in

met)
WORKDIR='/home/admcosmo/cosmo/metarea5'
AREA2="met5"
;;
ant)
WORKDIR='/home/admcosmo/cosmo/antartica'
AREA2="ant"
;;
sse)
WORKDIR='/home/admcosmo/cosmo/sse'
AREA2="sse"
;;
esac

curr_date=`cat /home/operador/datas/datacorrente${HH}`
DIRDADOSORI=$WORKDIR/data/prevdata$HH
DADOSORIPREF="cosmo_${AREA2}_${HH}_$curr_date"


wgrib=/home/admcosmo/cosmo/bin/wgrib

DIG='0'

for HREF2 in `seq $HSTART 3 $HSTOP`
do

   if [ $HREF2 -lt 10 ];then
      HORA=0$DIG$HREF2
   elif [ $HREF2 -lt 100 ];then
      HORA=$DIG$HREF2
   else
      HORA=$HREF2
   fi

   str2="${str2} ${HORA}"

done

# Lendo os arquivos que serao extraidos a partir do arquivo de output do ajustes

cat $WORKDIR/ajustes/outputs.txt | sed -e '/#/d' > output_raw.txt 
nl=`cat output_raw.txt | wc -l`
currdir=`pwd`

###################################################
#
# Entra no diretorio de origem e executa o WGRIB 
# para todos os horarios dentro de $str2
#
###################################################

cd ${DIRDADOSORI}

for HORA in `echo ${str2}`
do

    FLAG="false"
    ntimes=0

    while [ $FLAG == "false" ] && [ $ntimes -lt 240 ]
    do

          if [ -e ${DADOSORIPREF}${HORA} ]
          then

                   datagrib=`${wgrib} -v ${DADOSORIPREF}${HORA} | head -1 |cut -d: -f3 | cut -d= -f2`

                   if [ ${datagrib} == ${curr_date}${HH} ]
                   then
                        echo
                        echo " Fazendo horario ${HORA} de ${datagrib} "
                        echo

                        for i in `seq 1 $nl`
                        do

                          linha=`head -$i ${currdir}/output_raw.txt | tail -1`
                          DIRDADOSEXT=$WORKDIR/data/`echo $linha | cut -f1 -d" "`${HH}
                          extrair=`echo $linha | cut -f2 -d" "`	
                          $wgrib ${DADOSORIPREF}${HORA} | egrep "${extrair}" | $wgrib -i -grib ${DADOSORIPREF}${HORA} -o ${DIRDADOSEXT}/${DADOSORIPREF}${HORA}

                       done
                       FLAG="true"

                   else

                       echo " Para o prognostico ${HORA} a data corrente eh ${curr_date}${HH} e a data do grib eh ${datagrib} "

                   fi

           else

                 echo " Arquivo nao prontificado ainda "
                 echo
                 ntimes=$((ntimes+1))
                 sleep 60
           fi


           if [ $ntimes -eq 240 ]
           then
              echo " Apos 4 horas esperando pelo PROG $HORA abortei este script "
              exit 12
           fi

     done


done

rm ${currdir}/output_raw.txt
