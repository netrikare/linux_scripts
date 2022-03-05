DEV=XXX
MAC=$(ip link show dev $DEV | tail -1 | cut -b16-32)
MAC_RANDOM=$(hexdump -n6 -e'/3 "" 6/1 ":%02X"' /dev/random | cut -b2-100)

#MAC=$MAC_RANDOM

echo "Setting mac addres to "$MAC
sudo ip link set dev $DEV down
sudo ip link set dev $DEV address $MAC
sudo ip link set dev $DEV up

