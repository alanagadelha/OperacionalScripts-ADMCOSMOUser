###########################################################
#
# Step-by-step to create developer Enviromental
# Created by CT(T) Alana, 26th of september 2019
##########################################################
#
#
# copy cosmo from admcosmo to cosmo_benchmark
#

# Criando uma chave publica para acesso

#admcosmo@dpns31:~> cd .ssh/
#admcosmo@dpns31:~/.ssh> ssh-copy-id -i id_rsa.pub cosmo_benchmark@dpns32

#Criando a estrutura de diretorios COSMO METAREA

DIRRAIZ=${HOME}
AREA1=metarea5
LISTADIR=" backup00 backup12 const cptec00 cptec12 gmedata hycom_00 hycom_12 icondata init_cond00 init_cond00_2 init_cond12 init_cond12_2 nudging prevdata00 prevdata12 prev_pontos00 prev_pontos12 ready00 ready12 restart00 restart12 sarmap00 sarmap12 sisgeodef00 sisgeodef12 valida_00 valida_12 vento00 vento12 "

ssh cosmo_benchmark@10.13.100.31 2>> /dev/null << EOF
  mkdir -p ${DIRRAIZ}/${AREA1}/ajustes
  mkdir -p ${DIRRAIZ}/${AREA1}/runlog
  mkdir -p ${DIRRAIZ}/${AREA1}/verif_log
  mkdir -p ${DIRRAIZ}/${AREA1}/cosmo
  mkdir -p ${DIRRAIZ}/${AREA1}/icon2cosmo
	for i in ${LISTADIR};do
	mkdir -p ${DIRRAIZ}/${AREA1}/data/${LISTADIR}
	done
EOF

#Copiando a estrutura da METAREAV
ORIGEM=/home/admcosmo/cosmo/${AREA1}

scp ${ORIGEM}/ajustes/*.txt cosmo_benchmark@10.13.100.31:${DIRRAIZ}/${AREA1}/ajustes/
scp ${ORIGEM}/cosmo/cosmo* ${ORIGEM}/cosmo/divisao_dominio.txt  ${ORIGEM}/cosmo/INPUT_COSMO  ${ORIGEM}/cosmo/mpirunarg.txt  ${ORIGEM}/cosmo/tmpl*  ${ORIGEM}/cosmo/lista_nos.txt cosmo_benchmark@10.13.100.31:${DIRRAIZ}/${AREA1}/cosmo/
scp ${ORIGEM}/icon2cosmo/icon* ${ORIGEM}/icon2cosmo/tmpl* ${ORIGEM}/icon2cosmo/README cosmo_benchmark@10.13.100.31:${DIRRAIZ}/${AREA1}/icon2cosmo/

exit 
