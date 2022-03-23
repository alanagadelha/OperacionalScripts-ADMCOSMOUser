#!/bin/bash
set -x
# script exec_cosmo.sh
#
#  Script de execucao do modelo COSMO Metarea paralelizado em MPI.
#
#  Autor: CT Leandro Machado 
#  Data: 10OUT2008
#  Adapted by 1T(T) Alana Pontes
#
#*****************************************************************************
#  Passo 1 - Aumenta o stacksize e verifica o recebimento de parametros
#          definindo o horario de referencia da rodada, o periodo de previsao e 
#          o numero de processadores nas direcoes latitudinal e longitudinal
#          do dominio.
#
#limit stacksize unlimited
clear
echo
echo "Este script executa o modelo COSMO paralelizado em MPI na Altix ICE X"
echo "Autor: CT (T) Leandro "
echo "Adaptado por Alana"
date

ulimit -s unlimited
ulimit -v unlimited
#
if [ $# -lt 4 ];then
   echo "Entre com  a area, o horario da rodada (00 ou 12), o prognostico inicial e final  das rodadas !!!"
   echo "Adicionalmente voce podera entrar com o numero de processadores em X e em Y se quiser defini-los"
   exit 12
fi
if [ $AREA == "SSE" ]
then
RODADA="Teste"
else
RODADA="Operacional"
fi

#RODADA=Teste

AREA=$1
HH=$2
HSTART=$3
HSTOP=$4

AREA () {
case $AREA in

met)
STATUS=60
HSTART_ref=00
HSTART_ref2=00
WORKDIR='/home/admcosmo/cosmo/metarea5'
#DT_ref=70
DT_ref=50 
HSTOP_ref=96
AREA2=met5
AREA3="METAREA V"
;;
ant)
STATUS=62
HSTART_ref=00
HSTART_ref2=00
WORKDIR='/home/admcosmo/cosmo/antartica'
DT_ref=60
HSTOP_ref=96
AREA2=ant
AREA3="ANTARTICA"
;;
sse)
STATUS=64
HSTART_ref="00"
HSTART_ref2="00"
WORKDIR='/home/admcosmo/cosmo/sse'
#DT=25 para sse=2.8
#DT_ref=25
#DT=20 para sse=2.2
DT_ref=20
#HSTOP_ref=96
HSTOP_ref=48
AREA2=sse
;;
esac
}

# Essa funcao determina qual foi o ultimo prognostico pronto e retoma a previsao a partir deste ponto
RESTART () {
 if [ $HSTART -eq $HSTART_ref ]
 then
 HSTART=$((HSTART+3))
 fi
 progs=`seq $((HSTART-HSTART_ref)) 3 $((HSTOP-HSTART_ref)) | tr '\012' ' '`
               prog=$HSTART
               flag="true"
               c=1
               while [ $flag == "true" ] && [ $prog -lt $((HSTOP-HSTART_ref)) ]
               do
                     prog=`echo $progs | cut -f$c -d" "`
                     DD=`echo $prog / 24 | bc `
                     DD="0"$DD
                     HR=`echo $prog % 24 | bc `


                     if [ $HR -le 9 ]
                     then
                         HR="0"$HR
                     fi

                      if ! [ -e  ${WORKDIR}/data/restart${HH}/lrff${DD}${HR}0000o ]
                      then
                           flag="false"
                      fi

                       c=$((c+1))
                  done

               if [ $flag == "false" ] && [ $prog -gt 0 ]
               then
                  HSTART=$((prog-3))
               elif [ $prog -eq 0 ]
               then
                  HSTART=$prog
               else
                 echo "Nao se trata de uma rodada de RESTART todos os prognosticos entre $HSTART e $HSTOP estao prontificados" 
               fi
}
#chamando a funcao AREA para o caso dele ter sido definida sem envocar AREA=

AREA

# colocando as variaveis em ordem alfabetica pra garantir que AREA seja a primeira a ser definida
variaveis=`echo $* | tr ' ' '\012' | sort | tr '\012' ' '`

# avaliando a definicao das variveis

for var in $*
do
#transformando a variavel em maiuscula
varaux=`echo $var | grep "=" | cut -f1 -d"=" | tr '[a-z]' '[A-Z]'`
# transformando o valor da variavel em minusculo
valor=`echo $var | grep "=" | cut -f2  -d"=" | tr '[A-Z]' '[a-z]'`

