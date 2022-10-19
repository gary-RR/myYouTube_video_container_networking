#!/bin/bash -e 

#!bash
NS1="NS1"
NS2="NS2"
NODE_IP="192.168.0.10"
BRIDGE_SUBNET="172.16.0.0/24"
BRIDGE_IP="172.16.0.1"
IP1="172.16.0.2"
IP2="172.16.0.3"
TO_NODE_IP="192.168.0.11"
TO_BRIDGE_SUBNET="172.16.1.0/24"
TO_BRIDGE_IP="172.16.1.1"
TO_IP1="172.16.1.2"
TO_IP2="172.16.1.3"

echo "Creating the namespaces"
sudo ip netns add $NS1
sudo ip netns add $NS2
    ip netns show

echo "Creating the veth pairs"
sudo ip link add veth10 type veth peer name veth11
sudo ip link add veth20 type veth peer name veth21
    ip link show type veth
        #ip link show veth11
        #ip link show veth20    

echo "Adding the veth pairs to the namespaces"
sudo ip link set veth11 netns $NS1
sudo ip link set veth21 netns $NS2

echo "Configuring the interfaces in the network namespaces with IP address"
sudo ip netns exec $NS1 ip addr add $IP1/24 dev veth11 
sudo ip netns exec $NS2 ip addr add $IP2/24 dev veth21 

echo "Enabling the interfaces inside the network namespaces"
sudo ip netns exec $NS1 ip link set dev veth11 up
sudo ip netns exec $NS2 ip link set dev veth21 up

echo "Creating the bridge"
sudo ip link add br0 type bridge
    ip link show type bridge
        ip link show br0
        #sudo ip link delete br0

echo "Adding the network namespaces interfaces to the bridge"
sudo ip link set dev veth10 master br0
sudo ip link set dev veth20 master br0

echo "Assigning the IP address to the bridge"
sudo ip addr add $BRIDGE_IP/24 dev br0

echo "Enabling the bridge"
sudo ip link set dev br0 up

echo "Enabling the interfaces connected to the bridge"
sudo ip link set dev veth10 up
sudo ip link set dev veth20 up

echo "Setting the loopback interfaces in the network namespaces"
sudo ip netns exec $NS1 ip link set lo up
sudo ip netns exec $NS2 ip link set lo up
    sudo ip netns exec $NS1 ip a
    sudo ip netns exec $NS2 ip a

echo "Setting the default route in the network namespaces"
sudo ip netns exec $NS1 ip route add default via $BRIDGE_IP dev veth11
sudo ip netns exec $NS2 ip route add default via $BRIDGE_IP dev veth21

# ------------------- Step 3 Specific Setup --------------------- #

echo "Setting the route on the node to reach the network namespaces on the other node"
sudo ip route add $TO_BRIDGE_SUBNET via $TO_NODE_IP dev eth0

echo "Enables IP forwarding on the node"
sudo sysctl -w net.ipv4.ip_forward=1

#--------------------Tests------------------------------

#Ping adaptor attached to NS1
sudo ip netns exec $NS1 ping -W 1 -c 2 172.16.0.2

#Ping the bridge
sudo ip netns exec $NS1 ping -W 1 -c 2 172.16.0.1

#Ping the adaptor of the second container
sudo ip netns exec $NS1 ping -W 1 -c 2 172.16.0.3

#Ping the other server (Ubuntu2)
sudo ip netns exec $NS1 ping -W 1 -c 2 192.168.0.11

#Ping the bridge on "Ubuntu2" server
sudo ip netns exec $NS1 ping -W 1 -c 2 172.16.1.1

#Ping the first container on "Ubuntu2"
sudo ip netns exec $NS1 ping -W 1 -c 2 172.16.1.2

#Ping the second container on "Ubuntu2"
sudo ip netns exec $NS1 ping -W 1 -c 10 172.16.1.3

