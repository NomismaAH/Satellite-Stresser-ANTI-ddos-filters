# Panda Anti-DDoS

A lightweight Anti-DDoS and connection abuse mitigation script for Ubuntu servers using IPTables.

Designed for:
- VPS Hosting
- Web Servers
- Game Panels
- Dedicated Servers
- Reverse Proxies
- Small Hosting Providers

## Features

- SYN Flood Protection
- Invalid Packet Filtering
- Connection Rate Limiting
- Per-IP Connection Limits
- ICMP Flood Protection
- Kernel Network Hardening
- Automatic Malicious IP Blocking
- Systemd Service Integration
- Automatic Firewall Rule Persistence
- Real-Time Monitoring

---

## Requirements

### Supported Operating Systems

- Ubuntu 20.04 LTS
- Ubuntu 22.04 LTS
- Ubuntu 24.04 LTS

### Dependencies

The installer automatically installs:

- iptables
- iptables-persistent
- net-tools
- systemd

---

## Installation

Download the script:

```bash
wget https://raw.githubusercontent.com/YOUR_USERNAME/Panda-AntiDDoS/main/install.sh
```

Make executable:

```bash
chmod +x install.sh
```

Run as root:

```bash
sudo ./install.sh
```

---

## Configuration

Edit the variables at the top of the script before installation:

```bash
SSH_PORT="22"

WEB_PORTS="80 443"

PANEL_PORTS="8080 8081"

CONNLIMIT="100"

SYNLIMIT="30"

BAN_THRESHOLD="300"
```

### Variables

| Variable | Description |
|-----------|------------|
| SSH_PORT | SSH port to allow |
| WEB_PORTS | Web ports to allow |
| PANEL_PORTS | Control panel ports |
| CONNLIMIT | Maximum simultaneous connections per IP |
| SYNLIMIT | Maximum SYN packets per second per IP |
| BAN_THRESHOLD | Connections before automatic IP ban |

---

## Starting the Monitor

The service automatically starts after installation.

Manual start:

```bash
systemctl start antiddos-monitor
```

Enable on boot:

```bash
systemctl enable antiddos-monitor
```

Restart service:

```bash
systemctl restart antiddos-monitor
```

---

## Monitoring

### Service Status

```bash
systemctl status antiddos-monitor
```

### Live Logs

```bash
journalctl -u antiddos-monitor -f
```

### Recent Logs

```bash
journalctl -u antiddos-monitor -n 50
```

### View Active Connections

```bash
ss -ntu
```

### Top Connected IPs

```bash
ss -ntu | awk 'NR>1 {print $5}' | cut -d: -f1 | sort | uniq -c | sort -nr | head -25
```

---

## Firewall Rules

View all firewall rules:

```bash
iptables -L INPUT -n -v
```

View DROP rules only:

```bash
iptables -L INPUT -n --line-numbers | grep DROP
```

Save current rules:

```bash
iptables-save > /etc/iptables/rules.v4
```

---

## Unblocking an IP

List blocked IPs:

```bash
iptables -L INPUT -n --line-numbers
```

Delete a rule:

```bash
iptables -D INPUT RULE_NUMBER
```

Example:

```bash
iptables -D INPUT 5
```

---

## Removing Panda Anti-DDoS

Stop the service:

```bash
systemctl stop antiddos-monitor
```

Disable the service:

```bash
systemctl disable antiddos-monitor
```

Delete the service:

```bash
rm -f /etc/systemd/system/antiddos-monitor.service
```

Delete the monitor:

```bash
rm -f /usr/local/bin/antiddos-monitor.sh
```

Reload systemd:

```bash
systemctl daemon-reload
```

Flush IPTables:

```bash
iptables -F
iptables -X
```

---

## How It Works

### IPTables Protection

The firewall:

- Drops invalid packets
- Blocks malformed TCP packets
- Limits SYN floods
- Restricts excessive connections
- Limits ICMP floods
- Drops fragmented packets

### Auto-Ban Engine

The monitor continuously:

1. Reads active TCP/UDP connections
2. Counts connections per IP
3. Detects excessive usage
4. Automatically inserts DROP rules
5. Logs all actions to systemd

---

## Important Notes

### 1 Gbps VPS Limitation

This script protects the server itself.

If an attacker sends traffic exceeding your VPS network capacity, the provider's network link may become saturated before traffic reaches the firewall.

For large attacks consider:

- Cloudflare
- OVH Anti-DDoS
- Path.net
- Voxility
- TCPShield
- NeoProtect

### Reverse Proxy Users

If using:

- Cloudflare
- Nginx Proxy Manager
- HAProxy
- Traefik

Increase connection limits to avoid false positives.

Example:

```bash
CONNLIMIT="500"
BAN_THRESHOLD="1000"
```

---

## Security Disclaimer

This software is intended for defensive network protection and abuse mitigation.

No firewall can fully stop volumetric attacks that exceed the available network bandwidth of the host machine.

Additional upstream protection may be required for large-scale attacks.

---

## License

MIT License

Copyright (c) 2026 Panda Anti-DDoS