case $varaux in

AREA) 
eval $varaux=$valor
if [ $AREA == "met" ] || [ $AREA == "ant" ] || [ $AREA == "20km" ]
then
echo AREA=$AREA
# invocando a funcao AREA
AREA
else
echo " AREA INVALIDA "
exit 12
fi
;;

HH)
eval $varaux=$valor
;;


HSTOP)
eval $varaux=$valor
;;

HSTART)
eval  $varaux=$valor
;;

NPROCX)
eval  $varaux=$valor
;;

NPROCY)
eval $varaux=$valor
;;

DT)
eval $varaux=$valor
;;

esac

done

echo 
echo
#*****************************************************************************

# Fazendo  check para os parametros basicos que podem ser informados"
echo " Fazendo o CHECK dos parametros recebidos "
echo " Voce informou AREA = $AREA "
echo

case $AREA in
met)
echo " "
;;
ant)
echo " "
;;
sse)
echo " "
;;
*)
echo
echo " Esta AREA nao e valida"
echo
exit 12
;;
esac

echo " Voce informou hora de referencia = $HH "
echo
case $HH in
00)
echo " "
;;
12)
echo " "
;;
03)
echo "Hello Alana!"
if [[ ":${AREA}" == ':sse' ]] ; then
   echo " "
else
   echo " O horario de referencia informado nao e valido "
   echo " Ele so pode ser 00 ou 12 "
   echo
   exit 12
fi
;;
15)
echo "Hello Alana!"
if [[ ":${AREA}" == ':sse' ]] ; then
   echo " "
else
   echo " O horario de referencia informado nao e valido "
   echo " Ele so pode ser 00 ou 12 "
   echo
   exit 12
fi
;;
*)
echo " O horario de referencia informado nao e valido "
echo " Ele so pode ser 00 ou 12 "
echo
exit 12
;;
esac


echo "Voce informou a hora de inicio HSTART = $HSTART "
echo
if [ $HSTART -ge $HSTOP ]
then
echo " Voce deve informar o horario de inicio menor ao horario final"
echo
exit 12
fi

MUL=`echo $HSTART % 3 | bc`

if [ $MUL -ne 0 ]
then
echo " HSTART deve ser multiplo de 3 "
echo
exit 12
fi

echo "Voce informou a hora de termino HSTOP = $HSTOP "
echo
MUL=`echo $HSTOP % 3 | bc`
if [ $MUL -ne 0 ]
then
echo " HSTOP deve ser multiplo de 3 "
echo
exit 12
fi

if [ $HSTOP -gt $HSTOP_ref ]
then
echo "Voce especificou um HSTOP maior do que o permitido ($HSTOP_ref)"
echo
exit 12
fi

# definindo DT se este nao tiver sido definido
if  [ -z $DT ]
then
echo "Voce nao especificou o passo de tempo. Sera usado o passo de tempo de referencia"
echo "DT = $DT_ref"
DT=$DT_ref
fi

if [ $DT -gt  $DT_ref ]
then
echo "Voce especificou um passo de tempo DT que viola CFL"
echo "Especifique DT menor que  $DT_ref"
echo
exit 12
else
DT75p=`echo "$DT_ref * 3 / 4" | bc `
if [ $DT -lt $DT75p ]
then
echo "Voce especifico um DT mais que 25% inferior a "$DT_ref
echo "Voce deseja utiliza-lo ?"
echo
select yn in "SIM" "NAO"; do
    case $yn in
        SIM ) break;;
        NAO ) echo "chame o script novamente especificando um novo DT";exit;;
    esac
done

fi

fi


# chamando o script para alocacao dos nos
#Comentado por Alana as 0800P do dia 15JUl2018
/home/admcosmo/cosmo/scripts/05.1.1_nos_proc_new.sh $AREA $NPROCX $NPROCY
erro=$?

if [ $erro -ne 0 ]
then
exit 12
else
NPROCX=`cat $WORKDIR/cosmo/divisao_dominio.txt | cut -f1 -d" "`
NPROCY=`cat $WORKDIR/cosmo/divisao_dominio.txt | cut -f2 -d" "`
NPROCIO=`cat $WORKDIR/cosmo/divisao_dominio.txt | cut -f3 -d" "`
echo " Serao utilizados NPROCX = $NPROCX processadores em X "
echo " Serao utilizados NPROCY = $NPROCY processadores em Y "
echo " Serao utilizados NPROCIO = $NPROCIO processadores para IO "
fi

