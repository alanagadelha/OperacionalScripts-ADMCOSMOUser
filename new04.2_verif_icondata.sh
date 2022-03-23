#!/bin/bash
set -x
#
# Script verif_icondata.sh
#
# Script que verifica o recebimento dos dados do ICON do DWD
# necessarios para a rodada do COSMO 
#
#*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=
# Passo 1 - Recebe os parametros
#
if [ $# -lt 4 ]
then
 echo 'Entre com a area, o horario da rodada (00 ou 12) e com o prognostico de inicio e de fim da rodada (24, 48, 78, etc) ?'
 exit 12
fi

RODADA=Operacional
AREA=$1
HH=$2
HSTART=$3
HSTOP=$4

if [ $# -eq 5 ] 
then
PROGS=$5
DIV=2
   
   if [ $PROGS == "pares" ] 
   then
   resto=0
   fi

   if [ $PROGS == "impares" ] 
   then
   resto=1
   fi

else

DIV=1
resto=0

fi


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

#*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=
# Passo 2 - Define variaveis
#


curr_date=`cat /home/admcosmo/datas/datacorrente${HH}`
datetimeana=${curr_date}${HH}
WORKDIR='/home/admcosmo/cosmo'
ICONDIR='/home/admcosmo/cosmo/icondata'


for prog in `seq $HSTART 3 $HSTOP`
do

    if [ $prog -lt 10 ]
    then
        LISTA=`echo $LISTA" 0"$prog`
    else
        LISTA=`echo $LISTA" "$prog`
    fi

done


#*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=
# Passo 3 - Inicio do loop

for Href in $LISTA ;do
 
     r=`echo $Href % $DIV | bc`

     cont=0
   
      if [ $r -eq $resto ] 
      then  

     dia=`expr $Href / 24`

     if [ $dia -lt 10 ];then
         DD=0$dia
     else
          DD=$dia
     fi

     hora=`expr $Href - $dia \* 24`
     if [ $hora -lt 10 ];then
         HR=0$hora
      else
         HR=$hora
      fi

      FILE=$DD$HR

      FLAG=0

     while [ $FLAG -eq 0 ];do

   #*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=
   # Passo 5 - Roda o script que verifica a data do icon_new
   #         caso correta cria flag no diretorio data/icondata/flags
   #
           ${WORKDIR}/scripts/04.2.1_check_icon_data.sh ${AREA} ${HH}

   #*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=
   # Passo 4 - Verifica se os arquivos jah comecaram a ser recebidos
   #          pela existencia do arquivo no diretorio flags.
   #
           if ! [ -s ${WORKDIR}/${AREA1}/data/icondata/flags/ICONDATA_${datetimeana} ];then

           sleep 120
           continue  #Retorna para o inicio do while
           fi

   #*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=
   # Passo 5 - Inicia a geracao dos arquivos de contorno
   #

          FILE=$DD$HR
  
          [ -s ${ICONDIR}/${AREA}_${HH}/ig?ff${FILE}0000.bz2 ] && [ -e ${WORKDIR}/${AREA1}/data/icondata/data${HH}/ICONf${FILE}0000 ]
          erro=$?

          if [ $erro -ne 0 ]
          then
             > ${WORKDIR}/${AREA1}/data/icondata/data${HH}/ICONf${FILE}0000
             cp -f ${ICONDIR}/${AREA}_${HH}/ig?ff${FILE}0000.bz2 ${WORKDIR}/${AREA1}/data/icondata/data${HH}/
             /usr/bin/bunzip2 -f ${WORKDIR}/${AREA1}/data/icondata/data${HH}/ig?ff${FILE}0000.bz2
	    cp ${WORKDIR}/${AREA1}/data/icondata/data${HH}/ig?ff${FILE}0000 ${WORKDIR}/${AREA1}/data/const
	    /home/gast/intel_13.0.1/libraries/bin/grib_copy -wshortName=HHL ${WORKDIR}/${AREA1}/data/const/igfff00000000 ${WORKDIR}/${AREA1}/data/const/igfff00000000_newhhl
            dtfile=`/home/gast/intel_13.0.1/libraries/bin/grib_ls -p dataDate ${WORKDIR}/${AREA1}/data/icondata/data${HH}/ig?ff${FILE}0000 | head -3 | tail -1`
            dtfile=${dtfile%% *}
            echo $dtfile
                  if ! [ ${dtfile}${HH} -eq ${datetimeana} ];then
                  rm -f ${WORKDIR}/${AREA1}/data/icondata/data${HH}/ICONf${FILE}0000
                  FLAG=0
                  else
                  ${WORKDIR}/scripts/04.2.2_exec_icon2cosmo.sh ${AREA} ${HH} ${HSTART} ${Href} 
                    erro=$?
                  
                       if [ $erro -eq 0 ]
                       then

                       MSG="Pre-proc do COSMO${AREA} ${curr_date} ${HH}Z condicao de contorno ICONf${FILE}0000"

                       #/usr/bin/input_status.php verif_${AREA} ${HH} ${RODADA} AMARELO "${MSG}"

                       FLAG=1

                       else
                       rm -f ${WORKDIR}/${AREA1}/data/icondata/data${HH}/ICONf${FILE}0000

		       sleep 60
 
                       cont=`echo "$cont + 1" | bc`

                       if [ $cont -eq 240 ]
                       then 
                       MSG="Pre-proc do COSMO${AREA} ${curr_date} ${HH}Z Falha na condicao de contorno ICONf${FILE}0000"

                       #/usr/bin/input_status.php verif_${AREA} ${HH} ${RODADA} VERMELHO "${MSG}"
                       exit 12 
                       fi
 
                       FLAG=0

                       fi
                  fi
         else
         FLAG=1  
         fi
     done


 fi

done
sleep 3
#narq= ${WORKDIR}/${AREA1}/data/icondata/data${HH}/ls -la|grep -e "^-"|wc -l
if [ -e ${WORKDIR}/${AREA1}/data/icondata/data${HH}/ICONf04000000 ]
#if [ narq == 67 ]
then
MSG="Pre-proc do COSMO${AREA} ${curr_date} ${HH}Z Finalizado"

#/usr/bin/input_status.php verif_${AREA} ${HH} ${RODADA} VERDE "${MSG}"
fi

#*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=
# FIM
