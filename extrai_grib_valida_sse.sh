#!/bin/bash -x
#############################################
#
# Script para extracao de dados GRIB, com objetivo 
# de validar o modelo cosmo 2km!
# 
#
#  CB RAQUEL
#
#
#############################################

#############################################
#
# Verifica se foi passado o horario da rodada
#
#############################################

if [ "$#" -ne 3 ];then
     echo "Entre com o horario da rodada (00 ou 12), o prognostico inicial e final de previsao !"
     exit 12
fi

HH=$1
HSTART=$2
HSTOP=$3

#############################################
#
# DIRDADOSORI eh o diretorio de origem de onde
# serao extraidos os dados do GRIB
#
# DIRDADOSEXT eh o diretorio de destino para
# onde serao salvos os dados extraidos.
#
#############################################

# cria pasta com data do dia antes de jogar os gribs
data=`date +%Y%m%d`

mkdir /home/admcosmo/cosmo/metarea5/data/valida_${HH}/cosmo_sse_grib_$data


curr_date=`cat /home/operador/datas/datacorrente${HH}`
DIRDADOSORI=/home/admcosmo/cosmo/sse/data/prevdata$HH
DIRDADOSEXT=/home/admcosmo/cosmo/metarea5/data/valida_${HH}/cosmo_sse_grib_$data
DADOSORIPREF="cosmo_sse22_${HH}_$curr_date"
DADOSDESPREF="cosmo_sse22_${HH}_$curr_date"


wgrib=/home/admcosmo/cosmo/bin/wgrib

DIG='0'

for HREF2 in `seq $HSTART 12 $HSTOP`;do

   if [ $HREF2 -lt 10 ];then
      HORA=0$DIG$HREF2
   elif [ $HREF2 -lt 100 ];then
      HORA=$DIG$HREF2
   else
      HORA=$HREF2
   fi

   str2="${str2} ${HORA}"

done

##################################################
#
#Entra no diretorio de origem e executa o WGRIB 
# para todos os horarios dentro de $str2
#
###################################################

cd ${DIRDADOSORI}

for HORA in `echo ${str2}`
do

###################################################
#
#Significado das linhas abaixo:
#
# kpds5=2:kpds6=102       Extrai a pressao a superficie
# kpds5=11:kpds6=105    Extrai a T2m
# kpds5=33:kpds6=105    Extrai U_10M
# kpds5=34:kpds6=105    Extrai V_10M
# kpds5=61:kpds6=1      Extrai a Precip
#
###################################################

        echo
        echo " Extraindo os dados de precipitacao, temperatura, pressao e vento do horario ${HORA}"

         wgrib ${DADOSORIPREF}${HORA} | egrep "(kpds5=61:kpds6=1|kpds5=11:kpds6=105|kpds5=2:kpds6=102:kpds7=0|kpds5=33:kpds6=105|kpds5=34:kpds6=105)" \
       | wgrib -i -grib ${DADOSORIPREF}${HORA} -o ${DIRDADOSEXT}/${DADOSDESPREF}${HORA}

#       wgrib ${DADOSORIPREF}${HORA} | egrep "(kpds5=1:kpds6=1|kpds5=11:kpds6=105|kpds5=17:kpds6=105|kpds5=33:kpds6=105|kpds5=34:kpds6=105|kpds5=71)" | wgrib -i -grib ${DADOSORIPREF}${HORA} -o ${DIRDADOSEXT}/${DADOSDESPREF}${HORA}


done