# varrendo os paramentros passados em busca de opcoes
for var in $*
do
#transformando a variavel em maiuscula
varaux=`echo $var | grep "-" | cut -f2 -d"-" | tr '[a-z]' '[A-Z]'`

case $varaux in

RESTART)
RESTART
;;
esac
done

#Atualiza o Status da rodada
#if [ $HH -eq 12 ]
#then
#     STATUS=$((STATUS+1))
#fi
#COR=1 #Amarelo
#MSG="INICIADO - STARTED"
#echo
#echo Executando /usr/local/bin/atualiza_status.pl $STATUS $COR \"$MSG\"
#echo
#/home/admcosmo/cosmo/scripts/atualiza_status.pl $STATUS $COR "$MSG"
#

#*****************************************************************************
#  Passo 2 - Define outras variaveis
#
curr_date=`cat /home/admcosmo/datas/datacorrente${HH}`
delta_t=$((HH+HSTART_ref))
datetimeana=`/home/admcosmo/cosmo/scripts/caldate ${curr_date} + ${delta_t}h 'yyyymmddhh'`


#########################################################
#    Atualizando o status da rodada - Inicio
#########################################################
MSG="Processamento do COSMO${AREA} ${curr_date} ${HH}Z iniciado"

#/usr/bin/input_status.php cosmo${AREA} ${HH} ${RODADA} AMARELO "${MSG}"

#*****************************************************************************


# definindo as variaveis necessarias para rodar o cosmo
#export LIBDWD FORCE CONTROLWORDS=1
#export LIBDWD_BITMAP_TYPE=ASCII
#export LIBDWD_BITMAP_PATH=${WORKDIR}/data/const

#*****************************************************************************
#  Passo 3 - Apaga arquivos antigos. 
#


# se HSTART nao e igual a HREF trata-se de uma rodada de restart

          ARQ=`echo ${WORKDIR}/data/prevdata${HH}/cosmo_${AREA2}_${HH}_${curr_date}"0"${HSTART_ref}`
          if [ $HSTART -lt $HSTART_ref ]
          then
          ref=$HSTART_ref2

          elif [ -e $ARQ ] 
          then
        
             err=`wgrib -v $ARQ | head -1 | cut -f7 -d: | grep anl`
           
             if [ $err -eq 0 ]
             then
             ref=$HSTART_ref
             else
             ref=$HSTART_ref2

             fi
         
          else
         
                ref=$HSTART_ref 
          
         fi

# Verificando se existe algum prognostico superior a HSTART pronto
               
               progs=`seq $((HSTOP-ref)) -3 $((HSTART-ref)) | tr '\012' ' '`
               prog=$((HSTOP-ref))
               c=2
               while [ $prog -ne $((HSTART-ref)) ]
               do

                     DD=`echo $prog / 24 | bc `
                     DD="0"$DD
                     HR=`echo $prog % 24 | bc `


                     if [ $HR -le 9 ]
                     then
                         HR="0"$HR
                     fi

                      if [ -e  ${WORKDIR}/data/restart${HH}/lrff${DD}${HR}0000o ] 
                      then
                               echo " Existe um prognostico superior $HSTART  horas de previsao pronto "

                               if [ $prog -le 9 ]
                               then 
                               prog="0"$prog
                               fi

                               echo " Voce pode comecar a rodar o modelo  com HSTART =  $prog "
                               echo " Se quiser comecar com HSTART = $HSTART  apague os arquivos de restart dos progs superiores antes"
                               
                                MSG="EXISTE RESTART. APAGUE-O OU USE HSTART=${prog} P/ COSMO${AREA} ${curr_date} ${HH}Z"

                                #/usr/bin/input_status.php cosmo${AREA} ${HH} ${RODADA} VERMELHO "${MSG}"


                              exit 12 
                      fi
                    
                       prog=`echo $progs | cut -f$c -d" "`
                       c=$((c+1))
                    
                     
               done

 


               DD=`echo $((HSTART-ref)) / 24 | bc `
               DD="0"$DD
               HR=`echo $((HSTART-ref)) % 24 | bc `

               if [ $HR -le 9 ]
               then
                   HR="0"$HR
               fi

               if [ -e  ${WORKDIR}/data/restart${HH}/lrff${DD}${HR}0000o ]
               then 
                         ln -s  ${WORKDIR}/data/restart${HH}/lrff${DD}${HR}0000o ${WORKDIR}/data/init_cond${HH}
                         rm ${WORKDIR}/data/prevdata${HH}/lfff${DD}${HR}0000
                         rm ${WORKDIR}/data/prevdata${HH}/lfff${DD}${HR}0000?
                         rm ${WORKDIR}/data/ready${HH}/LMF_${DD}${HR}0000 
               else
                         echo "Voce especificou um HSTART diferente de $ref mas o arquivo de restart nao esta disponivel"
                          MSG="HSTART DIFERENTE DE $ref MAS NAO HA RESTART DISPONIVEL P/ COSMO${AREA} ${curr_date} ${HH}Z"
