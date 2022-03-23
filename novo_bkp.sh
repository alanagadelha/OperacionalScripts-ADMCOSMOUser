#!/bin/bash -x

# Script para selecionar dos dados de saida
# somente os horarios descritos em HREF2

HSIM=$1
ANOI=$2
MESI=$3

	if ! [ $# == 5 ];then

		echo
		echo " Entre com o horario de simulacao HH,"
		echo " o ano YYYY, mes MM, dia inicial DD e dia final DD. "
		echo 
		echo " Ex.: ./novo_backup 00 2012 02 01 28"
		echo

	exit 01

	fi

DIRDADOSORI=/data2/backup_cosmo/metarea5/dados${HSIM}
DIRDADOSEXT=/data2/backup_cosmo/metarea5/dados${HSIM}/novo_backup

SUFIX=".tar.bz2"

# DIA inicial e final
HSTRT1=$4
HSTOP1=$5

# Intervalo de dados que serao guardados
INT=12

# Artificio para trabalhar os ZEROS dos 
# horarios menores que 10

DIG='0'

# Define os dias que serao extraidos

for HREF in `seq $HSTRT1 01 $HSTOP1`
do

DADOSORIPREF="cosmomet_10km_${HSIM}_${ANOI}${MESI}"
DADOSORIPREF1="cosmo_met5_${HSIM}_${ANOI}${MESI}"

	# Ajusta zeros no HREF para montar
	# a variavel DIA com 2 digitos

	if [ $HREF -lt 10 ];then
		DIA=$DIG$HREF
	else
		DIA=$HREF
	fi

	str="${str} ${DIA}"

	if [ -f ${DIRDADOSEXT}/horarios_${HSIM}_${ANOI}${MESI}${DIA} ];then

	rm ${DIRDADOSEXT}/horarios_${HSIM}_${ANOI}${MESI}${DIA}

	fi

	# Testa se o arquivo de ORIGEM existe

	if [ -f ${DIRDADOSORI}/${DADOSORIPREF}${DIA}${SUFIX} ];then

		echo
		echo " O arquivo foi encontrado e vou processa-lo."

		# Copiando o arquivo da parta original para a pasta NOVO_BACKUP

		echo " Copiando o arquivo da parta original para a pasta NOVO_BACKUP."

		cp ${DIRDADOSORI}/${DADOSORIPREF}${DIA}${SUFIX} ${DIRDADOSEXT}

		cd ${DIRDADOSEXT}

		# Destargeando o arquivo na pasta NOVO_BACKUP

		echo " Destargeando o arquivo na pasta NOVO_BACKUP."

#		bunzip2 -vf ${DIRDADOSEXT}/${DADOSORIPREF}${DIA}${SUFIX}
date
		tar -xjvf ${DIRDADOSEXT}/${DADOSORIPREF}${DIA}.tar.bz2
date
		mv home/admcosmo/cosmo/metarea5/data/prevdata${HSIM}/* .

		# HORA inicial
		HSTRT2=00

		# Calcula o horario final

		echo " Calculando o horario final."

		nhora=`ls -ltr ${DIRDADOSEXT}/${DADOSORIPREF1}${DIA}??? | wc -l`
		ult_hora=`echo "( ${nhora} * 3 - 3 )" | bc`
		HSTOP2=${ult_hora}

		if [ ${HSTOP2} -lt 10 ];then
                HSTOP2=0$DIG$HSTOP2
                elif [ $HSTOP2 -lt 100 ];then
                HSTOP2=$DIG$HSTOP2
                else
                HSTOP2=$HSTOP2
                fi

		echo " O horario final eh ${HSTOP2}."

		# define os horarios que serao trabalhados
		# de acordo com o intervalo INT. 

		for HREF2 in `seq $HSTRT2 $INT $HSTOP2`
		do

			if [ $HREF2 -lt 10 ];then
			HORA=0$DIG$HREF2
			elif [ $HREF2 -lt 100 ];then
			HORA=$DIG$HREF2
			else
			HORA=$HREF2
			fi

   			str2="${str2} ${HORA}"

			if [ -f ${DIRDADOSEXT}/${DADOSORIPREF1}${DIA}${HORA} ];then

				if [ ${HORA} == 000 ];then

					echo
					echo ${DADOSORIPREF1}${DIA}${HORA}  >> ${DIRDADOSEXT}/horarios_${HSIM}_${ANOI}${MESI}${DIA}
					echo ${DADOSORIPREF1}${DIA}${HORA}c >> ${DIRDADOSEXT}/horarios_${HSIM}_${ANOI}${MESI}${DIA}
					echo ${DADOSORIPREF1}${DIA}${HORA}p >> ${DIRDADOSEXT}/horarios_${HSIM}_${ANOI}${MESI}${DIA}
					echo ${DADOSORIPREF1}${DIA}${HORA}z >> ${DIRDADOSEXT}/horarios_${HSIM}_${ANOI}${MESI}${DIA}

				else

					echo
                                        echo ${DADOSORIPREF1}${DIA}${HORA}  >> ${DIRDADOSEXT}/horarios_${HSIM}_${ANOI}${MESI}${DIA}
                                        echo ${DADOSORIPREF1}${DIA}${HORA}p >> ${DIRDADOSEXT}/horarios_${HSIM}_${ANOI}${MESI}${DIA}
					echo ${DADOSORIPREF1}${DIA}${HORA}z >> ${DIRDADOSEXT}/horarios_${HSIM}_${ANOI}${MESI}${DIA}

				fi

			else

				echo
				echo " Nao encontrei o arquivo ${DIRDADOSEXT}/${DADOSORIPREF1}${DIA}${HORA}"

			fi

		done

		arquivos=`cat ${DIRDADOSEXT}/horarios_${HSIM}_${ANOI}${MESI}${DIA} | tr ' ' '\012' | sort | uniq | tr '\012' ' '`
		echo $arquivos | wc -w

		echo
		echo " Targeando arquivos."

		tar cjvf raw.${HSIM}${SUFIX} $arquivos

		if [ -f ${DIRDADOSEXT}/${DADOSORIPREF1}${DIA}${HSTOP2} ];then


                	# Deletando arquivos desnecessarios da pasta NOVO_BACKUP

                	echo " Deletando arquivos desnecessarios."

			echo
        		echo " Removendo arquivo de backup antigo ate ${HSTOP2}."
        		echo " arquivo ${DIRDADOSORI}/${DADOSORIPREF}${DIA}${SUFIX}"

                        rm ${DIRDADOSEXT}/${DADOSORIPREF1}${DIA}${SUFIX}
                        rm ${DIRDADOSEXT}/${DADOSORIPREF1}${DIA}*
			
			ls -ltr ${DIRDADOSORI}/${DADOSORIPREF}${DIA}.tar.bz2
			rm ${DIRDADOSORI}/${DADOSORIPREF}${DIA}.tar.bz2

                	# Agora copia raw.tar.bz2 para o novo original.

			echo " Agora copia raw.${HSIM}${SUFIX} para o novo original."

                	mv ${DIRDADOSEXT}/raw.${HSIM}${SUFIX} ${DIRDADOSEXT}/${DADOSORIPREF}${DIA}${SUFIX}

		else

			echo " Algum problema com o arquivo."
			echo " Pode ser pequeno demais."

		fi

		echo
		echo " Fim do processo para o dia ${DIA}${MESI}${ANOI}."

	else

		echo
		echo " Nao encontrei o arquivo ${DIRDADOSORI}/${DADOSORIPREF}${DIA}${SUFIX}."
		echo " Nao encontrei o arquivo ${DIRDADOSORI}/${DADOSORIPREF}${DIA}${SUFIX}." >> ${DIRDADOSEXT}/horarios_${HSIM}_${ANOI}${MESI}${DIA}
		echo
 
	fi

done
