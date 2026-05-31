# Satellite-Stresser-ANTI-ddos-filters
Check if it's running
systemctl status antiddos-monitor
View live logs
journalctl -u antiddos-monitor -f

This will show messages like:

Tue May 31 12:34:56 UTC 2026 Blocking 192.0.2.10 (425 connections)
View recent logs
journalctl -u antiddos-monitor -n 50
View all blocked IPs
iptables -L INPUT -n --line-numbers | grep DROP
Watch connections in real time
watch -n 1 'netstat -ntu | awk "{print \$5}" | cut -d: -f1 | sort | uniq -c | sort -nr | head -20'

Or with the newer ss command:

watch -n 1 'ss -ntu | awk "{print \$5}" | cut -d: -f1 | sort | uniq -c | sort -nr | head -20'
See top IPs connected right now
ss -ntu | awk 'NR>1 {print $5}' | cut -d: -f1 | sort | uniq -c | sort -nr | head -25
Check how many packets your firewall has dropped
iptables -L INPUT -n -v

Look at the pkts and bytes counters on the DROP rules to see which protections are actually triggering.

Follow firewall drops live

You can add a logging rule before a DROP rule:

iptables -I INPUT 1 -m limit --limit 10/min \
-j LOG --log-prefix "IPTABLES-DROP: "

Then watch:

journalctl -k -f
