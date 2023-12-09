#!/bin/bash

apt-get update && apt-get install -y openvpn easy-rsa iptables traceroute
echo iptables-persistent iptables-persistent/autosave_v4 boolean true | sudo debconf-set-selections
echo iptables-persistent iptables-persistent/autosave_v6 boolean true | sudo debconf-set-selections
apt-get -y install iptables-persistent


make-cadir /etc/openvpn/easy-rsa
cd /etc/openvpn/easy-rsa


export EASYRSA_BATCH=1
./easyrsa init-pki
./easyrsa build-ca nopass


./easyrsa gen-req server nopass
./easyrsa sign-req server server

./easyrsa gen-req client1 nopass
./easyrsa sign-req client client1

./easyrsa gen-dh

openvpn --genkey --secret ta.key

cp pki/ca.crt ta.key pki/issued/server.crt pki/private/server.key pki/dh.pem /etc/openvpn

cat > /etc/openvpn/server.conf <<EOF
port 1194
proto udp
dev tun
ca /etc/openvpn/ca.crt
cert /etc/openvpn/server.crt
key /etc/openvpn/server.key
tls-crypt /etc/openvpn/ta.key
dh dh.pem
server 10.8.0.0 255.255.255.0
ifconfig-pool-persist ipp.txt
push "redirect-gateway def1 bypass-dhcp"
push "dhcp-option DNS 8.8.8.8"
push "dhcp-option DNS 8.8.4.4"
keepalive 10 120
cipher AES-256-GCM
auth SHA256
user nobody
group nogroup
persist-key
persist-tun
status openvpn-status.log
verb 9
explicit-exit-notify 1
EOF

sed -i '/^#net.ipv4.ip_forward=1/s/^#//' /etc/sysctl.d/99-sysctl.conf

sysctl --system

NIC=$(ip -4 route ls | grep default | grep -Po '(?<=dev )(\S+)' | head -1)

iptables -t nat -I POSTROUTING 1 -s 10.8.0.0/24 -o $NIC -j MASQUERADE
iptables -I INPUT 1 -i tun0 -j ACCEPT
iptables -I FORWARD 1 -i $NIC -o tun0 -j ACCEPT
iptables -I FORWARD 1 -i tun0 -o $NIC -j ACCEPT
iptables -I INPUT 1 -i $NIC -p udp --dport 1194 -j ACCEPT

netfilter-persistent save
sudo sysctl -p

systemctl restart openvpn@server
systemctl enable openvpn@server
