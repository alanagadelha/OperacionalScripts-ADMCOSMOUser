#!/bin/bash
set -x
#
# script exec_cosmo2cosmo.sh
#
#  Script para executar o gme2cosmo somente para o horario passado
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
if [[ $# -ne 4 && $# -ne 5 ]] ; then
     echo "Entre com o  a AREA, horario de referencia (00Z ou 12Z) e o prognostico (00, 03, 06, 09, 12, etc)!!!!!"
     exit 12
fi
RODADA=Teste
AREA=$1
HH=$2
HSTART=$3
prog=$4
HH_m03=${5:-${HH}}

#*****************************************************************************
#  Passo 2 - Define variaveis
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
datetimeana_m03=${curr_date}${HH_m03}
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

#
#*****************************************************************************
#  Passo 3 - Rodando o  cosmo2cosmo analise e condicao de contorno
#
cd ${WORKDIR}/cosmo2cosmo
dir=${RANDOM}
mkdir $dir
cp -p tmpl_INPUT_COSMO2COSMO $dir
cp -p cosmo2cosmo $dir
cd $dir


# setando o flag de controle para geracao da analise ou nao

if [ $prog -eq $HSTART ];then
FLAG="true"
else
FLAG="false"
fi

dataana=`/home/admcosmo/cosmo/bin/caldate ${datetimeana} + ${HSTART}h 'yyyymmddhh'`

   rm -f ./YU* ./OUTPUT
   
   sed -e "s/datetime_m03/${datetimeana_m03}/g
           s/datetime/${datetimeana}/g
           s/HSTART/${prog}/g
           s/HSTOP/${prog}/g
           s/FLAG/${FLAG}/g
           s/HH_m03/${HH_m03}/g
           s/HH/${HH}/g
           s=WORKDIR=${WORKDIR}=g
          " tmpl_INPUT_COSMO2COSMO > INPUT
   par=`echo $prog % 2 + 1 | bc` 

# MPT (2.10 SGI-HPE MPI):
export LD_LIBRARY_PATH=/opt/hpe/hpc/mpt/mpt-2.17/lib:/home/gast/intel_13.0.1/libraries/lib:/opt/intel/lib/intel64:/lib64
export PATH=/opt/hpe/hpc/mpt/mpt-2.17/bin:/opt/intel/bin:/home/gast/intel_13.0.1/libraries/bin:/opt/sgi/sbin:/opt/sgi/bin:/usr/local/bin:/usr/bin:/bin:/usr/bin/X11:/opt/c3/bin:.
GRIB_API=/home/gast/intel_13.0.1/libraries/share/grib_api
export GRIB_DEFINITION_PATH=${GRIB_API}/1.16.0/definitions.edzw:${GRIB_API}/1.16.0/definitions:${GRIB_API}/definitions:/home/gast/intel_13.0.1/libraries/grib_api-1.20.0-Source/definitions/grib1
export GRIB_SAMPLES_PATH=${GRIB_API}/1.16.0/samples:${GRIB_API}/samples

  /opt/hpe/hpc/mpt/mpt-2.17/bin/mpirun `cat $WORKDIR/ajustes/no${par}_icon2cosmo.txt` 12 ./cosmo2cosmo
   error=$?

   if [ $error -ne 0 ];then
      echo ERRO NO PRE-PROCESSAMENTO do COSMO 2 COSMO!!!
      cd ${WORKDIR}/cosmo2cosmo
#      rm -rf ${dir}
      echo ABORTANDO !!!
      ssh `cat $WORKDIR/ajustes/no${par}_icon2cosmo.txt` killall cosmo2cosmo
  
	MSG="Falha no Pre-proc do COSMO${AREA} ${curr_date} ${HH}Z "

       #/usr/bin/input_status.php verif_icon ${HH} ${RODADA} VERMELHO "${MSG}" 
     exit 12
    else 
   echo "ok"
    fi

cd ..

#rm -rf ${dir}


if [[ ":${prog}" == ":${HSTART}" && ":${HH}" != ":${HH_m03}" ]] ; then

   if [ -s ${WORKDIR}/data/init_cond${HH}/laf$dataana ]
   then

#      dtfile=`/home/gast/libraries/GRIB_API/bin/grib_ls -p dataDate ${WORKDIR}/data/init_cond${HH}/laf$dataana | head -3 | tail -1`
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


if [ -s ${WORKDIR}/data/init_cond${HH}/LMB_${FILE}0000 ] && [ -s ${WORKDIR}/data/init_cond${HH}/lbff${FILE}0000 ];then
   
#   dtfile=`/home/admcosmo/cosmo/bin/dtgrib  ${WORKDIR}/data/init_cond${HH}/lbff${FILE}0000`
#    dtfile=`/home/gast/libraries/GRIB_API/bin/grib_ls -p dataDate ${WORKDIR}/data/init_cond${HH}/laf$dataana | head -3 | tail -1`
    dtfile=`/home/gast/intel_13.0.1/libraries/bin/grib_ls -p dataDate ${WORKDIR}/data/init_cond${HH}/laf$dataana | head -3 | tail -1`
    dtfile=${dtfile%% *}
    if [ ${dtfile}${HH} == ${datetimeana} ];then
      echo Arquivo LBC ${FILE} ref ${prog}hs gerado
	MSG="Pre-proc do COSMO${AREA} ${curr_date} ${HH}Z condicao de contorno LMB_${FILE}0000"

        #/usr/bin/input_status.php verif_icon ${HH} ${RODADA} AMARELO "${MSG}" 
  
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

   else
       rm -f ${WORKDIR}/data/init_cond${HH}/LMB_${FILE}0000
       exit 12
   fi
else 
   rm -f ${WORKDIR}/data/init_cond${HH}/LMB${FILE}0000
   exit 12

fi

#*****************************************************************
