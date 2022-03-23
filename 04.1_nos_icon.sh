#!/bin/bash
# Este script verifica quais nos estao ligados para serem utilizados pelo ICON2COSMO

set -x

if [ $# -lt 1 ]
then
echo " Voce deve entrar com a AREA"
exit 12 
fi


AREA=$1

case $AREA in

met)
WORKDIR='/home/admcosmo/cosmo/metarea5'
;;
ant)
WORKDIR='/home/admcosmo/cosmo/antartica'
;;
sse)
WORKDIR='/home/admcosmo/cosmo/sse'
;;
esac

# Sempre sera utilizado algum NO do rack0 para o ICON2COSMO
rack="r1i0n" 

for n in `seq 0 17`
do

# verificando se o no esta em cima
ping -q -c 1 $rack$n #> /dev/null
err=$?
if [ $err -eq 0 ]
then
# verificando quantos processadores estao disponiveis nesse no
nprocs=` ssh $rack$n cat /proc/cpuinfo | grep processor | wc -l`

#verificando se o no tem pelo menos 12 processadores disponiveis

if [ $nprocs -ge 12 ]
then
no_disponivel=`echo "$rack$n  $no_disponivel"`
fi

fi

done

## 04JUN2018 incluido pelo CC LEANDRO
## O COSMO USARA todo IRU 0 (r1i0n*)
# para isso o icon2cosmo usara preferencialmente os nos r1i3n[0,1]
# na ausencia desses nos do r1i3, o icon2cosmo usara algum no do r1i0n*
# ALT para r1i1n9 e 10 em 26FEV2019.

rack="r1i1n"
for n in `seq 0 1`
do

# verificando se o no esta em cima
ping -q -c 1 $rack$n #> /dev/null
err=$?
if [ $err -eq 0 ]
then
# verificando quantos processadores estao disponiveis nesse no
nprocs=` ssh $rack$n cat /proc/cpuinfo | grep processor | wc -l`

#verificando se o no tem pelo menos 12 processadores disponiveis

if [ $nprocs -ge 12 ]
then
no_disponivel=`echo "$rack$n  $no_disponivel"`
fi

fi

done

#########FIM DA ALTERACAO FEITA PELO CC LEANDO 04JUN2018

# guardando a informacao do no a ser usado
echo $no_disponivel | cut -f1 -d" " >  $WORKDIR/ajustes/no1_icon2cosmo.txt
echo $no_disponivel | cut -f2 -d" " >  $WORKDIR/ajustes/no2_icon2cosmo.txt

#FIM
