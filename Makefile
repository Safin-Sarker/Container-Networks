.PHONY: setup test clean

setup:
	@echo "Creating namespaces..."
	sudo ip netns add red 
	sudo ip netns add blue 
	sudo ip netns add route 

	@echo "Creating and enabling bridges..."
	sudo ip link add br0 type bridge 
	sudo ip link add br1 type bridge 
	sudo ip link set br0 up
	sudo ip link set br1 up

	@echo " Creating veth pairs for red and blue..."
	sudo ip link add veth-red type veth peer name v-red-ns 
	sudo ip link add veth-blue type veth peer name v-blue-ns
	sudo ip link set v-red-ns netns red
	sudo ip link set veth-red master br0
	sudo ip link set veth-red up

	sudo ip link set v-blue-ns netns blue
	sudo ip link set veth-blue master br1
	sudo ip link set veth-blue up

	@echo "Creating veth pairs for router..."
	sudo ip link add vr-red-ns type veth peer name vr-red 
	sudo ip link add vr-blue-ns type veth peer name vr-blue 

	sudo ip link set vr-red-ns netns route
	sudo ip link set vr-red master br0
	sudo ip link set vr-red up

	sudo ip link set vr-blue-ns netns route
	sudo ip link set vr-blue master br1
	sudo ip link set vr-blue up

	@echo "Assigning IPs..."
	sudo ip netns exec red ip addr add 10.11.0.2/24 dev v-red-ns
	sudo ip netns exec blue ip addr add 10.12.0.2/24 dev v-blue-ns

	sudo ip netns exec route ip addr add 10.11.0.1/24 dev vr-red-ns
	sudo ip netns exec route ip addr add 10.12.0.1/24 dev vr-blue-ns

	@echo " Bringing up interfaces..."
	sudo ip netns exec red ip link set v-red-ns up
	sudo ip netns exec blue ip link set v-blue-ns up

	sudo ip netns exec red ip link set lo up
	sudo ip netns exec blue ip link set lo up

	sudo ip netns exec route ip link set vr-red-ns up
	sudo ip netns exec route ip link set vr-blue-ns up
	sudo ip netns exec route ip link set lo up

	@echo " Setting up routes..."
	sudo ip netns exec red ip route add default via 10.11.0.1
	sudo ip netns exec blue ip route add default via 10.12.0.1

	@echo " Enabling IP forwarding..."
	sudo ip netns exec route sysctl -w net.ipv4.ip_forward=1

	@echo "✅ Setup complete."

test:
	@echo "Testing ping from red to blue..."
	sudo ip netns exec red ping -c 3 10.12.0.2

	@echo "Testing ping from blue to red..."
	sudo ip netns exec red ping -c 3 10.11.0.2

clean:
	@echo "🧹 Cleaning up..."
	-sudo ip netns del red
	-sudo ip netns del blue
	-sudo ip netns del route
	-sudo ip link del br0
	-sudo ip link del br1
	-sudo ip link del veth-red
	-sudo ip link del veth-blue
	-sudo ip link del vr-red
	-sudo ip link del vr-blue
