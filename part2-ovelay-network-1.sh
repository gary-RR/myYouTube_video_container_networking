NS1="NS1"
NS2="NS2"
NODE_IP="192.168.0.10"
TUNNEL_IP="172.16.0.100"
BRIDGE_IP="172.16.0.1"
IP1="172.16.0.2"
IP2="172.16.0.3"
TO_NODE_IP="192.168.0.11"
TO_TUNNEL_IP="172.16.1.100"
TO_BRIDGE_IP="172.16.1.1"
TO_IP1="172.16.1.2"
TO_IP2="172.16.1.3"

echo "Creating the namespaces"
sudo ip netns add $NS1
sudo ip netns add $NS2

echo "Creating the veth pairs"
sudo ip link add veth10 type veth peer name veth11
sudo ip link add veth20 type veth peer name veth21

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
sudo ip link add name br0 type bridge

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

echo "Setting the default route in the network namespaces"
sudo ip netns exec $NS1 ip route add default via $BRIDGE_IP dev veth11
sudo ip netns exec $NS2 ip route add default via $BRIDGE_IP dev veth21

echo "Enables IP forwarding on the node"
sudo sysctl -w net.ipv4.ip_forward=1

# ------------------- Overlay setup --------------------- #

To establish the udp tunnel (make sure to run these as root (sudo -i)):

1- On "ubuntu1" run: 
socat UDP:192.168.0.11:9000,bind=192.168.0.10:9000 TUN:172.16.0.100/16,tun-name=tundudp,iff-no-pi,tun-type=tun &
#***Note that I removed "iff-up" switch from command on "ubuntu1" because I was getting an error. 

2- On "ubuntu2" run: 
socat UDP:192.168.0.10:9000,bind=192.168.0.11:9000 TUN:172.16.1.100/16,tun-name=tundudp,iff-no-pi,tun-type=tun,iff-up &

3- Return to "ubuntu1" and run
ip link set dev tundudp up

#echo "Disables reverse path filtering"
#sudo bash -c 'echo 0 > /proc/sys/net/ipv4/conf/all/rp_filter'
#sudo bash -c 'echo 0 > /proc/sys/net/ipv4/conf/eth0/rp_filter'
#sudo bash -c 'echo 0 > /proc/sys/net/ipv4/conf/br0/rp_filter'
#sudo bash -c 'echo 0 > /proc/sys/net/ipv4/conf/tundudp/rp_filter'

#----------------------------------Test --------------------------------------------#

#Check routes in container1
sudo ip netns exec $NS1 ip route

#Examine what route the route to reach one of the container on Ubuntu2
ip route get $TO_IP1

#Ping a container hosted on Ubuntu2 from a container hosted on this server(Ubuntu1)   
sudo ip netns exec $NS1 ping -c 4 $TO_IP1
