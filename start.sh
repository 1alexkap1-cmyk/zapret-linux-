#!/bin/bash

# Ensure we are running as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root (use sudo)"
  exit 1
fi

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
BIN="${BASE_DIR}/bin/nfqws"
PAYLOADS="${BASE_DIR}/payloads"
LISTS="${BASE_DIR}/lists"

# Create empty user list files if they don't exist
touch "${LISTS}/list-general-user.txt" "${LISTS}/list-exclude-user.txt" "${LISTS}/ipset-exclude-user.txt"

# Port filtering configuration
QNUM=200
TCP_PORTS="80,443,2053,2083,2087,2096,8443"
UDP_PORTS="443"
UDP_PORT_RANGES="19294:19344,50000:50100"

# Function to clean up iptables rules on exit
cleanup() {
    echo "Cleaning up iptables rules..."
    iptables -t mangle -D PREROUTING -p tcp -m multiport --dports $TCP_PORTS -j NFQUEUE --queue-num $QNUM --queue-bypass 2>/dev/null || true
    iptables -t mangle -D PREROUTING -p udp -m multiport --dports $UDP_PORTS -j NFQUEUE --queue-num $QNUM --queue-bypass 2>/dev/null || true

    # Clean up port ranges
    IFS=',' read -r -a ranges <<< "$UDP_PORT_RANGES"
    for range in "${ranges[@]}"; do
        iptables -t mangle -D PREROUTING -p udp --dport "$range" -j NFQUEUE --queue-num $QNUM --queue-bypass 2>/dev/null || true
    done

    # Output rules
    iptables -t mangle -D OUTPUT -p tcp -m multiport --dports $TCP_PORTS -j NFQUEUE --queue-num $QNUM --queue-bypass 2>/dev/null || true
    iptables -t mangle -D OUTPUT -p udp -m multiport --dports $UDP_PORTS -j NFQUEUE --queue-num $QNUM --queue-bypass 2>/dev/null || true
    for range in "${ranges[@]}"; do
        iptables -t mangle -D OUTPUT -p udp --dport "$range" -j NFQUEUE --queue-num $QNUM --queue-bypass 2>/dev/null || true
    done

    echo "Stopped."
}

# Trap signals for clean exit
trap cleanup EXIT SIGINT SIGTERM

echo "Setting up iptables rules..."
# Add rules
iptables -t mangle -I PREROUTING -p tcp -m multiport --dports $TCP_PORTS -j NFQUEUE --queue-num $QNUM --queue-bypass
iptables -t mangle -I PREROUTING -p udp -m multiport --dports $UDP_PORTS -j NFQUEUE --queue-num $QNUM --queue-bypass
IFS=',' read -r -a ranges <<< "$UDP_PORT_RANGES"
for range in "${ranges[@]}"; do
    iptables -t mangle -I PREROUTING -p udp --dport "$range" -j NFQUEUE --queue-num $QNUM --queue-bypass
done

iptables -t mangle -I OUTPUT -p tcp -m multiport --dports $TCP_PORTS -j NFQUEUE --queue-num $QNUM --queue-bypass
iptables -t mangle -I OUTPUT -p udp -m multiport --dports $UDP_PORTS -j NFQUEUE --queue-num $QNUM --queue-bypass
for range in "${ranges[@]}"; do
    iptables -t mangle -I OUTPUT -p udp --dport "$range" -j NFQUEUE --queue-num $QNUM --queue-bypass
done


echo "Starting nfqws bypass..."
"$BIN" --qnum=$QNUM \
--filter-udp=443 --hostlist="${LISTS}/list-general.txt" --hostlist="${LISTS}/list-general-user.txt" --hostlist-exclude="${LISTS}/list-exclude.txt" --hostlist-exclude="${LISTS}/list-exclude-user.txt" --ipset-exclude="${LISTS}/ipset-exclude.txt" --ipset-exclude="${LISTS}/ipset-exclude-user.txt" --dpi-desync=fake --dpi-desync-repeats=6 --dpi-desync-fake-quic="${PAYLOADS}/quic_initial_www_google_com.bin" --new \
--filter-udp=19294-19344,50000-50100 --filter-l7=discord,stun --dpi-desync=fake --dpi-desync-fake-discord="${PAYLOADS}/quic_initial_dbankcloud_ru.bin" --dpi-desync-fake-stun="${PAYLOADS}/stun.bin" --dpi-desync-repeats=6 --new \
--filter-tcp=2053,2083,2087,2096,8443 --hostlist-domains=discord.media --dpi-desync=multisplit --dpi-desync-split-seqovl=681 --dpi-desync-split-pos=1 --dpi-desync-split-seqovl-pattern="${PAYLOADS}/tls_clienthello_www_google_com.bin" --new \
--filter-tcp=443 --hostlist="${LISTS}/list-google.txt" --ip-id=zero --dpi-desync=multisplit --dpi-desync-split-seqovl=681 --dpi-desync-split-pos=1 --dpi-desync-split-seqovl-pattern="${PAYLOADS}/tls_clienthello_www_google_com.bin" --new \
--filter-tcp=80,443 --hostlist="${LISTS}/list-general.txt" --hostlist="${LISTS}/list-general-user.txt" --hostlist-exclude="${LISTS}/list-exclude.txt" --hostlist-exclude="${LISTS}/list-exclude-user.txt" --ipset-exclude="${LISTS}/ipset-exclude.txt" --ipset-exclude="${LISTS}/ipset-exclude-user.txt" --dpi-desync=multisplit --dpi-desync-split-seqovl=568 --dpi-desync-split-pos=1 --dpi-desync-split-seqovl-pattern="${PAYLOADS}/tls_clienthello_4pda_to.bin" --new \
--filter-udp=443 --ipset="${LISTS}/ipset-all.txt" --hostlist-exclude="${LISTS}/list-exclude.txt" --hostlist-exclude="${LISTS}/list-exclude-user.txt" --ipset-exclude="${LISTS}/ipset-exclude.txt" --ipset-exclude="${LISTS}/ipset-exclude-user.txt" --dpi-desync=fake --dpi-desync-repeats=6 --dpi-desync-fake-quic="${PAYLOADS}/quic_initial_www_google_com.bin" --new \
--filter-tcp=80,443,8443 --ipset="${LISTS}/ipset-all.txt" --hostlist-exclude="${LISTS}/list-exclude.txt" --hostlist-exclude="${LISTS}/list-exclude-user.txt" --ipset-exclude="${LISTS}/ipset-exclude.txt" --ipset-exclude="${LISTS}/ipset-exclude-user.txt" --dpi-desync=multisplit --dpi-desync-split-seqovl=568 --dpi-desync-split-pos=1 --dpi-desync-split-seqovl-pattern="${PAYLOADS}/tls_clienthello_4pda_to.bin"
