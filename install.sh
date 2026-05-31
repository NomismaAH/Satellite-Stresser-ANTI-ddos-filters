#!/bin/bash

#########################################
# Panda Anti-DDoS Script
# Ubuntu 20.04 + IPTables
#########################################

SSH_PORT="22"

# Web
WEB_PORTS="80 443"

# Control Panels
PANEL_PORTS="8080 8081"

# Max concurrent connections per IP
CONNLIMIT="100"

# Max SYN packets/sec per IP
SYNLIMIT="30"

# Auto-ban threshold
BAN_THRESHOLD="300"

#########################################

echo "[+] Installing required packages..."

apt update -y
apt install -y iptables-persistent net-tools

echo "[+] Applying kernel hardening..."

cat >/etc/sysctl.d/99-antiddos.conf <<EOF
net.ipv4.tcp_syncookies=1
net.ipv4.tcp_max_syn_backlog=4096
net.ipv4.tcp_synack_retries=2
net.ipv4.tcp_fin_timeout=15
net.ipv4.tcp_keepalive_time=600
net.ipv4.conf.all.rp_filter=1
net.ipv4.conf.default.rp_filter=1
net.ipv4.icmp_echo_ignore_broadcasts=1
net.ipv4.icmp_ignore_bogus_error_responses=1
net.ipv4.tcp_timestamps=0
net.ipv4.tcp_sack=1
net.ipv4.tcp_window_scaling=1
net.ipv4.tcp_rfc1337=1
EOF

sysctl --system

echo "[+] Flushing existing firewall rules..."

iptables -F
iptables -X
iptables -Z

#########################################
# DEFAULT POLICIES
#########################################

iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

#########################################
# BASIC ALLOWS
#########################################

iptables -A INPUT -i lo -j ACCEPT

iptables -A INPUT \
    -m conntrack \
    --ctstate ESTABLISHED,RELATED \
    -j ACCEPT

#########################################
# SSH
#########################################

iptables -A INPUT -p tcp --dport ${SSH_PORT} -j ACCEPT

#########################################
# WEB PORTS
#########################################

for PORT in ${WEB_PORTS}; do
    iptables -A INPUT -p tcp --dport ${PORT} -j ACCEPT
done

#########################################
# PANEL PORTS
#########################################

for PORT in ${PANEL_PORTS}; do
    iptables -A INPUT -p tcp --dport ${PORT} -j ACCEPT
done

#########################################
# INVALID PACKETS
#########################################

iptables -A INPUT \
    -m conntrack \
    --ctstate INVALID \
    -j DROP

#########################################
# BAD TCP STATES
#########################################

iptables -A INPUT \
    -p tcp ! --syn \
    -m conntrack \
    --ctstate NEW \
    -j DROP

#########################################
# SYN FLOOD PROTECTION
#########################################

iptables -A INPUT \
    -p tcp \
    --syn \
    -m hashlimit \
    --hashlimit-name synflood \
    --hashlimit-mode srcip \
    --hashlimit-above ${SYNLIMIT}/second \
    --hashlimit-burst 60 \
    -j DROP

#########################################
# CONNECTION LIMIT
#########################################

iptables -A INPUT \
    -p tcp \
    -m connlimit \
    --connlimit-above ${CONNLIMIT} \
    --connlimit-mask 32 \
    -j DROP

#########################################
# ICMP LIMITING
#########################################

iptables -A INPUT \
    -p icmp \
    -m limit \
    --limit 5/second \
    --limit-burst 10 \
    -j ACCEPT

iptables -A INPUT -p icmp -j DROP

#########################################
# COMMON ATTACK TRAFFIC
#########################################

iptables -A INPUT -f -j DROP

#########################################
# SAVE RULES
#########################################

iptables-save > /etc/iptables/rules.v4

#########################################
# AUTO BAN SERVICE
#########################################

cat >/usr/local/bin/antiddos-monitor.sh <<EOF
#!/bin/bash

THRESHOLD=${BAN_THRESHOLD}

while true
do
    netstat -ntu 2>/dev/null | \
    awk '{print \$5}' | \
    cut -d: -f1 | \
    grep -v '^$' | \
    sort | uniq -c | sort -nr | \
    while read count ip
    do
        if [ "\$count" -gt "\$THRESHOLD" ]; then
            iptables -C INPUT -s "\$ip" -j DROP 2>/dev/null || {
                echo "\$(date) Blocking \$ip (\$count connections)"
                iptables -I INPUT -s "\$ip" -j DROP
            }
        fi
    done

    sleep 10
done
EOF

chmod +x /usr/local/bin/antiddos-monitor.sh

cat >/etc/systemd/system/antiddos-monitor.service <<EOF
[Unit]
Description=Anti-DDoS Monitor
After=network.target

[Service]
ExecStart=/usr/local/bin/antiddos-monitor.sh
Restart=always

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable antiddos-monitor
systemctl restart antiddos-monitor

echo ""
echo "=================================="
echo " Anti-DDoS Protection Enabled"
echo "=================================="
echo ""
echo "SSH Port: ${SSH_PORT}"
echo "Web Ports: ${WEB_PORTS}"
echo "Panel Ports: ${PANEL_PORTS}"
echo "Conn Limit/IP: ${CONNLIMIT}"
echo "SYN Limit/IP: ${SYNLIMIT}/sec"
echo "Auto-Ban Threshold: ${BAN_THRESHOLD}"
echo ""
