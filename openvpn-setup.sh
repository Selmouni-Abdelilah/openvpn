#!/bin/bash

# Install OpenVPN and Easy-RSA for certificate management
apt-get update && apt-get install -y openvpn easy-rsa iptables traceroute
echo iptables-persistent iptables-persistent/autosave_v4 boolean true | sudo debconf-set-selections
echo iptables-persistent iptables-persistent/autosave_v6 boolean true | sudo debconf-set-selections
apt-get -y install iptables-persistent

# Make the Easy-RSA files available in the OpenVPN directory
make-cadir /etc/openvpn/easy-rsa
cd /etc/openvpn/easy-rsa

# Initialize the Easy-RSA environment and build the CA
export EASYRSA_BATCH=1
./easyrsa init-pki
./easyrsa build-ca nopass


# Generate server key and certificate
./easyrsa gen-req server nopass
./easyrsa sign-req server server

# Generate client key and certificate
./easyrsa gen-req client1 nopass
./easyrsa sign-req client client1

# Generate Diffie-Hellman parameters for key exchange
./easyrsa gen-dh

openvpn --genkey --secret ta.key

# Copy necessary files to OpenVPN directory
cp pki/ca.crt ta.key pki/issued/server.crt pki/private/server.key pki/dh.pem /etc/openvpn

# Generate server.conf file
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

# Enable IP forwarding
sed -i '/^#net.ipv4.ip_forward=1/s/^#//' /etc/sysctl.d/99-sysctl.conf

sysctl --system

NIC=$(ip -4 route ls | grep default | grep -Po '(?<=dev )(\S+)' | head -1)

# Set up NAT for the VPN
iptables -t nat -I POSTROUTING 1 -s 10.8.0.0/24 -o $NIC -j MASQUERADE
iptables -I INPUT 1 -i tun0 -j ACCEPT
iptables -I FORWARD 1 -i $NIC -o tun0 -j ACCEPT
iptables -I FORWARD 1 -i tun0 -o $NIC -j ACCEPT
iptables -I INPUT 1 -i $NIC -p udp --dport 1194 -j ACCEPT

netfilter-persistent save
sudo sysctl -p

# Restart and enable the OpenVPN service
systemctl restart openvpn@server
systemctl enable openvpn@server



echo "OpenVPN server setup is complete."

# Obtain the public IP address of this server
public_ip=$(curl -s ifconfig.me)

# Define the locations of your certificate files
CA_CRT="/etc/openvpn/ca.crt"
CLIENT_CRT="/etc/openvpn/easy-rsa/pki/issued/client1.crt"
CLIENT_KEY="/etc/openvpn/easy-rsa/pki/private/client1.key"
DECRIPT_KEY="/etc/openvpn/easy-rsa/pki/private/decryptedkey.key"
TA_KEY="/etc/openvpn/ta.key"


# Output the OpenVPN configuration
echo "client
dev tun
proto udp
remote $public_ip 1194
resolv-retry infinite
nobind
persist-key
persist-tun
remote-cert-tls server
cipher AES-256-GCM
auth SHA256
key-direction 1
verb 6 " >> ~/client.ovpn
echo "<ca>" >> ~/client.ovpn
cat $CA_CRT >> ~/client.ovpn
echo "</ca>" >> ~/client.ovpn
echo "
user nobody
group nogroup " >> ~/client.ovpn
echo "<cert>" >> ~/client.ovpn
sed -ne '/BEGIN CERTIFICATE/,$ p' $CLIENT_CRT >> ~/client.ovpn
echo "</cert>" >> ~/client.ovpn
echo "<key>" >> ~/client.ovpn
cat $CLIENT_KEY >> ~/client.ovpn
echo "</key>" >> ~/client.ovpn
echo "<tls-crypt>" >> ~/client.ovpn
sed -ne '/BEGIN OpenVPN Static key/,$ p' $TA_KEY >> ~/client.ovpn
echo "</tls-crypt>" >> ~/client.ovpn
# Display OpenVPN service status
systemctl status openvpn@server