#                                /usr/bin/input_status.php cosmo${AREA} ${HH} ${RODADA} VERMELHO "${MSG}"
#

#                          exit 12
               fi


rm -f ${WORKDIR}/cosmo/INPUT*
rm -f ${WORKDIR}/cosmo/YU*


#
#*****************************************************************************
# Passo 4 - Executa o COSMO para HSTOP horas de previsao
#
cd ${WORKDIR}/cosmo/

#
sed s/datetime/$datetimeana/g tmpl_INPUT_COSMO > temp_cosmo
sed s/HSTART/$((HSTART-ref))/g temp_cosmo > INPUT_COSMO
sed s/HSTOP/$((HSTOP-ref))/g INPUT_COSMO > temp_cosmo
sed s/DT/${DT}/g temp_cosmo > INPUT_COSMO
sed s/HSTOP/$((HSTOP-ref))/g INPUT_COSMO > temp_cosmo
sed s=WORKDIR=$WORKDIR=g temp_cosmo > INPUT_COSMO
sed s/NX/$NPROCX/ INPUT_COSMO > temp_cosmo
sed s/NY/$NPROCY/ temp_cosmo > INPUT_COSMO
sed s/NIO/$NPROCIO/ INPUT_COSMO > temp_cosmo
sed s/HH/$HH/g temp_cosmo > INPUT_COSMO
#cp temp_cosmo INPUT_COSMO
rm -f temp_cosmo 

ln -sf INPUT_COSMO INPUT_DYN
ln -sf INPUT_COSMO INPUT_INI
ln -sf INPUT_COSMO INPUT_ORG
ln -sf INPUT_COSMO INPUT_DIA
ln -sf INPUT_COSMO INPUT_EPS
ln -sf INPUT_COSMO INPUT_IO
ln -sf INPUT_COSMO INPUT_PHY
ln -sf INPUT_COSMO INPUT_ASS

echo '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
echo 
echo "`date` - Inicio da Rodada do COSMO na Versão-5.1 $AREA3 ${HH}Z"
echo
echo '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'


#MSG="RODANDO - RUNNING"
#echo Executando atualiza_status.pl $STATUS $COR \"$MSG\"
#/home/admcosmo/cosmo/scripts/atualiza_status.pl $STATUS $COR "$MSG"
##################################################
# Atualizando o status da rodada
##################################################
MSG="RODANDO COSMO${AREA} ${data_curr} ${HH}Z"

#/usr/bin/input_status.php cosmo${AREA} ${HH} ${RODADA} AMARELO "${MSG}"
###############################################

/home/admcosmo/cosmo/scripts/05.1.2_renamec_prevmet.sh ${AREA} ${HH} ${HSTART} ${HSTOP} &

if [ $AREA == "met" ]
then
/home/admcosmo/cosmo/scripts/05.1.3_renamec_backupmet.sh ${AREA} ${HH} ${HSTART} ${HSTOP} &
#### Adicionei o script dos dados para o Spadsar
nohup /home/admcosmo/cosmo/scripts/dados_cosmo_spadsar.sh ${HH} > /home/admcosmo/cosmo/scripts/Spadsar/Spadsar${HH}.log &
fi

if [ $AREA == "ant" ]
then
/home/admcosmo/cosmo/scripts/05.1.3_renamec_backupmet.sh ${AREA} ${HH} ${HSTART} ${HSTOP} &
fi

if [ $AREA == "sse" ];then
/home/admcosmo/cosmo/scripts/05.1.4_renamec_prevmet_sse22.sh sse22 $HH $HSTART $HSTOP & 
fi

