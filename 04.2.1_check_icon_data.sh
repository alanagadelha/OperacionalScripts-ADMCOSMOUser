#!/bin/bash
set -x
#
# Script check_gmedata_date.sh
#
# Script que verifica se os dados do GME para o COSMO  jah 
# comecaram a ser recebidos.
#
# Autor: CT Leandro Machado
# Data: 17OUT2012
# Modificado: CT Alana.
#*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=
# Passo 1 - Recebe os parametros
#
if [ $# -ne 2 ];then
     echo "Entre com a area e o Prognostico (00Z ou 12Z)!!!!!"
     exit 12
fi
RODADA=Operacional
AREA=$1
HH=$2

#*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=
# Passo 2 - Define variaveis
#
case $AREA in
met)
AREA1=metarea5
;;
ant)
AREA1=antartica
;;
sse)
AREA1=sse
;;
esac

curr_date=`cat /home/admcosmo/datas/datacorrente${HH}`
datetimeana=${curr_date}${HH}
WORKDIR=/home/admcosmo/cosmo/${AREA1}
ICONDIR='/home/admcosmo/cosmo/icondata'

echo $WORKDIR

#*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=
# Passo 3 - verifica se o flag do recebimento dos arquivos jah
#           nao existe ou se o arquivo icon_new.bz2 nao existe.
#
if ! [ -s ${ICONDIR}/${AREA}_${HH}/icon_new.bz2 ];then
   echo "O arquivo icon_new.bz2 nao existe (nao chegou)!!!"

   exit 12
fi
if [ -s ${WORKDIR}/data/icondata/flags/ICONDATA_${datetimeana} ];then
   echo "O flag jah foi gerado!!!"

   exit 12
fi
#
#*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=
# Passo 4 -  Verifica se os arquivos jah comecaram a ser recebidos
#            checando a data dentro do arquivo gme_new.
#
cd ${WORKDIR}/data/icondata/data${HH}
cp -f ${ICONDIR}/${AREA}_${HH}/icon_new.bz2 .
date
bunzip2 -f icon_new.bz2
dataf=`head -n1  icon_new`
HH1=`head -n2 icon_new > raw.txt`
echo "$raw.txt" 
HHf=`tail -n1 raw.txt`
if [ ${datetimeana} == ${dataf}${HHf} ];then
   echo `date` -  Os Arquivos jah estao chegando
   echo `date` -  Inicio recebimendo dos dados do ICON >  ${WORKDIR}/data/icondata/flags/ICONDATA_${datetimeana}

#########################################################
#    Atualizando o status da rodada - Inicio
#########################################################
           MSG="Dados ICON p/ COSMO${AREA} ${curr_date} ${HH}Z foi iniciada"

           #/usr/bin/input_status.php verif_${AREA} ${HH} ${RODADA} AMARELO "${MSG}"

else

#########################################################
#    Atualizando o status da rodada - Inicio
#########################################################
           MSG="Dados ICON p/ COSMO${AREA} ${curr_date} ${HH}Z nao chegaram"

           #/usr/bin/input_status.php verif_${AREA} ${HH} ${RODADA} AMARELO "${MSG}"

   echo Os arquivos ainda nao chegaram
fi
rm -f icon_new.bz2 icon_new

