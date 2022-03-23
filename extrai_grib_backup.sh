#!/bin/bash -x

#############################################
#
# Script para extracao de dados GRIB, com objetivo 
# extrair dados especificos do cosmo 7km!
#
# Escrito em 02OUT2017
#
# Autora: Ten Renata
# Adaptado de extrai_grib_valida.sh, autora CB RAQUEL
#
#
#############################################

#############################################
#
# Verifica se foi passado o horario da rodada
#
#############################################

if [ "$#" -ne 3 ];then

     echo "Entre com o dia inicial e final (Ex.: 20160928)!"
     exit 12

fi

DSTART=$1
AI=echo ${DSTART} | cut -c 1-4
MI=echo ${DSTART} | cut -c 5-6
DI=echo ${DSTART} | cut -c 7-8

DSTOP=$2
AF=echo ${DSTOP} | cut -c 1-4
MF=echo ${DSTOP} | cut -c 5-6
DF=echo ${DSTOP} | cut -c 7-8


#############################################
#
# DIRDADOSORI eh o diretorio de origem de onde
# serao extraidos os dados do GRIB
#
# DIRDADOSDES eh o diretorio de destino para
# onde serao salvos os dados extraidos.
#
#############################################

# cria pasta com data do dia antes de jogar os gribs
#data=`date +%Y%m%d`

mkdir /home/admcosmo/cosmo/metarea5/data/valida_${HH}/cosmo_grib_$data


#curr_date=`cat /home/operador/datas/datacorrente${HH}`
DIRDADOSORI=/data2/backup_cosmo/metarea5/dados00
DIRDADOSDES=/home/admbackup/dados_renata
DADOSORIPREF="cosmomet_07km_00_"

##################################################
#
#Entra no diretorio de origem e executa o WGRIB 
# para todos os horarios dentro de $str2
#
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

cd $DIRDADOSDES

a=$AI
m=$MI
d=$DI

while [ $a -le $AF ]; do

	while [ $m -le $MF ]; do

		if [ $m -le 12 ]; then

			while [ $d -le $DF ]; do

				if [ $d -le 31 ]; then

					tar -??? ${DIRDADOSORI}/${DADOSORIPREF}$a$m$d
					echo
					echo " Extraindo precipitacao, temperatura, pressao e vento do dia $a$m$d"
					wgrib ${DIRDADOSORI}/${DADOSORIPREF}$a$m$d | egrep "(kpds5=61:kpds6=1|kpds5=11:kpds6=105|kpds5=2:kpds6=102:kpds7=0|kpds5=33:kpds6=105|kpds5=34:kpds6=105)" \
					| wgrib -i -grib ${DADOSORIPREF}$a$m$d -o ${DIRDADOSDES}/cosmo7km_renata_$a$m$d


				fi

		fi
			(( d++ ))
			done

	(( m++ ))
	done

(( a++ ))
done
