#!/bin/bash

# Descrição: Script que realiza as seguintes tarefas de segurança: 
#	1. Atualiza a base de vírus conhecidos do antivírus Clamav (https://docs.clamav.net).
#	2. Executa o scan a partir do diretório raiz (/) ou diretório/arquivo informado no primeiro argumento/parâmetro ($1).
#	3. Remove arquivos infectados, caso encontrado virus conhecidos conforme base de virus conhecidos do Clamav.
#	4. Insere diagnóstico do scan em arquivo ~/report_data_scan_$1.csv.
#
# Pré-requisito: 
#	1. Ter o antivírus clamav (https://docs.clamav.net) instalado no Linux e as extensões (ferramentas do clamav): 
#		1.1 freshclam (atualiza a base de vírus conhecidos) 
#		1.2 clamscan (realiza scan)
#  	2. Preferencialmente executar o script em modo su ou sudo - os arquivos de log e diagnósticos serão criados em /root
#
# Parâmetros/Argumentos (não obrigatórios):
# 	$1 Deve conter o diretório a partir do qual será aplicado o scan do antivíruis ou deve ser "desliga" caso seja necessário executar shutdown após execução do script.
# 	$2 Deve ser "desliga" (executa shutdown após execução do script). 
#
# stdout e stderr serão logados em ~/log/$(date +'%Y%m%d%H%M').log
# O arquivo que contém o histórico de diagnósticos, para o diretório/arquivo informado em $1 ou diretório raiz (/), gerado após o scan, será criado e incrementado em ~/report_data_scan_$1.csv
#
# Exemplos: 
#	1. ./antivirus_analyser.sh
#	2. ./antivirus_analyser.sh desliga
#	3. ./antivirus_analyser.sh /media/cdrom desliga

##### Autor: Rafael Zucon
##### e-mail: rafaelzucon@yahoo.com.br
##### Data de criação: 16 de Dezembro de 2024

var_process="JetBrains\|chrom\|sublime_text\|mousepad\|gimp\|firefox\|google\|Thunar\|thunar\|atril\|Atril\|libreoffice\|LibreOffice"
var_kill=$(echo $(ps -aux |grep "$(echo $var_process)" |grep -v "grep" |grep -v "kill-apps" |awk '{print $2}' |awk '{print $1}'))
n=${#var_kill}
if [[ $n -gt 0 ]]
then
        var_res=$(kill -9 $(echo $var_kill))
        echo $var_res
        echo "pid $var_kill"
        echo "killed $(date +'%Y-%m-%d %H:%M:%S')"
fi


function remove_bar(){ #remove as barras (/) de $1, caso existam, para adicionar sufixo ao nome do arquivo ~/report_data_scan_$1.csv
	str_name=$1
	str_treat=$(echo $str_name |sed 's/\//_/g')
	if [[ ${#str_treat} > 1 ]]
	then
		start=1;
		stop=${#str_treat}
		last_char=$(echo $str_treat | cut -c $stop-$stop)
		first_char=$(echo $str_treat | cut -c $start-$start)
		if [[ $first_char == "_" ]]
		then
			str_treat=$(echo $str_treat | cut -c $(($start+1))-$stop)
			stop=${#str_treat}
			last_char=$(echo $str_treat | cut -c $stop-$stop)
		fi

		if [[ $last_char == "_" ]]
		then
			str_treat=$(echo $str_treat | cut -c $start-$(($stop-1)))
		fi
	else
		if [[ $str_treat == "_" ]]
		then
			str_treat="all"
		fi
	fi
	sfx_file_report=$str_treat
}

function update_report(){
file_scan=$1
sfx_file_report=$2
remove_bar $sfx_file_report
file_path_report=$(echo "~/report_data_scan_$sfx_file_report.csv")
if [ ! -f $file_path_report ]
then
	touch $file_path_report
	echo "date_time;known_viruses;scanned_dir;scanned_files;total_errors;infected_files;data_scanned_MB;data_read_MB;time_sec" > $file_path_report
fi
known_viruses=$(echo $(cat "$(echo $file_scan)" |grep "Known viruses:" |awk '{print $3}'))
scanned_dir=$(echo $(cat "$(echo $file_scan)" |grep "Scanned directories:" |awk '{print $3}'))
scanned_files=$(echo $(cat "$(echo $file_scan)" |grep "Scanned files:" |awk '{print $3}'))
total_errors=$(echo $(cat "$(echo $file_scan)" |grep "Total errors:" |awk '{print $3}'))
infected_files=$(echo $(cat "$(echo $file_scan)" |grep "Infected files:" |awk '{print $3}'))
data_scanned_MB=$(echo $(cat "$(echo $file_scan)" |grep "Data scanned:" |awk '{print $3}' |sed 's/\./\,/'))
data_read_MB=$(echo $(cat "$(echo $file_scan)" |grep "Data read:" |awk '{print $3}' |sed 's/\./\,/'))
time_sec=$(echo $(cat "$(echo $file_scan)" |grep "Time:" |awk '{print $2}' |sed 's/\./\,/'))


echo "$start_date;$known_viruses;$scanned_dir;$scanned_files;$total_errors;$infected_files;$data_scanned_MB;$data_read_MB;$time_sec" >> $file_path_report

}

start_date=$(date +'%Y%m%d%H%M')
file_log=$(echo "$start_date.log")
file_path_log=$(echo "~/log/$file_log")
if [ ! -d "~/log" ]
then
	mkdir log
fi
touch $file_path_log
start_dir="/"
cd /
param1=$1
if [[ $1 != "desliga" && ${#param1} > 0 ]]
then
	start_dir=$1
fi
freshclam >> $file_path_log 2>&1
clamscan -r -i --remove=yes $start_dir >> $file_path_log 2>&1
sleep 2
update_report $file_path_log $start_dir
if [[ $1 == "desliga" || $2 == "desliga" ]]
then
	shutdown now 
fi
