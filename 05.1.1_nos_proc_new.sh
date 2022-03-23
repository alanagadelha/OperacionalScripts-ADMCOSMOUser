#!/bin/bash
# Este script verifica quais nos estao ligados para serem utilizados
# Quantos processadores estao ok 
# E utiliza um criterio de horario e prioridade
set -x
set -v

# definindo o numero maximo de processadores de acordo com o horario

# Verificando a hora


if [ $# -lt 1 ]
then
echo " Voce deve entrar com a AREA e adicionalmente informar o numero de processadores em X e em Y"
exit 12 
fi


AREA=$1

# caso tenha sido especificado o numero de processadores estes serao utilizados aqui
if [ $# -eq 3 ]
then
nprocx=$2
nprocy=$3
nprocf=`echo "$nprocx * $nprocy" | bc`
else
nprocf=0
fi

# capturando a hora atual
time=`date`
hr=`echo $time | awk ' { print $4 } ' | cut -f1 -d:`
mn=`echo $time | awk ' { print $4 } ' | cut -f2 -d:`

# transformando a hora atual em minutos passados desde 00:00
tempo=`echo "$hr * 60 + $mn" | bc`

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

# definindo onde esta o arquivo com as janelas de tempo para uso dos nos
FILETIME=$WORKDIR/ajustes/times.txt

# deletando as linhas com comentarios
cat $FILETIME | sed -e '/#/d' > rawtimes.txt
NLINES=`cat rawtimes.txt | wc -l`

for i in `seq 1 $((NLINES-1))`
do

# calculando o tempo em minutos equivalente a cada linha do arquivo de janela de tempo
linha1=`head -$i rawtimes.txt | tail -1`
linha2=`head -$((i+1))  rawtimes.txt | tail -1`
hora1=`echo $linha1 | awk ' { print $1 } ' | cut -f1 -d:`
hora2=`echo $linha2 | awk ' { print $1 } ' | cut -f1 -d:`
min1=`echo $linha1 | awk ' { print $1 } ' | cut -f2 -d:`
min2=`echo $linha2 | awk ' { print $1 } ' | cut -f2 -d:`    
tempo1=`echo "$hora1 * 60 + $min1" | bc`
tempo2=`echo "$hora2 * 60 + $min2" | bc` 

# verificando entre que linhas a hora atual estaria encaixada dentro da janela
if [ $tempo -ge $tempo1 ] && [ $tempo -le $tempo2 ]
then
nos=`echo $linha2 | cut -f2-10 -d" "`
fi

done

rm rawtimes.txt

# verificando quantos grupos r1in estao presentes na linha selecionada
Nnos=`echo $nos | grep -o "," | wc -l`

rm lista_nos.txt

for i in `seq 1 $Nnos`
do

# separando a informacao de cada rack que podera ser utilizado e o intervalo de nos disponiveis
info=`echo $nos | cut -f$i -d","`
rack=`echo $info | cut -f1 -d" "`
no1=`echo $info | cut -f2 -d" "`
no2=`echo $info | cut -f3 -d" "`


for n in `seq $no1 $no2`
do

# verificando se o no esta em cima
ping -q -c 1 $rack$n > /dev/null
err=$?
if [ $err -eq 0 ]
then

cat <<EOM >no.txt
cluster blades {
    dpns31

    ${rack}${n} 
}

EOM


# verificando quantos processadores estao disponiveis nesse no
nprocs=`cexec -f no.txt cat /proc/cpuinfo | grep processor | wc -l`
# montando a lista com nos e processadores disponiveis
echo "$rack$n $nprocs," >> lista_nos.txt
fi

done

done

# retirando os nos utilizados pelo COSMO2ICON desta lista

noicon1=`cat $WORKDIR/ajustes/no1_icon2cosmo.txt`
noicon2=`cat $WORKDIR/ajustes/no2_icon2cosmo.txt`
sed '/'$noicon1'/d' lista_nos.txt > raw.txt
#mv raw.txt lista_nos.txt
sed '/'$noicon2'/d' raw.txt > lista_nos.txt
rm raw.txt

# calculando quantos processadores estao disponiveis

NPROCSDISP=`cat lista_nos.txt | sed -e 's/,//' | awk -F " " '{n+=$2} END {print n}'`
echo " Existem $NPROCSDISP disponiveis"

# contando quantas opcoes de configuracao de distribuicao de processadores entre X e Y no dominio estao disponiveis
nlinhas=`cat $WORKDIR/ajustes/processadores.txt | wc -l`


# utilizando o arquivo processadores.txt para definir o numero de processadores caso eles nao tenham sido informados

procio=0

if [ $nprocf -eq 0 ]
then

 for i in `seq 1 $nlinhas`
 do
 processadores=`head -$i $WORKDIR/ajustes/processadores.txt | tail -1 `
 procx=`echo $processadores | cut -f1 -d" "`
 procy=`echo $processadores | cut -f2 -d" "`

 nprocs=`echo "$procx * $procy + $procio" | bc`

# verificando quais destas configuracoes maximiza o numero de processadores a serem utilizados sem ultrapassar o numero de processadores disponiveis

  if [ $nprocs -le $NPROCSDISP ] && [ $nprocs -gt $nprocf ]
  then
  nprocf=$nprocs
  nprocx=$procx
  nprocy=$procy
  nprocio=$procio
  fi

  done

else

if [ $nprocf -gt $NPROCSDISP ]
then
echo " Voce especificou NPROCX = $procx"
echo " Voce especificou NPROCY = $procy"
echo " Voce especificou NPROCY = $procio"
echo " A multiplicacao NPROCX * NPROCY + NPROCIOrepresenta um numero de processadores maior que o numero $NPROCSDISP de processadores disponiveis"
exit 12
fi


fi
k=1
n=0
linhas=""

nprocs=$nprocf



while [ $n -lt $nprocs ]
do
linha=`cat lista_nos.txt | head -$k | tail -1`
proc=`echo $linha | cut -f2 -d" " | sed -e 's|,||'`
n=$((n+proc))
linhas=`echo $linhas" "$linha`
k=$((k+1))
done

if [ $n -gt $nprocs ]
then
diff=$((n-nprocs))
no=`echo $linha | cut -f1 -d" "`
pr=`echo $linha | cut -f2 -d" " |  sed -e 's|,||'`
p2=$((pr-diff))
linhas=`echo $linhas | sed -e 's|'$no' '$pr',||'`
linhas=`echo $linhas" "$no" "$p2`
fi

if [ $n -eq $nprocs ]
then
linhas2=`echo $linhas | sed ':a;$!{N;ba;};s/\(.*\),/\1 /'`
linhas=$linhas2
fi

echo $linhas >  $WORKDIR/cosmo/mpirunarg.txt

echo "$nprocx $nprocy $nprocio" > $WORKDIR/cosmo/divisao_dominio.txt 

rm lista_nos.txt

exit 0


