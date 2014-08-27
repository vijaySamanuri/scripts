#!/bin/bash
container=${1:-"container"}
fixed_ip=${2:-"172.17.42.99"}
docker_bridge=${3:-"docker0"}
A=A$container
B=B$container

# get docker0 bridge ip and netmask
bridge_ip=$(/sbin/ip -4 -o addr show dev $docker_bridge|awk '{split($4,a,"/");print a[1]}')
bridge_netmask=$(/sbin/ip -4 -o addr show dev $docker_bridge|awk '{split($4,a,"/");print a[2]}')

pid=$(docker inspect -f '{{.State.Pid}}' $container)
mkdir -p /var/run/netns
find -L /var/run/netns -type l -delete
ln -s /proc/$pid/ns/net /var/run/netns/$pid
ip link add $A type veth peer name $B
brctl addif $docker_bridge $A
ip link set $A up
ip link set $B netns $pid
ip netns exec $pid ip link set dev $B name eth0
ip netns exec $pid ip link set eth0 up
ip netns exec $pid ip addr add $fixed_ip/$bridge_netmask dev eth0
ip netns exec $pid ip route add default via $bridge_ip
