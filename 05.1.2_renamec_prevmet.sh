#!/bin/bash 
#
#  Script rename_prevmet.sh
#
#  Script para modificar os nomes dos arquivos de previsao
#  do modelo cosmo, de HH Z, para a metarea5 
#
#
# CT(T) Leandro - Adaptado para renomear a medida que os arquivos sao gerados

#*****************************************************************************
#  passo 1 - verifica a hora de referencia
#

if [ $# -lt 4 ];then
   echo "Entre com  a area, o horario da rodada (00 ou 12), o prognostico inicial e final  das rodadas !!!"
   exit 12
fi

AREA=$1
HH=$2
HSTART=$3
HSTOP=$4

case $AREA in

met)
WORKDIR='/home/admcosmo/cosmo/metarea5'
AREA2=met5
INT=3
;;
ant)
WORKDIR='/home/admcosmo/cosmo/antartica'
AREA2=ant
INT=3
;;
#sse)
#WORKDIR='/home/admcosmo/cosmo/sse'
#AREA2=sse
#INT=1
#;;
*)
echo " Area nao cadastrada "
exit 12
;;
esac


#*****************************************************************************
#  passo 2 - Define variaveis.
#
#
data_corr=`cat ~/datas/datacorrente$HH`
new_name=cosmo_${AREA2}_${HH}_${data_corr}
#INT=3
#
#*****************************************************************************
#  passo 3 - altera nomes dos arquivos.
#
# 
HREF=0
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
     arquivo_z=lfff${FILE}0000z
     arquivo_c=lfff${FILE}0000c

     cd ${WORKDIR}/data/prevdata$HH
 
    flag=1
    n=1
    
    while [ $flag -eq 1 ]
 do

    if [ -s $arquivo_m ] && [ -s $arquivo_p ]
    then
         sleep 5
         mv ./${arquivo_m} ./${new_name}${HORA}
         mv ./${arquivo_p} ./${new_name}${HORA}p
         mv ./${arquivo_z} ./${new_name}${HORA}z
         ln -sf ./${new_name}${HORA} ./${arquivo_m}
         
        if [ $HREF -eq 0 ]
           then
             cp ./${arquivo_c} ./${new_name}${HORA}c
        fi 
        flag=0 
    
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

#   cd ${WORKDIR}/data/oleo$HH
   
#    flag=1
#    n=1

#    while [ $flag -eq 1 ]
#    do

#    if [ -s $arquivo_nc ] 
#    then
#         mv ./${arquivo_nc} ./${new_name}${HORA}
#         flag=0
     
#     else

#       sleep 30
#       n=$((n+1))

#       if [ $n -gt 480 ]
#       then
#          echo " Aguardei durante 4 horas o prognostico $HREF h "
#          exit 12
#       fi
 
#       fi
   
#   done
###Teste para o vento da Andressa feito em 16JAN2017#####
     
#    cd ${WORKDIR}/data/vento$HH
#    arquivo_mvento=lfff${FILE}0000.nc
#    INT=1
#    flag=1
#    n=1

#    while [ $flag -eq 1 ]
# do

#    if [ -s $arquivo_mvento ];then
#         ln -sf ./${new_name}${HORA} ./${arquivo_mvento}

#   else

#       sleep 30
#       n=$((n+1))

#       if [ $n -gt 480 ]
#       then
#          echo " Aguardei durante 4 horas o prognostico $HREF h "
#          exit 12
#     fi
 #   fi
#done


temp_href=`expr $HREF + $INT`
HREF=$temp_href


   done


