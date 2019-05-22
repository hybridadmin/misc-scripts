#!/bin/bash

if [[ `which yum` ]]; then
	DISTRO=$(cat /etc/*release | grep -E "^(Cent|Fedo|Redh)" | awk '{print $1}' | head -n1 | tr '[A-Z]' '[a-z]')
	RELEASE=$(sed 's/Linux//g' < /etc/redhat-release | awk '{print $3}' | tr -d " " | cut -c-1)
elif [[ `which apt` ]]; then
	DISTRO=$(lsb_release -is | tr '[A-Z]' '[a-z]')
	RELEASE=$(lsb_release -rs | cut -d '.' -f 1)
else
   echo "OS NOT DETECTED"
fi

function configure_firewall (){
	dest_port=$1
	dest_proto=$2
	source_addr=$3

	if [ $DISTRO == 'centos' ] || [ $DISTRO == 'redhat' ]; then
		if [ $RELEASE -ge 7 ]; then
			##firewalld
			sudo bash -c "firewall-cmd --permanent --zone=public --add-rich-rule='rule family=ipv4 source address="$source_addr" port port="$dest_port" protocol="$dest_proto" accept'"
			sudo firewall-cmd --reload
		else
			##iptables
			iptables -A INPUT -p $dest_proto -s $source_addr --dport $dest_port -j ACCEPT
		fi
	else
		if [ `ufw status | cut -d ' ' -f2` == "active" ]; then
			## ufw
			sudo ufw allow from $source_addr to any port $dest_port proto $dest_proto
		else
			## iptables
			iptables -A INPUT -p $dest_proto -s $source_addr --dport $dest_port -j ACCEPT
		fi
	fi
}
