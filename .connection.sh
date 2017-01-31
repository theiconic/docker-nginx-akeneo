#!/bin/bash

NET_SUBNET="${NET_SUBNET:=192.168.231}"

function make_connection()
{
	# Create the network
	printf "====== Creating network ...\n"
	(docker network inspect my_akeneo_network > /dev/null 2>&1 \
		|| docker network create -d bridge \
				--subnet "${NET_SUBNET}.0/26" \
				--gateway "${NET_SUBNET}.1" \
		 		my_akeneo_network || exit 20 )
	printf "Done\n"

}

make_connection