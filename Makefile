#linux update
update:
	sudo apt update;
	sudo apt upgrade -y;
	sudo apt install iproute2;
	sudo apt install net-tools;

#Task:1 -Create Network bridges
create_bridge:
	sudo ip link add dev br0 type bridge;
	sudo ip link add dev br1 type bridge;

#make bridges state up
	sudo ip link set dev br0 up;
	sudo ip link set dev br1 up;

#Task:2 -Create Network namespace
create_ns:
	sudo ip netns add ns1;
	sudo ip netns add ns2;
	sudo ip netns add router-ns;
#list network namespace
	sudo ip netns list

#Task:3 -Create Virtual Interfaces and Connections
create_veth:
#create interfaces with correct pair
	sudo ip link add veth-ns1 type veth peer name veth-br0;
	sudo ip link add veth-ns2 type veth peer name veth-br1;
	sudo ip link add vr-br0 type veth peer name vr-ns1;
	sudo ip link add vr-br1 type veth peer name vr-ns2;

#connect interfaces to correct namesapce and bridges
	sudo ip link set dev veth-ns1 netns ns1;
	sudo ip link set dev veth-br0 master br0;

	sudo ip link set dev veth-ns2 netns ns2;
	sudo ip link set dev veth-br1 master br1;

	sudo ip link set dev vr-br0 master br0;
	sudo ip link set dev vr-ns1 netns router-ns;

	sudo ip link set dev vr-br1 master br1;
	sudo ip link set dev vr-ns2 netns router-ns;

#make namespace interface up
	sudo ip netns exec ns1 ip link set dev veth-ns1 up;
	sudo ip netns exec ns2 ip link set dev veth-ns2 up;
	sudo ip netns exec router-ns ip link set dev vr-ns1 up;
	sudo ip netns exec router-ns ip link set dev vr-ns2 up;

#make bridge interface up
	sudo ip link set dev veth-br0 up;
	sudo ip link set dev veth-br1 up;
	sudo ip link set dev vr-br0 up;
	sudo ip link set dev vr-br1 up;

#Task:4-Configure IP addresses
assign_ip:
	sudo ip address add 10.11.0.1/24 dev br0;
	sudo ip address add 10.11.0.3/24 dev vr-br0;
	
	sudo ip address add 10.12.0.1/24 dev br1;
	sudo ip address add 10.12.0.3/24 dev vr-br1;

	sudo ip netns exec ns1 ip address add 10.11.0.2/24 dev veth-ns1;
	
	sudo ip netns exec ns2 ip address add 10.12.0.2/24 dev veth-ns2;
	
	sudo ip netns exec router-ns ip address add 10.13.0.2/24 dev vr-ns1;
	sudo ip netns exec router-ns ip address add 10.13.0.3/24 dev vr-ns2;


#Task:5-Set Up Routing
ip_forward:
#default route in namespace
	sudo ip netns exec ns1 ip route add default via 10.11.0.1;
	sudo ip netns exec ns2 ip route add default via 10.12.0.1;

#routing in the bridge to make sure traffice route to the different network
	ip route add 10.12.0.0/16 dev vr-br0;
	ip route add 10.11.0.0/16 dev vr-br1;

#routing between network in router-ns
	sudo ip netns exec router-ns ip route add 10.11.0.0/16 dev vr-ns1;
	sudo ip netns exec router-ns ip route add 10.12.0.0/16 dev vr-ns2;

#enabling IP forwarding 
	sudo iptables --append FORWARD --in-interface br0 --jump ACCEPT;
	sudo iptables --append FORWARD --out-interface br0 --jump ACCEPT;
	sudo iptables --append FORWARD --in-interface br1 --jump ACCEPT;
	sudo iptables --append FORWARD --out-interface br1 --jump ACCEPT;

#Clean up
clean_up:
	sudo ip netns del ns1;
	sudo ip netns del ns2;
	sudo ip netns del roter-ns;

	sudo ip link delete br0 type bridge;
	sudo ip link delete br1 type bridge;
