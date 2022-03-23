#!/bin/bash -x
#
#  Script rename_prevmet.sh
#
#  Script para modificar os nomes dos arquivos de previsao
#  do modelo cosmo, de HH Z, para a metarea5 
#
#
# CT(T) Leandro - Adaptado para renomear a medida que os arquivos sao gerados
# Modificado por CT(T)Alexandre Gadelha e CT(T)Alana.
#*****************************************************************************
#  passo 1 - verifica a hora de referencia
#

if [ $# -lt 4 ];then
   echo "Entre com  a area, o horario da rodada (00, 06, 12 ou 18), o prognostico inicial e final  das rodadas !!!"
   exit 12
fi
#RODADA="Teste"
RODADA="Operacional"
AREA=$1
HH=$2
HSTART=$3
HSTOP=$4

case $AREA in

met)
WORKDIR='/home/admcosmo/cosmo/metarea5'
AREA2=met5
INT=1
;;
sse22)
WORKDIR='/home/admcosmo/cosmo/sse'
HSTART_ref=48
AREA2=sse22
INT=1
;;
esac


#*****************************************************************************
#  passo 2 - Define variaveis.
#
#
data_corr=`cat ~/datas/datacorrente$HH`
new_name=cosmo_${AREA2}_${HH}_${data_corr}
#
#*****************************************************************************
#  passo 3 - altera nomes dos arquivos.
#
# 
HREF=`echo "$HSTART * 1 " | bc`
DIG='0'


while [ $HREF -le $HSTOP ]; do

      if [ $HREF -lt 10 ];then
         HORA=0$DIG$HREF
      elif [ $HREF -lt 100 ];then
         HORA=$DIG$HREF
      else
         HORA=$HREF
      fi

      dia=`expr $HREF / 24`
      if [ $dia -lt 10 ];then
       DD=0$dia
     else
       DD=$dia
     fi

     hora=`expr $HREF - $dia \* 24`
     if [ $hora -lt 10 ];then
        HR=0$hora
     else
        HR=$hora
     fi

     FILE=$DD$HR

     arquivo_m=lfff${FILE}0000
     arquivo_p=lfff${FILE}0000p
     arquivo_c=lfff${FILE}0000c
     arquivo_z=lfff${FILE}0000z

     cd ${WORKDIR}/data/prevdata$HH
 
     flag=1
     n=1
    
    while [ $flag -eq 1 ]
    do

#       eval ARQm=$ARQFLAGm
#	eval ARQp=$ARQFLAGp
#	eval ARQz=$ARQFLAGz
       resto=`expr $HREF % 1`
    
        if [ -s $arquivo_m ] && [ -s $arquivo_p ];then

            sleep 2
      
            if [ $resto -eq 0 ]
            then 
                mv ./${arquivo_m} ./${new_name}${HORA}
                mv ./${arquivo_p} ./${new_name}${HORA}p
                mv ./${arquivo_z} ./${new_name}${HORA}z
            fi

             if [ $HREF -eq 0 ]
             then
                mv ./${arquivo_c} ./${new_name}${HORA}c
             fi
MSG="PRONTO PROG ${HORA}h DO COSMO${AREA} ${data_corr} ${HH}Z "
/usr/bin/input_status.php cosmosse ${HH} ${RODADA} AMARELO "${MSG}"
            flag=0 

#	     MSG="PRONTO PROG ${HORA}h DO COSMO${AREA} ${data_corr} ${HH}Z "
#	     /usr/bin/input_status.php cosmo${AREA} ${HH} ${RODADA} AMARELO "${MSG}"
    
        else
    
            sleep 30
            n=$((n+1))

            if [ $n -gt 480 ]
            then
              echo " Aguardei durante 4 horas o prognostico $HREF h "
             exit 12
           fi
 
       fi
   

    done

temp_href=`expr $HREF + $INT`
HREF=$temp_href


done
