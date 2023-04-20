#!/bin/bash

#Colours
greenColour="\e[0;32m\033[1m"
endColour="\033[0m\e[0m"
redColour="\e[0;31m\033[1m"
blueColour="\e[0;34m\033[1m"
yellowColour="\e[0;33m\033[1m"
purpleColour="\e[0;35m\033[1m"
turquoiseColour="\e[0;36m\033[1m"
grayColour="\e[0;37m\033[1m"

ctrl_c() {
	echo -e "\n\n${redColour}[!] Saliendo...\n${endColour}"
	exit 1
}

#CTRL+C
trap ctrl_c INT

function convertirIp() {

  	local octeto1=${1:0:8}
  	local octeto2=${1:8:8}
  	local octeto3=${1:16:8}
  	local octeto4=${1:24:8}

  	
  	local decimal1=$((2#$octeto1))
  	local decimal2=$((2#$octeto2))
  	local decimal3=$((2#$octeto3))

  	if [ "$2" == "max" ]; then
  		decimal4=$(( $((2#$octeto4)) - 1 ))
  	elif [ "$2" == "min" ]; then
  		decimal4=$(( $((2#$octeto4)) + 1 ))
  	else
  		decimal4=$((2#$octeto4))
  	fi
  	echo "${decimal1}.${decimal2}.${decimal3}.${decimal4}"
}

function decToBin() {
    finalBinIp=""
    ipTemp=$(echo $1 | tr "." " ")
    for seg in $ipTemp; do
        binSeg=$(echo "obase=2;$seg" | bc)
        paddedBinSeg=$(printf "%08d" $binSeg)
        finalBinIp+="${paddedBinSeg}."
    done
    echo "${finalBinIp%?}"

}

function calculateAddressBin() {
	ipBin=$(decToBin $1)
	ip_sinPuntos=$(echo $ipBin | tr -d ".")
	echo "$ip_sinPuntos"
}

function calculateNetmaskBin() {
	netmask=""
	net=$(( $1 ))
	host=$((32 - $net))
	
	for nmask in {1..32}; do
		if [ $nmask -gt $net ]; then
			netmask+="0"
		else
			netmask+="1"
		fi
	done

	echo "$netmask"

}


function calculateWilcardBin() {
	netmask=""
	net=$(( $1 ))
	host=$((32 - $net))
	
	for nmask in {1..32}; do
		if [ $nmask -gt $net ]; then
			netmask+="1"
		else
			netmask+="0"
		fi
	done

	echo "$netmask"

}

function calculateNetworkIdBin() {
	ipBin=$(decToBin $1)
	ip_sinPuntos=$(echo $ipBin | tr -d ".")
	
	nmask=$(calculateNetmaskBin $2)

	for (( i=0; i<${#nmask}; i++ )); do
		
		if [[ ! ${nmask:i:1} == '.' ]]; then
			if [[ ${nmask:i:1} == 1 && ${ip_sinPuntos:i:1} == 1 ]]; then  # si los 2 son un 1 agregamos un 1
	    		resultado+="1"
	  		else														  # de lo contrario agregamos 0
	    		resultado+="0"
	  		fi
	  	else
	  		resultado+="."
	  	fi
	done

	echo "$resultado"
}


function calculateBroadcastBin() {
	net=$(( $1 ))
	host=$((32 - $net))
	ipBin="$(decToBin $2)"

	broadcast=""

	ip_sinPuntos=$(echo $ipBin | tr -d ".")
	for (( i=0; i<${#ip_sinPuntos}; i++ )); do
		if [ $i -ge $net ]; then
			broadcast+="1"
		else
			broadcast+=${ip_sinPuntos:i:1}
		fi

	done
	echo "$broadcast"
}

# Calculamos los hosts disponibles para el netmask introducido
function calculatePossibleHosts() {
    host=$((32 - $1))
    echo $((2 ** $host - 2))

}

function validar_ip() {
	if [[ $1 =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}/[0-9]{1,2}$ && !($1 =~ [^0-9./]) ]]; then
		return 0
  	else
    	return 1
  	fi
}

# Funcion que me permite repetir un caracter un numero de veces indicado
function repeat(){
	local start=1
	local end=${1:-80}
	local str="${2:-=}"
	local range=$(seq $start $end)
	for i in $range ; do echo -n "${str}"; done
}

validar_ip $1

if [ $? -eq 0 ]; then
	ip_cid=$1
	ip="$(echo $ip_cid | awk '{print $1}' FS='/')" #10.0.0.0
	cid=$(echo $ip_cid | awk '{print $2}' FS='/')  #24
	ipBin="$(decToBin $ip)" # 00000000.00000000.00000000.00000000
	ip_sinPuntos=$(echo $ipBin | tr -d ".") # 00000000000000000000000000000000
	
	class=""
	private=""

	# Convertimos a formato 0.0.0.0/24
	address=$(convertirIp $(calculateAddressBin $ip))
	netmask=$(convertirIp $(calculateNetmaskBin $cid))
	wildcard=$(convertirIp $(calculateWilcardBin $cid))
	networkid=$(convertirIp $(calculateNetworkIdBin $ip $cid))
	netbroadcast=$(convertirIp $(calculateBroadcastBin $cid $ip))
	min=$(convertirIp $(calculateNetworkIdBin $ip $cid) $(echo "min"))
	max=$(convertirIp $(calculateBroadcastBin $cid $ip) $(echo "max"))
	
	# Calculamos cantidad des espacios para alinear columnas
	address_spaces=$(repeat $(( 17 - ${#address} )) ' '; echo)
	netmask_spaces=$(repeat $(( 17 - ${#netmask} )) ' '; echo)
	wildcard_spaces=$(repeat $(( 17 - ${#wildcard} )) ' '; echo)
	networkid_spaces=$(repeat $(( 16 - ${#networkid} - ${#cid} )) ' '; echo)
	netbroadcast_spaces=$(repeat $(( 17 - ${#netbroadcast} )) ' '; echo)
	min_spaces=$(repeat $(( 17 - ${#min} )) ' '; echo)
	max_spaces=$(repeat $(( 17 - ${#max} )) ' '; echo)
	first_segment=$(echo $address | awk '{print $1}' FS='.')



	# Mostramos en consola las conversiones

	echo -e "\n${yellowColour}[${endColour}${greenColour}+${endColour}${yellowColour}]${endColour}${grayColour} Address${endColour}${yellowColour}:${endColour}${blueColour}   $address${endColour}$address_spaces${turquoiseColour}$(calculateAddressBin $ip)${endColour}"
	echo -e "${yellowColour}[${endColour}${greenColour}+${endColour}${yellowColour}]${endColour}${grayColour} Netmask${endColour}${yellowColour}:${endColour}${blueColour}   $netmask${endColour}$netmask_spaces${turquoiseColour}$(calculateNetmaskBin $cid)${endColour}"
	echo -e "${yellowColour}[${endColour}${greenColour}+${endColour}${yellowColour}]${endColour}${grayColour} Wilcard${endColour}${yellowColour}:${endColour}${blueColour}   $wildcard${endColour}$wildcard_spaces${turquoiseColour}$(calculateWilcardBin $cid)${endColour}"
	echo -e "${yellowColour}[${endColour}${greenColour}+${endColour}${yellowColour}]${endColour}${grayColour} Network${endColour}${yellowColour}:${endColour}${blueColour}   $networkid/$cid${endColour}$networkid_spaces${turquoiseColour}$(calculateNetworkIdBin $ip $cid)${endColour}"
	echo -e "${yellowColour}[${endColour}${greenColour}+${endColour}${yellowColour}]${endColour}${grayColour} Broadcast${endColour}${yellowColour}:${endColour}${blueColour} $netbroadcast${endColour}$netbroadcast_spaces${turquoiseColour}$(calculateBroadcastBin $cid $ip)${endColour}"
	echo -e "${yellowColour}[${endColour}${greenColour}+${endColour}${yellowColour}]${endColour}${grayColour} HostMin${endColour}${yellowColour}:${endColour}${blueColour}   $min${endColour}$min_spaces${turquoiseColour}$(echo $(decToBin $min) | tr -d ".")${endColour}"
	echo -e "${yellowColour}[${endColour}${greenColour}+${endColour}${yellowColour}]${endColour}${grayColour} HostMax${endColour}${yellowColour}:${endColour}${blueColour}   $max${endColour}$max_spaces${turquoiseColour}$(echo $(decToBin $max) | tr -d ".")${endColour}"
		

	# Detectamos la clase y aprobechamos para mostrar colores distintos para el valor de Net

	if [ $first_segment -gt 1 ]  && [ $first_segment -le 9 ]; then
		class="A"
		echo -e "${yellowColour}[${endColour}${greenColour}+${endColour}${yellowColour}]${endColour}${grayColour} Net${endColour}${yellowColour}:${endColour}${redColour}       Public${endColour}"
	elif [ $first_segment -eq 10 ]; then
		class="A"
		echo -e "${yellowColour}[${endColour}${greenColour}+${endColour}${yellowColour}]${endColour}${grayColour} Net${endColour}${yellowColour}:${endColour}${grayColour}       Private${endColour}"
	elif [ $first_segment -ge 11 ]  && [ $first_segment -le 126 ]; then
		class="A"
		echo -e "${yellowColour}[${endColour}${greenColour}+${endColour}${yellowColour}]${endColour}${grayColour} Net${endColour}${yellowColour}:${endColour}${redColour}       Public${endColour}"
	elif [ $first_segment -eq 127 ] ; then
		class="A"
		echo -e "${yellowColour}[${endColour}${greenColour}+${endColour}${yellowColour}]${endColour}${grayColour} Net${endColour}${yellowColour}:${endColour}${greenColour}       Local${endColour}"
	elif [ $first_segment -ge 128 ] && [ $first_segment -le 191 ]; then
		class="B"
		echo -e "${yellowColour}[${endColour}${greenColour}+${endColour}${yellowColour}]${endColour}${grayColour} Net${endColour}${yellowColour}:${endColour}${redColour}       Public${endColour}"
	elif [ $first_segment -eq 192 ] ; then
		class="A"
		echo -e "${yellowColour}[${endColour}${greenColour}+${endColour}${yellowColour}]${endColour}${grayColour} Net${endColour}${yellowColour}:${endColour}${greenColour}       Local${endColour}"
	elif [ $first_segment -ge 193 ] && [ $first_segment -le 223 ]; then
		class="C"
		echo -e "${yellowColour}[${endColour}${greenColour}+${endColour}${yellowColour}]${endColour}${grayColour} Net${endColour}${yellowColour}:${endColour}${redColour}       Public${endColour}"
	elif [ $first_segment -ge 224 ] && [ $first_segment -le 239 ]; then
		class="D"
		echo -e "${yellowColour}[${endColour}${greenColour}+${endColour}${yellowColour}]${endColour}${grayColour} Net${endColour}${yellowColour}:${endColour}${redColour}       Public${endColour}"
	elif [ $first_segment -ge 240 ] && [ $first_segment -le 247 ]; then
		class="E"
		echo -e "${yellowColour}[${endColour}${greenColour}+${endColour}${yellowColour}]${endColour}${grayColour} Net${endColour}${yellowColour}:${endColour}${redColour}       Public${endColour}"
 	else
		class="unknow"
	fi


	echo -e "${yellowColour}[${endColour}${greenColour}+${endColour}${yellowColour}]${endColour}${grayColour} Hosts${endColour}${yellowColour}:    ${endColour}${yellowColour} $(calculatePossibleHosts $cid)${endColour}"
	echo -e "${yellowColour}[${endColour}${greenColour}+${endColour}${yellowColour}]${endColour}${grayColour} Class${endColour}${yellowColour}:${endColour}${yellowColour}     $class${endColour}\n"

else
	echo -e "\n${yellowColour}[${endColour}${redColour}!${endColour}${yellowColour}]${endColour}${grayColour} Uso $0${endColour} ${yellowColour}<${endColour}${grayColour}ip${endColour}${yellowColour}/${endColour}${grayColour}cid${endColour}${yellowColour}>, ej:${endColour}${blueColour} 192.168.1.1${endColour}${yellowColour}/${endColour}${blueColour}24${endColour}\n"
fi
