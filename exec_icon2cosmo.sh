#!/bin/bash
set -x
#
# script exec_icon2cosmo.sh
#
#  Script para executar o icon2cosmo somente para o horario passado
# como parametro.
#
#
#*****************************************************************************
#  Passo 1 - Aumenta o stacksize e testa o recebimento de parametros
#
#limit stacksize unlimited
ulimit -s unlimited
ulimit -l unlimited
ulimit -v unlimited
#
if [ $# -ne 4 ];then
     echo "Entre com o  a AREA, horario de referencia (00Z ou 12Z) e o prognostico (00, 03, 06, 09, 12, etc)!!!!!"
     exit 12
fi
AREA=$1
HH=$2
HSTART=$3
prog=$4

#*****************************************************************************
#  Passo 2 - Define variaveis
#

case $AREA in
met)
AREA1=metarea5
;;
sse)
AREA1=sse
;;
ant)
AREA1=antartica
;;
esac

curr_date=`cat /home/admcosmo/datas/datacorrente${HH}`
datetimeana=${curr_date}${HH}
WORKDIR=/home/admcosmo/cosmo/$AREA1

dia=`expr $prog / 24`
if [ $dia -lt 10 ];then
   DD=0$dia
else
   DD=$dia
fi

hora=`expr $prog - $dia \* 24`
if [ $hora -lt 10 ];then
   HR=0$hora
else
   HR=$hora
fi

FILE=$DD$HR

#*****************************************************************************
#  Passo 3 - Rodando o  icon2cosmo analise e condicao de contorno
#
cd ${WORKDIR}/icon2cosmo
dir=${RANDOM}
mkdir $dir
cp -p tmpl_INPUT_ICON2COSMO $dir
cp -p icon2cosmo $dir
cd $dir


# setando o flag de controle para geracao da analise ou nao

if [ $prog -eq $HSTART ];then
FLAG="true"
else
FLAG="false"
fi

dataana=`/home/admcosmo/cosmo/bin/caldate $datetimeana + ${HSTART}h 'yyyymmddhh'`

   rm -f ./YU* ./OUTPUT
   
   sed s/datetime/$datetimeana/g tmpl_INPUT_ICON2COSMO > temp_icon2cosmo
   sed s/HSTART/${prog}/g temp_icon2cosmo > INPUT
   sed s/HSTOP/${prog}/g INPUT > temp_icon2cosmo
   sed s/FLAG/${FLAG}/g temp_icon2cosmo > INPUT
   sed s/HH/$HH/g INPUT > temp_icon2cosmo
   sed s=WORKDIR=$WORKDIR=g temp_icon2cosmo > INPUT
   rm -f temp_icon2cosmo
   par=`echo $prog % 2 + 1 | bc` 

# MPT (2.10 SGI-HPE MPI):
export LD_LIBRARY_PATH=/opt/hpe/hpc/mpt/mpt-2.17/lib:/home/gast/intel_13.0.1/libraries/lib:/opt/intel/lib/intel64:/lib64
export PATH=/opt/hpe/hpc/mpt/mpt-2.17/bin:/opt/intel/bin:/home/gast/intel_13.0.1/libraries/bin:/opt/sgi/sbin:/opt/sgi/bin:/usr/local/bin:/usr/bin:/bin:/usr/bin/X11:/opt/c3/bin:.
GRIB_API=/home/gast/intel_13.0.1/libraries/share/grib_api
export GRIB_DEFINITION_PATH=${GRIB_API}/1.16.0/definitions.edzw:${GRIB_API}/1.16.0/definitions:${GRIB_API}/definitions:/home/gast/intel_13.0.1/libraries/grib_api-1.20.0-Source/definitions/grib1
export GRIB_SAMPLES_PATH=${GRIB_API}/1.16.0/samples:${GRIB_API}/samples


   /opt/hpe/hpc/mpt/mpt-2.17/bin/mpirun `cat $WORKDIR/ajustes/no${par}_icon2cosmo.txt` 24 ./icon2cosmo
   error=$?

   if [ $error -ne 0 ];then
      echo ERRO NO PRE-PROC do ICON !!!
      cd ${WORKDIR}/icon2cosmo
      rm -rf ${dir}
      echo ABORTANDO !!!
      ssh `cat $WORKDIR/ajustes/no${par}_icon2cosmo.txt` killall icon2cosmo
      exit 12
    else 
   echo "ok"
    fi

cd ..

rm -rf ${dir}


if [ $prog -eq $HSTART ] ; then

   if [ -s ${WORKDIR}/data/init_cond${HH}/laf$dataana ]
   then

      #dtfile=`/home/gast/libraries/GRIB_API/bin/grib_ls -p dataDate ${WORKDIR}/data/init_cond${HH}/laf$dataana | head -3 | tail -1`
      dtfile=`/home/gast/intel_13.0.1/libraries/bin/grib_ls -p dataDate ${WORKDIR}/data/init_cond${HH}/laf$dataana | head -3 | tail -1`
      dtfile=${dtfile%% *} 
         if [ ${dtfile}${HH} == ${datetimeana} ];then
              echo Arquivo ANALISE gerado
         else
              rm -f ${WORKDIR}/data/init_cond${HH}/LMA_${FILE}0000
              exit 12
         fi
   else
         rm -f ${WORKDIR}/data/init_cond${HH}/LMA_$dataana
         exit 12
   fi

fi

if [[ ":${AREA1}" != ':sse' ]] ; then

   if [ -s ${WORKDIR}/data/init_cond${HH}/LMB_${FILE}0000 ] && [ -s ${WORKDIR}/data/init_cond${HH}/lbff${FILE}0000 ] ; then
      
      dtfile=`/home/gast/intel_13.0.1/libraries/bin/grib_ls -p dataDate ${WORKDIR}/data/init_cond${HH}/laf$dataana | head -3 | tail -1`
      dtfile=${dtfile%% *}
      if [ ${dtfile}${HH} == ${datetimeana} ] ; then

         echo Arquivo LBC ${FILE} ref ${prog}hs gerado
      
         if [ $HSTART != "00" ]; then
              
            dif=`echo "$prog - $HSTART"  | bc `

            dia=`expr $dif / 24`

            if [ $dia -lt 10 ];then
               DD=0$dia
            else
               DD=$dia
            fi
                    
            hora=`expr $dif - $dia \* 24`
            if [ $hora -lt 10 ];then
                HR=0$hora
            else
                HR=$hora
            fi

         fi

         FILE2=$DD$HR

         ln -sf  ${WORKDIR}/data/init_cond${HH}/LMB_${FILE}0000 ${WORKDIR}/data/init_cond${HH}_2/LMB_${FILE2}0000
         ln -sf  ${WORKDIR}/data/init_cond${HH}/lbff${FILE}0000 ${WORKDIR}/data/init_cond${HH}_2/lbff${FILE2}0000

      else
          rm -f ${WORKDIR}/data/init_cond${HH}/LMB_${FILE}0000
          exit 12
      fi
   else 
      rm -f ${WORKDIR}/data/init_cond${HH}/LMB${FILE}0000
      exit 12
   fi

fi

#*****************************************************************

