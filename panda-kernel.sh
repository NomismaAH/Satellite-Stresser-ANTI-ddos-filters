#!/bin/bash

#########################################
# Panda Kernel Optimizer
# Ubuntu 20.04 / 22.04 / 24.04
#########################################

if [[ $EUID -ne 0 ]]; then
    echo "Please run as root."
    exit 1
fi

echo "[+] Installing required packages..."

apt update -y
apt install -y irqbalance conntrack

echo "[+] Creating sysctl configuration..."

cat > /etc/sysctl.d/99-panda-kernel.conf << 'EOF'
################################################
# Panda Kernel Network Optimization
################################################

# SYN flood protection
net.ipv4.tcp_syncookies=1
net.ipv4.tcp_max_syn_backlog=8192
net.ipv4.tcp_synack_retries=2

# TCP cleanup
net.ipv4.tcp_fin_timeout=15
net.ipv4.tcp_keepalive_time=600
net.ipv4.tcp_tw_reuse=1

# Security
net.ipv4.conf.all.rp_filter=1
net.ipv4.conf.default.rp_filter=1

net.ipv4.conf.all.accept_source_route=0
net.ipv4.conf.default.accept_source_route=0

net.ipv4.conf.all.accept_redirects=0
net.ipv4.conf.default.accept_redirects=0

net.ipv4.conf.all.send_redirects=0
net.ipv4.conf.default.send_redirects=0

# ICMP protection
net.ipv4.icmp_echo_ignore_broadcasts=1
net.ipv4.icmp_ignore_bogus_error_responses=1

# Conntrack
net.netfilter.nf_conntrack_max=1048576
net.netfilter.nf_conntrack_tcp_timeout_established=600

# Queue sizes
net.core.somaxconn=65535
net.core.netdev_max_backlog=50000

# Buffer sizes
net.core.rmem_max=67108864
net.core.wmem_max=67108864

net.ipv4.tcp_rmem=4096 87380 67108864
net.ipv4.tcp_wmem=4096 65536 67108864

# Ephemeral ports
net.ipv4.ip_local_port_range=1024 65535

# BBR
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr
EOF

echo "[+] Loading conntrack and synproxy modules..."

cat > /etc/modules-load.d/panda-antiddos.conf << EOF
nf_conntrack
nf_synproxy_core
EOF

modprobe nf_conntrack 2>/dev/null
modprobe nf_synproxy_core 2>/dev/null

echo "[+] Enabling irqbalance..."

systemctl enable irqbalance
systemctl restart irqbalance

echo "[+] Applying sysctl settings..."

sysctl --system

echo
echo "====================================="
echo " Panda Kernel Optimization Complete"
echo "====================================="
echo

echo "[+] BBR Status:"
sysctl net.ipv4.tcp_congestion_control

echo
echo "[+] Conntrack Limits:"
echo -n "Current: "
cat /proc/sys/net/netfilter/nf_conntrack_count 2>/dev/null || echo "Unavailable"

echo -n "Maximum: "
cat /proc/sys/net/netfilter/nf_conntrack_max 2>/dev/null || echo "Unavailable"

echo
echo "[+] Network Queue:"
sysctl net.core.somaxconn

echo
echo "[+] Reboot Recommended"
echo
