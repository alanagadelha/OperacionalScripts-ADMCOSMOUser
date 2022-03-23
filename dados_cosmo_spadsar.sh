#!/bin/bash


cdo="/usr/local/lib/.pyenv/shims/cdo"
ncdump="/mnt/nfs/dpns33/data1/home_dpns31/gast/intel_13.0.1/libraries/bin/ncdump"
HH=$1

if [ $# -lt 1 ]; then 
	echo "Entre com o horário 00 ou 12"
	exit 444 
fi   

data=`date +%Y%m%d`
data_day=`echo $data | cut -c 7,8`

echo " Hoje é dia ${data_day}"

dados_spadsar="/home/admcosmo/cosmo/metarea5/data/spadsar${HH}"
dirwork_spadsar="/home/admcosmo/cosmo/scripts/Spadsar"


#### Remove os arquivos com mais de 2 dias antes de iniciar cada rodada
find ${dirwork_spadsar}/cosmo* -mtime +2 -exec rm {} \;



#### Variável $var_tempos verifica o numero de tempos que tem no arquivo do dia cosmo_uv_${data}00_24.nc.Se for 24 é o correto e não precisa fazer de novo o script abaixo. Fiz isso pq quando o 05.1_exec_cosmo roda uma rodada a mais (por teste ou afins) ele adicionava mais tempos ao arquivo NETCDF
var_tempos=`${ncdump} -h ${dirwork_spadsar}/cosmo_uv_${data}00_24.nc | head -3 | tail -1 | cut -d "(" -f2 | cut -c1,2`

if [ ${var_tempos} == 24 ];then
	echo "Eu não vou mais fazer a rodada, pq já tem o arquivo do dia com os tempos corretos (24 tempos)"

	exit  
else
	echo "Fazendo a rodada operacional"

fi


cd ${dados_spadsar}

### Essa é a lista com os últimos arquivos para cada dia
list_file="lfff00230000.nc lfff01230000.nc lfff02230000.nc lfff03230000.nc"  

echo " ${list_file}"
#### É a projeção de horas em relação ao inicio da rodada. Começando pelas primeiras 24 horas (00 a 23) do dia 0
hr_proj=24 

for last_file in ${list_file} ;do 

	last_file_day=`echo $last_file | cut -c 6`
	
	echo " Estou trabalhando com os arquivos do dia $last_file_day e o seu último arquivo é o $last_file"

	#### Dando um nome para o arquivo final
	file_out="${dirwork_spadsar}/cosmo_uv_${data}${HH}_${hr_proj}.nc"
	### Preciso zerar o variável file_in para quando entrar no primeiro for e usar o outro dia last_file_day ele só carregue os arquivos do dia	
	file_in=" "
	
	for i in `seq -w 00 23`;do 

	file="lfff0${last_file_day}${i}0000.nc" 
	file_in="${file_in} $file"

	echo $file_in
	done
	
	nt=0
	HABORT=360
	FLAG=1
	while [ ${FLAG} -eq 1 ] && [ ${nt} -le ${HABORT} ];do
	
	echo "Verificando se o arquivo do existe e se a data do arquivo $last_file equivale a do dia atual"
	
	#### Quero confirmar que o arquivo é do dia de hoje e por isso o comando abaixo para olhar o dado
	file_data_created=`/home/gast/intel_13.0.1/libraries/bin/ncdump -h ${dados_spadsar}/$last_file | tail -2 | head -1 | cut -d"-" -f3 | cut -d" " -f1`
		
		if [ -e ${last_file} ] && [ ${file_data_created} == ${data_day} ];then 
			echo "Então o arquivo existe $last_file"

			## Aqui eu monto o arquivo que será enviado para o ComOpNav
			## Faço isso apenas com um cat acrescentando os arquivo do dia $last_file_day em um só arquivo com o nome cosmo_uv_${data}${HH}_${hr_proj}.nc
			echo "$cdo cat $file_in $file_out"
			#/usr/local/cdo/bin/cdo cat $file_in $file_out
			$cdo cat $file_in $file_out

			FLAG=0
		else
		
			echo "O arquivo não existe ou a data do arquivo nao esta atualizada"
		
			if [ ${nt} -eq ${HABORT} ];then

                        	echo " Apos ${HABORT} ciclos, ABORTEI ao esperar o arquivo ${last_file}."
                        	echo " Saindo por EXIT 02."
				exit 02

			fi
		
		sleep 60
		nt=$((nt+1))
	
		fi
	

	done	

	hr_proj=`echo "$hr_proj + 24" | bc`
done


