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
  	local decimal4=$((2#$octeto4))
  
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
	  if [[ ${nmask:i:1} == 1 && ${ip_sinPuntos:i:1} == 1 ]]; then
	    resultado+="1"
	  else
	    resultado+="0"
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

#128.66.14.99/15
#Address: 10000000.01000010.00001110.01100011 (128.66.14.99)
#Netmask: 11111111.11111110.00000000.00000000 (255.254.0.0)
#NetID  : 10000000.01000010.00000000.00000000 (128.66.0.0)
#BrCast : 10000000.01000011.11111111.11111111 (128.67.255.255)

validar_ip $1
if [ $? -eq 0 ]; then
	ip_cid=$1
	ip="$(echo $ip_cid | awk '{print $1}' FS='/')"
	cid=$(echo $ip_cid | awk '{print $2}' FS='/')
	ipBin="$(decToBin $ip)"
	ip_sinPuntos=$(echo $ipBin | tr -d ".")

	echo -e "\nNetmask:   $(calculateNetmaskBin $cid)"
	echo -e "Wildcard:  $(calculateWilcardBin $cid)"
	echo -e "NetworkId: $(calculateNetworkIdBin $ip $cid)"
	echo -e "Broadcast: $(calculateBroadcastBin $cid $ip)\n"

	netmask=$(convertirIp $(calculateNetmaskBin $cid))
	wildcard=$(convertirIp $(calculateWilcardBin $cid))
	networkid=$(convertirIp $(calculateNetworkIdBin $ip $cid))
	netbroadcast=$(convertirIp $(calculateBroadcastBin $cid $ip))

	echo -e "\n${yellowColour}[${endColour}${greenColour}+${endColour}${yellowColour}]${endColour}${grayColour} Netmask${endColour}${yellowColour}:${endColour}${blueColour} $netmask${endColour}"
	echo -e "${yellowColour}[${endColour}${greenColour}+${endColour}${yellowColour}]${endColour}${grayColour} Wilcard${endColour}${yellowColour}:${endColour}${blueColour} $wildcard${endColour}"
	echo -e "${yellowColour}[${endColour}${greenColour}+${endColour}${yellowColour}]${endColour}${grayColour} Network id${endColour}${yellowColour}:${endColour}${blueColour} $networkid/$cid${endColour}"
	echo -e "${yellowColour}[${endColour}${greenColour}+${endColour}${yellowColour}]${endColour}${grayColour} Broadcast${endColour}${yellowColour}:${endColour}${blueColour} $netbroadcast${endColour}"
	echo -e "${yellowColour}[${endColour}${greenColour}+${endColour}${yellowColour}]${endColour}${grayColour} Hosts posibles${endColour}${yellowColour}:${endColour}${blueColour} $(calculatePossibleHosts $cid)${endColour}\n"
else
	echo -e "\n${yellowColour}[${endColour}${redColour}!${endColour}${yellowColour}]${endColour}${grayColour} Uso $0${endColour} ${yellowColour}<${endColour}${grayColour}ip${endColour}${yellowColour}/${endColour}${grayColour}cid${endColour}${yellowColour}>, ej:${endColour}${blueColour} 192.168.1.1${endColour}${yellowColour}/${endColour}${blueColour}24${endColour}\n"
fi