/home/admcosmo/cosmo/scripts/05.1.5_extrai_wgrib.sh ${AREA} ${HH} ${HSTART} ${HSTOP} &


#****************************************************************************************************
#GRIB_API RECENT 

GRIB_API=/home/gast/intel_13.0.1/libraries/share/grib_api
export GRIB_DEFINITION_PATH=${GRIB_API}/1.16.0/definitions.edzw:${GRIB_API}/1.16.0/definitions:${GRIB_API}/definitions
export GRIB_SAMPLES_PATH=${GRIB_API}/1.16.0/samples:${GRIB_API}/samples

#OLD_VERSION
#export grib_definition_path="/home/gast/libraries/GRIB_API/share-1.11.0/grib_api/definitions.edzw:/home/gast/libraries/GRIB_API/share-1.11.0/
#grib_api/definitions"

ulimit -s unlimited
ulimit -v unlimited
#export LIBDWD FORCE CONTROLWORDS=1
#export LIBDWD_BITMAP_TYPE="ASCII"
#export LIBDWD_BITMAP_PATH=${WORKDIR}/data/const
export MPI_DSM_DISTRIBUTE=1
export MPI_IB_RAILS=2

#******************************************************************************************************

/usr/bin/time /opt/hpe/hpc/mpt/mpt-2.17/bin/mpirun -v `cat mpirunarg.txt` ./cosmo
error=$?

if [ $error -ne 0 ];then
   echo ERRO NO MODELO COSMO!!!
   echo ABORTANDO!!!
#   COR=2 #Vermelho
#   MSG="FALHA - CRASHED"
#/home/admcosmo/cosmo/scripts/atualiza_status.pl $STATUS $COR "$MSG"
#/home/admcosmo/cosmo/scripts/atualiza_status.pl $STATUS1 $COR "$MSG"

########################################################
#    Atualizando o status da rodada
########################################################
MSG="FALHA NO PROCESSAMENTO COSMO${AREA} ${curr_date} ${HH}Z"

#/usr/bin/input_status.php cosmo${AREA} ${HH} ${RODADA} VERMELHO "${MSG}"
################################################################

/home/admcosmo/cosmo/scripts/01_mata.sh
   exit 12
fi

#*****************************************************************************
# Passo 6 - Move os arquivos de meteograma para o diretorio correto
#
cd ${WORKDIR}/cosmo/
mv *.ppt ${WORKDIR}/data/prev_pontos${HH}

rm -f pontos_nomes
grep ynamegp INPUT_COSMO | cut -d'=' -f4 | sed s/ppt//|cut -d ',' -f1 | sed s/\'//g > pontos_nomes
mv pontos_nomes ${WORKDIR}/data/prev_pontos${HH}


##*****************************************************************************
# Passo 9 - Abre permissao de leitura dos arquivos do diretorio prev_dataHH
#
chmod -R +r ${WORKDIR}/data/prev_data${HH}/
#
##*****************************************************************************
sleep 60  # dando tempo do rename renomear

if [ $AREA2 == "sse" ] && [ -e ${WORKDIR}/data/prevdata${HH}/cosmo_${AREA2}22_${HH}_${curr_date}0${HSTOP_ref} ];then

MSG="PROCESSAMENTO DO COSMO${AREA} ${curr_date} ${HH}Z ENCERRADO"
#/usr/bin/input_status.php cosmo${AREA} ${HH} ${RODADA} VERDE "${MSG}"

else

if [ -e ${WORKDIR}/data/prevdata${HH}/cosmo_${AREA2}_${HH}_${curr_date}0${HSTOP_ref} ];then

MSG="PROCESSAMENTO DO COSMO${AREA} ${curr_date} ${HH}Z ENCERRADO"
#/usr/bin/input_status.php cosmo${AREA} ${HH} ${RODADA} VERDE "${MSG}"

fi
fi
#echo
#echo Executando /usr/local/bin/atualiza_status.pl $STATUS $COR \"$MSG\"
#echo
#/home/admcosmo/cosmo/scripts/atualiza_status.pl $STATUS $COR "$MSG"
#/home/admcosmo/cosmo/scripts/atualiza_status.pl $STATUS1 $COR "$MSG"

#*****************************************************************************
echo '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
echo
echo "`date` - Fim da Rodada do COSMO na Versão-5.1$AREA3 ${HH}Z"
echo
echo '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
#*****************************************************************************
# FIM  

