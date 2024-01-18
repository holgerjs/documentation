#!/bin/bash

# Initialize parameters with default values
domain_name=""
trusted_network=""

# Parse parameters
while (( "$#" )); do
  case "$1" in
    --domain-name)
      domain_name=$2
      shift 2
      ;;
    --trusted-network)
      trusted_network=$2
      shift 2
      ;;
    --) # end argument parsing
      shift
      break
      ;;
    -*|--*=) # unsupported flags
      echo "Error: Unsupported flag $1" >&2
      exit 1
      ;;
    *) # preserve positional arguments
      PARAMS="$PARAMS $1"
      shift
      ;;
  esac
done

# Check if the necessary parameters were provided
if [ -z "$domain_name" ] || [ -z "$trusted_network" ]; then
  echo "Usage: $0 --domain-name domain_name --trusted-network trusted_network"
  exit 1
fi


echo "+----------------------------------------------+"
echo "|     _           _     _____  _   _  _____    |"
echo "|    | |         | |   |  __ \| \ | |/ ____|   |"
echo "|    | |     __ _| |__ | |  | |  \| | (___     |"
echo "|    | |    / _  |  _ \| |  | | .   |\___ \    |" 
echo "|    | |___| (_| | |_) | |__| | |\  |____) |   |"
echo "|    |______\__,_|_.__/|_____/|_| \_|_____/    |"
echo "|                                              |"              
echo "|        Local DNS Server Setup Script         |"
echo "|                                              |"
echo "|  This script will set up a local DNS server  |"
echo "+----------------------------------------------+"


# Get the hostname
hostname=$(hostname)

# Concatenate the hostname with the domain name
fqdn="$hostname.$domain_name"

# Store the local IP address in a variable
local_ip_address=$(hostname -I | awk '{print $1}')

primary_zone_file_path="/etc/bind/zones/db.$domain_name"
truncated_ip=$(echo "$trusted_network" | cut -d'.' -f1-3)
reverse_zone_file_path="/etc/bind/zones/db.$truncated_ip"
reversed_ip=$(echo "$truncated_ip" | awk -F. '{print $3"."$2"."$1}')
reverse_zone_name="$reversed_ip.in-addr.arpa"

# Print the values of the variables
echo "Local IP Address: $local_ip_address"
echo "Hostname: $hostname"
echo "FQDN: $fqdn"
echo "Primary Zone Name: $domain_name"
echo "Primary Zone File Path: $primary_zone_file_path"
echo "Reverse Zone Name: $reverse_zone_name"
echo "Reverse Zone File Path: $reverse_zone_file_path"

# Write the local IP address, hostname, and FQDN to the /etc/hosts file

# Create the line to be added
line="$local_ip_address $hostname $fqdn"

# Check if the line already exists in the /etc/hosts file
if ! grep -qF "$line" /etc/hosts; then
  # If the line does not exist, add it
  echo "Adding $line to /etc/hosts ..."
  echo "# Added by local DNS Server setup script" | sudo tee -a /etc/hosts
  echo "$line" | sudo tee -a /etc/hosts
else
  echo "The line $line already exists in /etc/hosts."
fi

# Update repositories
echo "Updating repositories ..."
sudo apt update
sudo apt install bind9 bind9utils bind9-doc dnsutils -y

# Use sed to replace the line in the file
echo "Replacing OPTIONS in the file /etc/default/named ..."
sudo sed -i 's/OPTIONS="-u bind"/OPTIONS="-u bind -4"/g' /etc/default/named

# Restart the named service
echo "Restarting the named service ..."
sudo systemctl restart named --no-pager
sudo systemctl status named --no-pager

# Create the /etc/bind/named.conf.options file
echo "Creating the /etc/bind/named.conf.options file ..."
sudo bash -c 'cat > /etc/bind/named.conf.options' << EOF
acl "trusted" {
    $local_ip_address;                      # $hostname
    $trusted_network;                       # trusted networks
};

options {
        directory "/var/cache/bind";

        // If there is a firewall between you and nameservers you want
        // to talk to, you may need to fix the firewall to allow multiple
        // ports to talk.  See http://www.kb.cert.org/vuls/id/800113


        recursion yes;                      # enables resursive queries
        allow-recursion { trusted; };       # allows recursive queries from "trusted" - referred to ACL
        listen-on { $local_ip_address; };   # $hostname IP address
        allow-transfer { none; };           # disable zone transfers by default

        forwarders {
                168.63.129.16;              # Azure DNS Proxy
        };

        //========================================================================
        // If BIND logs error messages about the root key being expired,
        // you will need to update your keys.  See https://www.isc.org/bind-keys
        //========================================================================
        dnssec-validation auto;
};
EOF

echo "Checking the syntax of the /etc/bind/named.conf.options file ..."
sudo named-checkconf /etc/bind/named.conf.options

# Create the /etc/bind/named.conf.local file
echo "Creating the /etc/bind/named.conf.local file ..."
sudo bash -c 'cat > /etc/bind/named.conf.local' << EOF
//
// Do any local configuration here
//

// Consider adding the 1918 zones here, if they are not used in your
// organization
//include "/etc/bind/zones.rfc1918";

zone "$domain_name" {
    type master;
    file "$primary_zone_file_path"; # zone file path
};


zone "$reverse_zone_name" {
    type master;
    file "$reverse_zone_file_path";  # subnet $trusted_network reverse zone file path
};
EOF

# Create the primary zone file
echo "Creating the primary zone file ..."
sudo mkdir -p /etc/bind/zones/
sudo bash -c "cat > $primary_zone_file_path" << EOF
;
; BIND data file for the local loopback interface
;
\$TTL    604800
@       IN      SOA     $fqdn. admin.$fqdn. (
                              3         ; Serial
                         604800         ; Refresh
                          86400         ; Retry
                        2419200         ; Expire
                         604800 )       ; Negative Cache TTL
;

; NS records for name servers
    IN      NS      $fqdn.

; A records for name servers
$fqdn.          IN      A       $local_ip_address
EOF

# Create the secondary zone file
echo "Creating the secondary zone file ..."
sudo bash -c "cat > $reverse_zone_file_path" << EOF
;
; BIND reverse data file for the local loopback interface
;
\$TTL    604800
@       IN      SOA     $fqdn. admin.$fqdn. (
                              3         ; Serial
                         604800         ; Refresh
                          86400         ; Retry
                        2419200         ; Expire
                         604800 )       ; Negative Cache TTL
;

; name servers - NS records
      IN      NS      $fqdn.

; PTR Records
21   IN      PTR     $fqdn.    ; $local_ip_address
EOF

# Check the BIND configuration and Syntax of the Zone Files
echo "Checking the BIND configuration ..."
sudo named-checkconf

echo "Checking the syntax of the zone files ..."
sudo named-checkzone $domain_name $primary_zone_file_path
sudo named-checkzone $reverse_zone_name $reverse_zone_file_path

# Restart the named service
echo "Restarting the named service ..."
sudo systemctl restart named --no-pager
