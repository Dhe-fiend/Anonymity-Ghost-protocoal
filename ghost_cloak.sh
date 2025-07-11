#!/bin/bash
# === Darkcipher's Ultimate Ghost Cloak ===
# Features:
# 1. MAC Address Randomization
# 2. Tor + VPN Chaining (Optional)
# 3. DNS/WebRTC Leak Prevention
# 4. Kill Leaky Apps (Discord, Chrome, etc.)
# 5. Browser Fingerprint Hardening
# 6. Full System Cleanup
# 7. Connection Verification

# --- Check Root ---
if [ "$(id -u)" -ne 0 ]; then
    echo "[!] Run as root: sudo ./ghost_cloak.sh"
    exit 1
fi

# --- Disable History Logging ---
unset HISTFILE
export HISTSIZE=0

# --- Detect Active Interface ---
iface=$(ip route | grep default | awk '{print $5}' | head -n 1)
if [ -z "$iface" ]; then
    echo "[!] No active network interface found!"
    exit 1
fi

# --- Kill Dangerous Processes ---
echo "[+] Killing leaky processes..."
pkill -9 -f "discord|chrome|steam|dropbox|skype|zoom|signal|firefox|thunderbird"

# --- MAC Spoofing ---
echo "[+] Randomizing MAC address..."
{
    ip link set dev "$iface" down &&
    macchanger -r "$iface" &&
    ip link set dev "$iface" up
} || {
    echo "[!] MAC spoofing failed! Exiting."
    ip link set dev "$iface" up  # Restore network
    exit 1
}

# --- Start VPN (Optional) ---
# Uncomment if you use a VPN (e.g., OpenVPN)
# echo "[+] Starting VPN..."
# openvpn --config /path/to/config.ovpn &

# --- Tor Anonymization ---
echo "[+] Starting Tor..."
service tor start || {
    echo "[!] Tor failed! Install with: sudo apt install tor"
    exit 1
}
anonsurf start || {
    echo "[!] Anonsurf failed! (Kali/Parrot only)"
    exit 1
}

# --- DNS Leak Protection ---
echo "[+] Blocking DNS leaks..."
echo "nameserver 9.9.9.9" > /etc/resolv.conf  # Quad9 DNS
chattr +i /etc/resolv.conf  # Prevent changes

# --- WebRTC/DNS Leak Test ---
echo "[+] Testing for leaks..."
if ! torsocks curl -s https://check.torproject.org | grep -q "Congratulations"; then
    echo "[!] Tor leak detected! Fix manually."
    exit 1
fi

if torsocks curl -s https://www.dnsleaktest.com | grep -q "$(curl -s ifconfig.me)"; then
    echo "[!] DNS leak detected! Use Tails OS for full safety."
fi

# --- Browser Hardening (For Firefox/Tor Browser) ---
echo "[+] Hardening browser against fingerprinting..."
cat > /etc/firefox/prefs.js <<EOF
user_pref("privacy.resistFingerprinting", true);
user_pref("privacy.trackingprotection.enabled", true);
user_pref("webgl.disabled", true);
user_pref("media.peerconnection.enabled", false);  // Disable WebRTC
EOF

# --- System Cleanup ---
echo "[+] Wiping temp files..."
bleachbit -c --preset  # Requires bleachbit installed

# --- Final Status ---
echo -e "\n=== GHOST MODE ACTIVATED ==="
echo "[*] Interface: $iface"
echo "[*] New MAC: $(macchanger -s "$iface" | grep 'Current MAC')"
echo "[*] Tor IP: $(torsocks curl -s ifconfig.me)"
echo "[*] DNS: $(torsocks curl -s https://dnsleaktest.com | grep -A1 'Hello' | tail -n1)"
echo -e "\n[!] WARNING: Avoid logging into accounts or using untrusted apps!"